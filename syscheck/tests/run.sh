#!/usr/bin/env bash
# run.sh — tests for the syscheck libs. Never touches the real ESP, /proc or network:
# every probe is replaced and every path points into a throwaway directory.
# Usage: syscheck/tests/run.sh   (exit 0 = all passed)
#        SHOW=1 syscheck/tests/run.sh   (also print each scenario's output)
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
lib="$here/../.local/lib/syscheck"
export NO_COLOR=1
# shellcheck source=SCRIPTDIR/../.local/lib/syscheck/common.sh
source "$lib/common.sh"
# shellcheck source=SCRIPTDIR/../.local/lib/syscheck/boot.sh
source "$lib/boot.sh"
# shellcheck source=SCRIPTDIR/../.local/lib/syscheck/net.sh
source "$lib/net.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

passed=0
failed=0
out=""

# run NAME FUNCTION: capture output + return code of FUNCTION
run() {
    local name="$1"
    shift
    out="$("$@")"
    rc=$?
    current="$name"
    if [[ -n "${SHOW:-}" ]]; then
        printf '\n--- %s (rc=%d)\n%s\n' "$name" "$rc" "$out"
    fi
}

expect_rc() {
    if [[ "$rc" == "$1" ]]; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
        printf 'FAIL %s: expected rc %s, got %s\n%s\n' "$current" "$1" "$rc" "$out"
    fi
}

expect_out() {
    if grep -qF -- "$1" <<<"$out"; then
        passed=$((passed + 1))
    else
        failed=$((failed + 1))
        printf 'FAIL %s: output lacks %q\n%s\n' "$current" "$1" "$out"
    fi
}

expect_no_out() {
    if grep -qF -- "$1" <<<"$out"; then
        failed=$((failed + 1))
        printf 'FAIL %s: output unexpectedly has %q\n%s\n' "$current" "$1" "$out"
    else
        passed=$((passed + 1))
    fi
}

# --- boot fixtures ----------------------------------------------------------

RELEASE="7.2.4-arch1-2"

# A file that looks like an x86 bzImage to sc_image_release: a pointer at
# 0x20E to a version string. 256 + 0x200 puts the string at byte 768.
make_kernel() {
    local path="$1" release="$2"
    truncate -s 4096 "$path"
    printf '\x00\x01' | dd of="$path" bs=1 seek=$((0x20E)) conv=notrunc 2>/dev/null
    printf '%s (builduser@archlinux) #1 SMP' "$release" | dd of="$path" bs=1 seek=768 conv=notrunc 2>/dev/null
}

# Healthy system: mounted ESP, kernel + big-enough newer initramfs, modules.
setup_boot() {
    FAKE_ESP="$work/esp"
    rm -rf "$FAKE_ESP" "$work/modules" "$work/proc" "$work/cgroup" "$work/flag"
    mkdir -p "$FAKE_ESP" "$work/modules/$RELEASE" "$work/proc" "$work/cgroup"
    make_kernel "$FAKE_ESP/vmlinuz-linux" "$RELEASE"
    touch -d '2026-09-14 16:11:00' "$FAKE_ESP/vmlinuz-linux"
    truncate -s $((20 * 1024 * 1024)) "$FAKE_ESP/initramfs-linux.img"
    touch -d '2026-09-14 16:11:10' "$FAKE_ESP/initramfs-linux.img"

    SC_MODULES_DIR="$work/modules"
    SC_PROC_DIR="$work/proc"
    SC_CGROUP_DIR="$work/cgroup"
    SC_REBOOT_FLAG="$work/flag"

    FAKE_MOUNTED=1
    FAKE_FSTYPE=vfat
    FAKE_FREE=900
    FAKE_RUNNING="$RELEASE"
    FAKE_PKG_RELEASE="$RELEASE"
}

sc_find_esp() { echo "$FAKE_ESP"; }
sc_mount_info() { (( FAKE_MOUNTED )) && echo "/dev/fake1 $FAKE_FSTYPE"; }
sc_free_mb() { echo "$FAKE_FREE"; }
sc_installed_kernels() { echo linux; }
sc_pkg_version() { echo "7.2.4.arch1-2"; }
sc_pkg_release() { echo "$FAKE_PKG_RELEASE"; }
sc_running_release() { echo "$FAKE_RUNNING"; }

# A fake service whose one process maps the given file.
add_service() {
    local unit="$1" pid="$2" mapline="$3"
    mkdir -p "$SC_CGROUP_DIR/system.slice/$unit" "$SC_PROC_DIR/$pid"
    echo "$pid" >"$SC_CGROUP_DIR/system.slice/$unit/cgroup.procs"
    echo "7f0000000000-7f0000001000 r-xp 00000000 00:1f 42    $mapline" >"$SC_PROC_DIR/$pid/maps"
}

# --- boot scenarios ---------------------------------------------------------

setup_boot
run "boot: healthy" sc_bootcheck_run
expect_rc 0
expect_out "✓ safe to reboot"
expect_out "kernel on ESP is $RELEASE, matches the package"
expect_out "no fallback initramfs"
expect_no_out "reboot is pending"

setup_boot
FAKE_MOUNTED=0
run "boot: ESP not mounted" sc_bootcheck_run
expect_rc 1
expect_out "ESP is NOT mounted"
expect_out "image checks skipped"

setup_boot
FAKE_FSTYPE=btrfs
run "boot: wrong filesystem on ESP mount" sc_bootcheck_run
expect_rc 1
expect_out "not vfat"

setup_boot
FAKE_FREE=12
run "boot: ESP nearly full" sc_bootcheck_run
expect_rc 1
expect_out "ESP free space: 12M"

setup_boot
rm "$FAKE_ESP/vmlinuz-linux"
run "boot: kernel missing" sc_bootcheck_run
expect_rc 1
expect_out "vmlinuz-linux is missing"

setup_boot
rm "$FAKE_ESP/initramfs-linux.img"
run "boot: initramfs missing" sc_bootcheck_run
expect_rc 1
expect_out "initramfs-linux.img is missing"

setup_boot
truncate -s $((1024 * 1024)) "$FAKE_ESP/initramfs-linux.img"
touch -d '2026-09-14 16:11:10' "$FAKE_ESP/initramfs-linux.img"
run "boot: truncated initramfs" sc_bootcheck_run
expect_rc 1
expect_out "truncated or failed build"

setup_boot
touch -d '2026-09-14 16:10:00' "$FAKE_ESP/initramfs-linux.img"
run "boot: initramfs older than kernel" sc_bootcheck_run
expect_rc 1
expect_out "OLDER than the kernel"

setup_boot
touch -d '2026-09-14 16:11:00' "$FAKE_ESP/initramfs-linux.img"
run "boot: same mtime (vfat 2s granularity) is not a failure" sc_bootcheck_run
expect_rc 0

setup_boot
touch "$FAKE_ESP/initramfs-linux-fallback.img"
run "boot: fallback reported" sc_bootcheck_run
expect_rc 0
expect_out "fallback initramfs present"

setup_boot
make_kernel "$FAKE_ESP/vmlinuz-linux" "7.1.9-arch1-1"
touch -d '2026-09-14 16:11:00' "$FAKE_ESP/vmlinuz-linux"
run "boot: stale kernel on ESP (upgrade ran with ESP unmounted)" sc_bootcheck_run
expect_rc 1
expect_out "kernel on ESP is 7.1.9-arch1-1, but installed package is $RELEASE"

setup_boot
rm -rf "${SC_MODULES_DIR:?}/$RELEASE"
run "boot: modules directory missing" sc_bootcheck_run
expect_rc 1
expect_out "$RELEASE is missing"

setup_boot
FAKE_RUNNING="7.1.9-arch1-1"
run "boot: reboot pending is not a failure" sc_bootcheck_run
expect_rc 0
expect_out "reboot pending: running 7.1.9-arch1-1"
expect_out "modules for 7.1.9-arch1-1 are gone"
expect_out "and a reboot is pending"

setup_boot
touch "$SC_REBOOT_FLAG"
run "boot: hook flag without kernel change" sc_bootcheck_run
expect_rc 0
expect_out "flagged by pacman hook"

setup_boot
add_service "mariadb.service" 101 "/usr/lib/libssl.so.3 (deleted)"
add_service "sshd.service" 102 "/usr/lib/libc.so.6"
add_service "portal.service" 103 "/memfd:wayland-cursor (deleted)"
run "boot: deleted maps are warnings, memfd ignored" sc_bootcheck_run
expect_rc 0
expect_out "1 service(s) still run deleted (upgraded) code: mariadb.service"

# --- net fixtures -----------------------------------------------------------

# The FAKE_ROUTES6/FAKE_RULES6 values are read through indirect expansion.
# shellcheck disable=SC2034
setup_net() {
    FAKE_PROCS=" NetworkManager wpa_supplicant "
    FAKE_BACKEND=""
    FAKE_ROUTES4="default via 10.0.0.1 dev wlan0 proto dhcp src 10.0.0.2 metric 600"
    FAKE_ROUTES6=""
    FAKE_ADDRS="10.0.0.2/24"
    FAKE_RULES4=$'0:\tfrom all lookup local\n32766:\tfrom all lookup main\n32767:\tfrom all lookup default'
    FAKE_RULES6=$'0:\tfrom all lookup local\n32766:\tfrom all lookup main'
    FAKE_EXIT=""
    FAKE_PING=" 10.0.0.1 1.1.1.1 "
    FAKE_NEIGH="FAILED"
    FAKE_TCP=1
    FAKE_DNS=1
    FAKE_DNS_DIRECT=0
    SC_RESOLV_CONF="$work/resolv.conf"
    printf '# Generated by NetworkManager\nnameserver 10.0.0.1\n' >"$SC_RESOLV_CONF"
}

sc_proc_running() { [[ "$FAKE_PROCS" == *" $1 "* ]]; }
sc_unit_active() { return 1; }
sc_nm_wifi_backend() { echo "$FAKE_BACKEND"; }
sc_wireless_ifaces() { echo wlan0; }
sc_default_routes() {
    local var="FAKE_ROUTES$1"
    [[ -n "${!var}" ]] && printf '%s\n' "${!var}"
}
sc_global_addrs() { [[ -n "$FAKE_ADDRS" ]] && echo "$FAKE_ADDRS"; }
sc_ip_rules() {
    local var="FAKE_RULES$1"
    printf '%s\n' "${!var}"
}
sc_neigh_state() { echo "$FAKE_NEIGH"; }
sc_ping() { [[ "$FAKE_PING" == *" $1 "* ]]; }
sc_tcp_connect() { (( FAKE_TCP )); }
sc_resolve() { (( FAKE_DNS )); }
sc_resolve_direct() { (( FAKE_DNS_DIRECT )); }
sc_tailscale_exit_node() { [[ -n "$FAKE_EXIT" ]] && echo "$FAKE_EXIT"; }

# --- net scenarios ----------------------------------------------------------

setup_net
run "net: healthy" sc_netcheck_run
expect_rc 0
expect_out "✓ connected"
expect_out "one backend: wpa_supplicant"

setup_net
FAKE_PROCS=" NetworkManager wpa_supplicant iwd "
run "net: iwd and wpa_supplicant both running" sc_netcheck_run
expect_rc 1
expect_out "iwd AND wpa_supplicant are BOTH running"
expect_out "sudo systemctl disable --now iwd"
expect_out "connectivity breaks at: wifi backend"

setup_net
FAKE_PROCS=" NetworkManager iwd "
FAKE_BACKEND="wpa_supplicant"
run "net: NM expects wpa_supplicant, iwd running" sc_netcheck_run
expect_rc 1
expect_out "set to use wpa_supplicant, but only iwd is running"

setup_net
FAKE_PROCS=" NetworkManager iwd "
FAKE_BACKEND="iwd"
run "net: NM configured for iwd, iwd running" sc_netcheck_run
expect_rc 0
expect_out "one backend: iwd (NetworkManager expects iwd)"

setup_net
FAKE_ROUTES4=""
FAKE_PING=""
FAKE_TCP=0
FAKE_DNS=0
run "net: no default route - first failure is link" sc_netcheck_run
expect_rc 1
expect_out "no default route"
expect_out "connectivity breaks at: link"

setup_net
FAKE_ROUTES4+=$'\ndefault via 192.168.1.1 dev enp0s1 proto dhcp metric 600'
run "net: two IPv4 default routes" sc_netcheck_run
expect_out "2 IPv4 default routes"

setup_net
# shellcheck disable=SC2034 # read indirectly by sc_default_routes
FAKE_ROUTES6="default via fe80::1 dev wlan0 proto ra metric 600"
run "net: one v4 + one v6 default route is fine" sc_netcheck_run
expect_out "at most one default route per address family"

setup_net
FAKE_RULES4=$'0:\tfrom all lookup local\n5210:\tfrom all fwmark 0x80000/0xff0000 lookup main\n5270:\tfrom all lookup 52\n32766:\tfrom all lookup main\n32767:\tfrom all lookup default'
run "net: tailscale rules are known" sc_netcheck_run
expect_out "no unexpected ip rules"
expect_out "2 Tailscale ip rule(s)"

setup_net
FAKE_RULES4+=$'\n100:\tfrom 10.8.0.0/24 lookup vpn'
run "net: unknown rule flagged" sc_netcheck_run
expect_out "1 non-default ip rule(s)"
expect_out "IPv4 100: from 10.8.0.0/24 lookup vpn"

setup_net
FAKE_PROCS+="tailscaled "
FAKE_EXIT="100.64.0.7 true"
run "net: exit node set" sc_netcheck_run
expect_rc 0
expect_out "Tailscale exit node 100.64.0.7 is set"

setup_net
FAKE_PROCS+="tailscaled "
FAKE_EXIT="100.64.0.7 false"
FAKE_PING=" 10.0.0.1 "
FAKE_TCP=0
run "net: offline exit node" sc_netcheck_run
expect_rc 1
expect_out "connectivity breaks at: routing (exit node)"

setup_net
FAKE_PING=" 1.1.1.1 "
FAKE_NEIGH="REACHABLE"
run "net: gateway drops ICMP but answers ARP" sc_netcheck_run
expect_rc 0
expect_out "ignores ping but answers ARP"

setup_net
FAKE_PING=""
FAKE_TCP=0
FAKE_DNS=0
run "net: gateway unreachable" sc_netcheck_run
expect_rc 1
expect_out "connectivity breaks at: gateway"

setup_net
FAKE_PING=" 10.0.0.1 "
run "net: ICMP blocked, TCP fine" sc_netcheck_run
expect_rc 0
expect_out "this network drops ICMP (TCP works)"

setup_net
FAKE_PING=" 10.0.0.1 "
FAKE_TCP=0
FAKE_DNS=0
run "net: nothing past the gateway" sc_netcheck_run
expect_rc 1
expect_out "connectivity breaks at: internet"

setup_net
FAKE_DNS=0
FAKE_DNS_DIRECT=1
run "net: local resolver broken" sc_netcheck_run
expect_rc 1
expect_out "local DNS config is broken"
expect_out "connectivity breaks at: dns"

echo
echo "$passed passed, $failed failed"
(( failed == 0 ))
