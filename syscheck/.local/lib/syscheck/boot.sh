#!/usr/bin/env bash
# boot.sh — checks behind `bootcheck`. Sourced, never executed.
#
# Everything that touches the real system goes through a small sc_* probe
# function or an SC_* path variable, so tests/run.sh can point the checks at a
# fake ESP / modules tree / procfs instead of the real boot partition.
#
# Check functions print their result and return 0 (fine) or 1 (problem); they
# never exit. sc_bootcheck_run ties them together and decides the verdict.

# Kernel packages bootcheck knows about. Only the installed ones are checked.
SC_KERNEL_PKGS=(linux linux-lts linux-zen linux-hardened)

SC_MODULES_DIR="${SC_MODULES_DIR:-/usr/lib/modules}"
SC_PROC_DIR="${SC_PROC_DIR:-/proc}"
SC_CGROUP_DIR="${SC_CGROUP_DIR:-/sys/fs/cgroup}"
# Written by the 95-reboot-pending pacman hook. /var/run is /run, a tmpfs, so
# the flag disappears by itself on the next boot.
SC_REBOOT_FLAG="${SC_REBOOT_FLAG:-/var/run/reboot-required}"

# A kernel upgrade rewrites one vmlinuz + one initramfs in place (~17M + ~29M on
# this machine). If the ESP fills up halfway through that, the image is left
# truncated. 60M covers one full rewrite of the current pair with headroom for
# the initramfs growing (new firmware, extra modules) before this check fires.
SC_MIN_ESP_FREE_MB=60

# The smallest real initramfs mkinitcpio produces with autodetect + zstd is
# still several times this; anything below it is a build that died or a write
# that was cut short. A truncated initramfs is worse than a missing one: the
# bootloader happily loads it and the kernel panics mid-boot, instead of the
# loader refusing the entry up front.
SC_MIN_INITRAMFS_BYTES=$((4 * 1024 * 1024))

# Maps of files that package upgrades replace. Restricted to /usr and /opt on
# purpose: memfd:, /dev/shm and SysV shared memory also show up as "(deleted)"
# in every desktop session and mean nothing here.
SC_DELETED_MAP_RE=' /(usr|opt)/.* \(deleted\)$'

SC_REBOOT_PENDING=0

# --- probes (overridden in tests) -------------------------------------------

sc_find_esp() {
    # bootctl only answers when a real, mounted ESP is found. When the ESP is
    # not mounted it fails, and /boot is where mkinitcpio would write anyway -
    # which is exactly the directory the mount check has to look at.
    bootctl --print-esp-path 2>/dev/null || echo /boot
}

# Prints "SOURCE FSTYPE" when PATH is a mount point, fails otherwise.
sc_mount_info() {
    findmnt -n -o SOURCE,FSTYPE --mountpoint "$1"
}

sc_free_mb() {
    df -BM --output=avail "$1" | tail -n 1 | tr -dc '0-9'
}

sc_installed_kernels() {
    local pkg
    for pkg in "${SC_KERNEL_PKGS[@]}"; do
        pacman -Q "$pkg" &>/dev/null && echo "$pkg"
    done
}

sc_pkg_version() {
    pacman -Q "$1" 2>/dev/null | awk '{print $2}'
}

# The kernel release a package installed, read from the package's own file list
# (e.g. "linux" -> "7.2.4-arch1-2"). Taken from the pacman database rather than
# from /usr/lib/modules so the modules check can tell when that directory is
# missing.
sc_pkg_release() {
    pacman -Qlq "$1" 2>/dev/null | sed -n 's|^/usr/lib/modules/\([^/]*\)/pkgbase$|\1|p' | head -n 1
}

sc_running_release() {
    uname -r
}

# The release string built into an x86 kernel image, read the same way
# mkinitcpio does (kver_x86 in /usr/lib/initcpio/functions). The boot protocol
# header stores a 2-byte pointer to the version string at 0x20E; the pointer is
# relative to the end of the 512-byte boot sector, hence + 0x200. The string is
# at most 127 bytes and its first word is the release.
sc_image_release() {
    local image="$1" offset release
    offset="$(od -An -j0x20E -dN2 "$image" 2>/dev/null)" || return 1
    offset="${offset//[[:space:]]/}"
    [[ -n "$offset" ]] || return 1
    read -r release _ < <(dd if="$image" bs=1 count=127 skip=$((offset + 0x200)) 2>/dev/null)
    [[ -n "$release" ]] || return 1
    printf '%s\n' "$release"
}

# --- checks -----------------------------------------------------------------

sc_check_esp_mounted() {
    local esp="$1" info source fstype
    if ! info="$(sc_mount_info "$esp")" || [[ -z "$info" ]]; then
        sc_fail "ESP is NOT mounted at $esp"
        sc_hint "pacman writes kernels into the empty $esp directory on / and reports success"
        sc_hint "sudo mount $esp, then reinstall every kernel package so the ESP gets the real files"
        return 1
    fi
    read -r source fstype <<<"$info"
    if [[ "$fstype" != "vfat" ]]; then
        # UEFI firmware can only read FAT, so a non-FAT "ESP" is the wrong mount.
        sc_fail "$esp is mounted from $source but is $fstype, not vfat - wrong partition?"
        return 1
    fi
    sc_ok "ESP mounted at $esp ($source, $fstype)"
}

sc_check_esp_space() {
    local esp="$1" free
    free="$(sc_free_mb "$esp")"
    if [[ -z "$free" ]]; then
        sc_warn "could not read free space on $esp"
        return 0
    fi
    if (( free < SC_MIN_ESP_FREE_MB )); then
        sc_fail "ESP free space: ${free}M (need at least ${SC_MIN_ESP_FREE_MB}M)"
        sc_hint "remove unused kernels/images from $esp before the next kernel upgrade"
        return 1
    fi
    sc_ok "ESP free space: ${free}M"
}

sc_check_kernel_images() {
    local boot="$1" pkg="$2" rc=0 size
    local kernel="$boot/vmlinuz-$pkg"
    local initramfs="$boot/initramfs-$pkg.img"
    local fallback="$boot/initramfs-$pkg-fallback.img"

    if [[ -f "$kernel" ]]; then
        sc_ok "$pkg: $kernel present"
    else
        sc_fail "$pkg: $kernel is missing"
        sc_hint "sudo pacman -S $pkg"
        rc=1
    fi

    if [[ ! -f "$initramfs" ]]; then
        sc_fail "$pkg: $initramfs is missing"
        sc_hint "sudo mkinitcpio -p $pkg"
        return 1
    fi

    size="$(stat -c %s "$initramfs")"
    if (( size < SC_MIN_INITRAMFS_BYTES )); then
        sc_fail "$pkg: $initramfs is only $((size / 1024))K - truncated or failed build"
        sc_hint "sudo mkinitcpio -p $pkg, and read its output for errors"
        rc=1
    # "Not older" rather than "newer": vfat stores mtimes in 2-second steps, so
    # a kernel copy and an initramfs build that land in the same step compare
    # equal even though the initramfs was written after the kernel.
    elif [[ -f "$kernel" && "$kernel" -nt "$initramfs" ]]; then
        sc_fail "$pkg: $initramfs is OLDER than the kernel - built for the previous kernel"
        sc_hint "sudo mkinitcpio -p $pkg"
        rc=1
    else
        sc_ok "$pkg: initramfs $((size / 1024 / 1024))M, built after the kernel"
    fi

    if [[ -f "$fallback" ]]; then
        sc_info "$pkg: fallback initramfs present"
    else
        sc_info "$pkg: no fallback initramfs (PRESETS in /etc/mkinitcpio.d/$pkg.preset)"
    fi
    return "$rc"
}

# The kernel on the ESP must be the one whose modules are installed. If the ESP
# was unmounted during an upgrade, the ESP still holds the OLD kernel while
# /usr/lib/modules only has the new modules: it boots, then cannot load a
# single module (no disk encryption, no wifi, no GPU).
sc_check_kernel_version() {
    local boot="$1" pkg="$2" expected actual
    expected="$(sc_pkg_release "$pkg")"
    if ! actual="$(sc_image_release "$boot/vmlinuz-$pkg")"; then
        sc_warn "$pkg: could not read the version from $boot/vmlinuz-$pkg"
        return 0
    fi
    if [[ -n "$expected" && "$actual" != "$expected" ]]; then
        sc_fail "$pkg: kernel on ESP is $actual, but installed package is $expected"
        sc_hint "the upgrade wrote the kernel somewhere else - was $boot mounted? sudo pacman -S $pkg"
        return 1
    fi
    sc_ok "$pkg: kernel on ESP is $actual, matches the package"
}

sc_check_modules() {
    local pkg="$1" release
    release="$(sc_pkg_release "$pkg")"
    if [[ -z "$release" ]]; then
        sc_fail "$pkg: pacman lists no modules directory for this package"
        sc_hint "package database or install is damaged: sudo pacman -S $pkg"
        return 1
    fi
    if [[ ! -d "$SC_MODULES_DIR/$release" ]]; then
        sc_fail "$pkg: $SC_MODULES_DIR/$release is missing"
        sc_hint "sudo pacman -S $pkg"
        return 1
    fi
    sc_ok "$pkg: modules present in $SC_MODULES_DIR/$release"
}

# A running kernel that differs from the installed one is expected right after
# an upgrade. It is the reason to reboot, not a reason the reboot is unsafe.
sc_check_running_kernel() {
    local running pkg release installed=()
    running="$(sc_running_release)"
    for pkg in "$@"; do
        release="$(sc_pkg_release "$pkg")"
        if [[ "$release" == "$running" ]]; then
            sc_ok "running kernel $running ($pkg) is the installed one"
            if [[ -e "$SC_REBOOT_FLAG" ]]; then
                SC_REBOOT_PENDING=1
                sc_warn "reboot pending: flagged by pacman hook (firmware, microcode, systemd or driver upgrade)"
            fi
            return 0
        fi
        installed+=("$pkg $(sc_pkg_version "$pkg")")
    done

    SC_REBOOT_PENDING=1
    sc_warn "reboot pending: running $running, installed ${installed[*]}"
    if [[ ! -d "$SC_MODULES_DIR/$running" ]]; then
        sc_hint "modules for $running are gone: plugging in USB devices, starting VPNs or mounting new filesystems will fail until you reboot"
    fi
    return 0
}

# Services still executing code from files an upgrade deleted. Like the running
# kernel, this is a reason to reboot (or restart them), not a boot risk.
sc_check_deleted_maps() {
    local dir unit pid rc unreadable=0
    local -A stale=()

    while IFS= read -r -d '' dir; do
        unit="${dir##*/}"
        [[ -r "$dir/cgroup.procs" ]] || continue
        while IFS= read -r pid; do
            [[ -n "$pid" ]] || continue
            grep -qE "$SC_DELETED_MAP_RE" "$SC_PROC_DIR/$pid/maps" 2>/dev/null
            rc=$?
            if (( rc == 0 )); then
                stale["$unit"]=1
            elif (( rc == 2 )) && [[ -e "$SC_PROC_DIR/$pid" ]]; then
                # Exists but unreadable: another user's process. A process that
                # exited between listing and reading is simply gone, not hidden.
                unreadable=$((unreadable + 1))
            fi
        done <"$dir/cgroup.procs"
    done < <(find "$SC_CGROUP_DIR" -type d -name '*.service' -print0 2>/dev/null)

    if (( ${#stale[@]} > 0 )); then
        sc_warn "${#stale[@]} service(s) still run deleted (upgraded) code: ${!stale[*]}"
        sc_hint "restart them (sudo systemctl restart <unit>) or reboot"
    else
        sc_ok "no inspected service runs deleted code"
    fi
    if (( unreadable > 0 )); then
        sc_info "$unreadable process(es) not readable as $(id -un) - run: sudo ~/.local/bin/bootcheck"
    fi
    return 0
}

# --- runner -----------------------------------------------------------------

sc_bootcheck_run() {
    local esp pkg esp_ok=0
    local -a kernels

    sc_reset_counts
    SC_REBOOT_PENDING=0

    sc_header "bootcheck"
    esp="$(sc_find_esp)"
    if sc_check_esp_mounted "$esp"; then
        esp_ok=1
        sc_check_esp_space "$esp"
    fi

    mapfile -t kernels < <(sc_installed_kernels)
    if (( ${#kernels[@]} == 0 )); then
        sc_fail "no kernel package installed (${SC_KERNEL_PKGS[*]})"
    fi

    for pkg in "${kernels[@]}"; do
        if (( esp_ok )); then
            # Version is only meaningful once the image itself checks out.
            sc_check_kernel_images "$esp" "$pkg" && sc_check_kernel_version "$esp" "$pkg"
        else
            # Skipped, not passed: the unmounted /boot directory on / may hold a
            # perfectly good-looking kernel that the firmware will never see.
            sc_info "$pkg: image checks skipped - ESP not mounted"
        fi
        sc_check_modules "$pkg"
    done

    (( ${#kernels[@]} > 0 )) && sc_check_running_kernel "${kernels[@]}"
    sc_check_deleted_maps

    echo
    if (( SC_FAILS > 0 )); then
        printf '%s✗ NOT safe to reboot - %d problem(s) above%s\n' "$SC_RED$SC_BOLD" "$SC_FAILS" "$SC_RESET"
        return 1
    fi
    if (( SC_REBOOT_PENDING )); then
        printf '%s✓ safe to reboot%s - and a reboot is pending\n' "$SC_GREEN$SC_BOLD" "$SC_RESET"
    else
        printf '%s✓ safe to reboot%s\n' "$SC_GREEN$SC_BOLD" "$SC_RESET"
    fi
    return 0
}
