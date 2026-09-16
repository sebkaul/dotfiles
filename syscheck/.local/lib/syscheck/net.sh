#!/usr/bin/env bash
# net.sh — checks behind `netcheck`. Sourced, never executed.
#
# Checks run bottom-up (wifi backend -> link -> routing -> gateway -> internet
# -> DNS), and every line is tagged with its layer, so the FIRST ✗ is where
# connectivity actually breaks. Everything below it is usually just fallout.
#
# As in boot.sh, anything that touches the system goes through an sc_* probe so
# tests can replace it.

SC_RESOLV_CONF="${SC_RESOLV_CONF:-/etc/resolv.conf}"
SC_SYS_NET_DIR="${SC_SYS_NET_DIR:-/sys/class/net}"

# Anycast, answers ICMP and TCP/80 from practically everywhere, and has no DNS
# dependency - so a failure here is about reachability, never about DNS.
SC_PROBE_IP=1.1.1.1
SC_PROBE_PORT=80
SC_DNS_NAME=archlinux.org

# A gateway on the same wifi answers in milliseconds, even with power saving
# the reply is well under a second. 2s is generous for a working link and keeps
# a fully dead network from making netcheck crawl.
SC_PING_TIMEOUT=2
# The first SYN retransmit happens after 1s (initial RTO), the second after a
# further 2s. 3s lets one lost SYN be retried before calling it a failure.
SC_TCP_TIMEOUT=3
# glibc's resolver waits 5s per nameserver before trying the next one; less
# than that would report a slow-but-working first server as broken.
SC_DNS_TIMEOUT=5

# --- probes (overridden in tests) -------------------------------------------

sc_proc_running() {
    pgrep -x "$1" &>/dev/null
}

sc_unit_active() {
    systemctl is-active --quiet "$1"
}

# NetworkManager prints its effective config with defaults commented out, so
# "# wifi.backend=wpa_supplicant" still tells us what it expects.
sc_nm_wifi_backend() {
    NetworkManager --print-config 2>/dev/null | sed -n 's/^#\{0,1\} *wifi\.backend=//p' | head -n 1
}

sc_wireless_ifaces() {
    local d
    for d in "$SC_SYS_NET_DIR"/*/wireless; do
        [[ -d "$d" ]] && basename "$(dirname "$d")"
    done
}

# $1 = 4 or 6
sc_default_routes() {
    ip -"$1" route show default 2>/dev/null
}

sc_global_addrs() {
    ip -o addr show dev "$1" scope global 2>/dev/null | awk '{print $4}'
}

# $1 = 4 or 6
sc_ip_rules() {
    ip -"$1" rule show 2>/dev/null
}

sc_neigh_state() {
    ip neigh show "$1" dev "$2" 2>/dev/null | awk '{print $NF}'
}

sc_ping() {
    ping -c 1 -W "$SC_PING_TIMEOUT" "$1" &>/dev/null
}

sc_tcp_connect() {
    # shellcheck disable=SC2016 # $1/$2 are expanded by the inner bash, on purpose
    timeout "$SC_TCP_TIMEOUT" bash -c 'exec 3<>"/dev/tcp/$1/$2"' _ "$1" "$2" &>/dev/null
}

# getent goes through nsswitch + /etc/resolv.conf: the same path every program
# on the system uses, unlike dig, which bypasses it.
sc_resolve() {
    timeout "$SC_DNS_TIMEOUT" getent ahosts "$1" &>/dev/null
}

sc_resolve_direct() {
    command -v dig &>/dev/null || return 2
    dig +short +time="$SC_PING_TIMEOUT" +tries=1 "@$2" "$1" A 2>/dev/null | grep -q .
}

# Prints "<exit node IP> <online true|false>" when an exit node is set.
sc_tailscale_exit_node() {
    local json
    json="$(tailscale status --json 2>/dev/null)" || return 1
    if command -v jq &>/dev/null; then
        jq -r '.ExitNodeStatus // empty | "\(.TailscaleIPs[0] // "?") \(.Online)"' <<<"$json"
    else
        # Without jq: the key only carries an object while an exit node is set.
        grep -q '"ExitNodeStatus": {' <<<"$json" && echo "? unknown"
    fi
}

# --- helpers ----------------------------------------------------------------

# First value after KEY in an `ip route` line: _sc_field dev "default via ... dev wlan0"
_sc_field() {
    awk -v key="$1" '{for (i = 1; i < NF; i++) if ($i == key) {print $(i + 1); exit}}' <<<"$2"
}

# --- checks -----------------------------------------------------------------

# iwd and wpa_supplicant both drive the wifi card through nl80211. Running both
# means two daemons fighting over one interface: scans get cancelled,
# associations get torn down, and NetworkManager only reports "disconnected".
sc_check_wifi_backend() {
    local iwd=0 wpa=0 nm=0 expected=""
    sc_proc_running iwd && iwd=1
    sc_proc_running wpa_supplicant && wpa=1
    if sc_proc_running NetworkManager; then
        nm=1
        expected="$(sc_nm_wifi_backend)"
        expected="${expected:-wpa_supplicant}"
    fi

    if (( iwd && wpa )); then
        sc_fail "[wifi]  iwd AND wpa_supplicant are BOTH running - they fight over the wifi card"
        if (( nm )); then
            local other=iwd
            [[ "$expected" == "iwd" ]] && other=wpa_supplicant
            sc_hint "NetworkManager uses $expected. Stop the other: sudo systemctl disable --now $other"
        else
            sc_hint "pick one: sudo systemctl disable --now iwd   (or wpa_supplicant)"
        fi
        return 1
    fi

    if (( nm )); then
        if [[ "$expected" == "iwd" ]] && (( wpa )); then
            sc_fail "[wifi]  NetworkManager is set to use iwd, but only wpa_supplicant is running"
            sc_hint "sudo systemctl disable --now wpa_supplicant && sudo systemctl enable --now iwd"
            return 1
        fi
        if [[ "$expected" == "wpa_supplicant" ]] && (( iwd )); then
            sc_fail "[wifi]  NetworkManager is set to use wpa_supplicant, but only iwd is running"
            sc_hint "sudo systemctl disable --now iwd   (NM starts wpa_supplicant on demand)"
            return 1
        fi
    fi

    if (( ! iwd && ! wpa )); then
        if [[ -n "$(sc_wireless_ifaces)" ]]; then
            sc_warn "[wifi]  no wifi backend running (fine on ethernet, fatal on wifi)"
        else
            sc_info "[wifi]  no wireless interface"
        fi
        return 0
    fi

    local running=wpa_supplicant
    (( iwd )) && running=iwd
    if (( nm )); then
        sc_ok "[wifi]  one backend: $running (NetworkManager expects $expected)"
    else
        sc_ok "[wifi]  one backend: $running"
    fi
}

# Sets SC_NET_DEV and SC_NET_GW for the checks after it.
sc_check_link() {
    local route addrs
    SC_NET_DEV=""
    SC_NET_GW=""
    route="$(sc_default_routes 4 | head -n 1)"
    [[ -n "$route" ]] || route="$(sc_default_routes 6 | head -n 1)"
    if [[ -z "$route" ]]; then
        sc_fail "[link]  no default route - not connected, or DHCP never finished"
        sc_hint "nmcli device status"
        return 1
    fi
    SC_NET_DEV="$(_sc_field dev "$route")"
    SC_NET_GW="$(_sc_field via "$route")"
    # An IPv6 router is usually link-local, which ping only reaches with a zone.
    [[ "$SC_NET_GW" == fe80:* ]] && SC_NET_GW="$SC_NET_GW%$SC_NET_DEV"

    addrs="$(sc_global_addrs "$SC_NET_DEV" | paste -sd ' ')"
    if [[ -z "$addrs" ]]; then
        sc_fail "[link]  $SC_NET_DEV has no global address - DHCP/SLAAC failed"
        sc_hint "nmcli device show $SC_NET_DEV"
        return 1
    fi
    sc_ok "[link]  $SC_NET_DEV: $addrs"
}

# Two default routes in one family: with different metrics only the lowest is
# used (wifi silently losing to a dead ethernet or VPN link); with equal metrics
# the kernel picks per destination and some sites "randomly" break.
sc_check_default_routes() {
    local fam count line rc=0
    for fam in 4 6; do
        count="$(sc_default_routes "$fam" | grep -c .)"
        if (( count > 1 )); then
            sc_warn "[route] $count IPv$fam default routes:"
            sc_default_routes "$fam" | while IFS= read -r line; do sc_hint "$line"; done
            rc=1
        fi
    done
    (( rc == 0 )) && sc_ok "[route] at most one default route per address family"
    return 0
}

# The kernel installs "local", "main" and (IPv4 only) "default" rules. Anything
# else sends some traffic to a different routing table - VPNs, Tailscale,
# leftovers from a crashed VPN client.
sc_check_ip_rules() {
    local fam line prio rule tailscale=0
    local -a unknown=()
    for fam in 4 6; do
        while IFS= read -r line; do
            [[ -n "$line" ]] || continue
            prio="${line%%:*}"
            rule="$(tr -s '[:space:]' ' ' <<<"${line#*:}")"
            rule="${rule# }"
            rule="${rule% }"
            case "$prio $rule" in
                "0 from all lookup local" | "32766 from all lookup main" | "32767 from all lookup default")
                    ;;
                # Tailscale's own rules: its packets carry fwmark 0x80000 and
                # everything else consults its table 52.
                *"fwmark 0x80000/0xff0000"* | *"lookup 52")
                    tailscale=$((tailscale + 1))
                    ;;
                *)
                    unknown+=("IPv$fam $prio: $rule")
                    ;;
            esac
        done < <(sc_ip_rules "$fam")
    done

    if (( ${#unknown[@]} > 0 )); then
        sc_warn "[route] ${#unknown[@]} non-default ip rule(s) - some traffic uses another routing table:"
        for line in "${unknown[@]}"; do sc_hint "$line"; done
    else
        sc_ok "[route] no unexpected ip rules"
    fi
    (( tailscale > 0 )) && sc_info "[route] $tailscale Tailscale ip rule(s) (normal while tailscaled runs)"
    return 0
}

sc_check_exit_node() {
    local exit_node ip online
    sc_proc_running tailscaled || return 0
    exit_node="$(sc_tailscale_exit_node)"
    if [[ -z "$exit_node" ]]; then
        sc_ok "[route] no Tailscale exit node"
        return 0
    fi
    read -r ip online <<<"$exit_node"
    if [[ "$online" == "false" ]]; then
        sc_fail "[route] Tailscale exit node $ip is OFFLINE - all internet traffic goes nowhere"
        sc_hint "tailscale set --exit-node="
        return 1
    fi
    sc_warn "[route] Tailscale exit node $ip is set - all internet traffic goes through it"
    sc_hint "if that is not intended: tailscale set --exit-node="
}

sc_check_gateway() {
    local state
    if [[ -z "$SC_NET_GW" ]]; then
        [[ -n "$SC_NET_DEV" ]] && sc_info "[gw]    default route has no gateway (point-to-point or VPN link)"
        return 0
    fi
    if sc_ping "$SC_NET_GW"; then
        sc_ok "[gw]    $SC_NET_GW answers ping"
        return 0
    fi
    # Some routers drop ICMP. If they still answered ARP, layer 2 is fine.
    state="$(sc_neigh_state "${SC_NET_GW%\%*}" "$SC_NET_DEV")"
    case "$state" in
        REACHABLE | STALE | DELAY | PROBE | PERMANENT)
            sc_warn "[gw]    $SC_NET_GW ignores ping but answers ARP ($state) - it just drops ICMP"
            return 0
            ;;
    esac
    sc_fail "[gw]    $SC_NET_GW unreachable (no ping, no ARP) - broken between you and the router"
    sc_hint "wifi association, wrong network, or client isolation on the access point"
    return 1
}

# ICMP and TCP are judged together: a network that drops ping but passes TCP is
# working, and should not produce a ✗ that points at the wrong layer.
sc_check_internet() {
    local icmp=0 tcp=0
    sc_ping "$SC_PROBE_IP" && icmp=1
    sc_tcp_connect "$SC_PROBE_IP" "$SC_PROBE_PORT" && tcp=1

    if (( icmp )); then
        sc_ok "[icmp]  $SC_PROBE_IP answers ping"
    elif (( tcp )); then
        sc_warn "[icmp]  $SC_PROBE_IP ignores ping - this network drops ICMP (TCP works)"
    else
        sc_fail "[icmp]  $SC_PROBE_IP unreachable - traffic stops past the gateway"
        sc_hint "upstream outage, captive portal, or a VPN/exit node swallowing traffic"
    fi

    if (( tcp )); then
        sc_ok "[tcp]   $SC_PROBE_IP:$SC_PROBE_PORT connects"
    else
        sc_fail "[tcp]   $SC_PROBE_IP:$SC_PROBE_PORT does not connect"
        (( icmp )) && sc_hint "ping works but TCP doesn't: firewall or captive portal"
    fi
    (( tcp ))
}

sc_check_dns() {
    local rc
    if sc_resolve "$SC_DNS_NAME"; then
        sc_ok "[dns]   $SC_DNS_NAME resolves"
        return 0
    fi
    sc_resolve_direct "$SC_DNS_NAME" "$SC_PROBE_IP"
    rc=$?
    case "$rc" in
        0)
            sc_fail "[dns]   system resolver fails, but asking $SC_PROBE_IP directly works - local DNS config is broken"
            sc_hint "cat $SC_RESOLV_CONF; nmcli device show | grep DNS"
            ;;
        2)
            sc_fail "[dns]   $SC_DNS_NAME does not resolve (install bind/dig to tell resolver config from upstream DNS)"
            ;;
        *)
            sc_fail "[dns]   $SC_DNS_NAME does not resolve, not even by asking $SC_PROBE_IP directly"
            ;;
    esac
    return 1
}

# Not a pass/fail: shows which program owns /etc/resolv.conf, and flags two DNS
# managers where only one is in effect (the DNS flavour of the iwd problem).
sc_check_dns_manager() {
    local manager target
    if [[ -L "$SC_RESOLV_CONF" ]]; then
        target="$(readlink "$SC_RESOLV_CONF")"
        case "$target" in
            *systemd/resolve/*) manager="systemd-resolved" ;;
            *) manager="symlink to $target" ;;
        esac
    else
        manager="$(sed -n 's/^# *Generated by \(.*\)$/\1/p' "$SC_RESOLV_CONF" 2>/dev/null | head -n 1)"
        manager="${manager:-a static file}"
    fi
    sc_info "[dns]   $SC_RESOLV_CONF is managed by $manager"
    if [[ "$manager" != "systemd-resolved" ]] && sc_unit_active systemd-resolved; then
        sc_info "[dns]   systemd-resolved is running but not used by $SC_RESOLV_CONF"
    fi
}

# --- runner -----------------------------------------------------------------

sc_netcheck_run() {
    local first_fail=""
    sc_reset_counts
    SC_NET_DEV=""
    SC_NET_GW=""

    sc_header "netcheck"
    sc_check_wifi_backend || first_fail="${first_fail:-wifi backend}"
    sc_check_link || first_fail="${first_fail:-link}"
    sc_check_default_routes
    sc_check_ip_rules
    sc_check_exit_node || first_fail="${first_fail:-routing (exit node)}"
    sc_check_gateway || first_fail="${first_fail:-gateway}"
    sc_check_internet || first_fail="${first_fail:-internet}"
    sc_check_dns || first_fail="${first_fail:-dns}"
    sc_check_dns_manager

    echo
    if (( SC_FAILS > 0 )); then
        printf '%s✗ connectivity breaks at: %s%s\n' "$SC_RED$SC_BOLD" "$first_fail" "$SC_RESET"
        return 1
    fi
    printf '%s✓ connected%s\n' "$SC_GREEN$SC_BOLD" "$SC_RESET"
}
