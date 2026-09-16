# Checks

One section per line that `bootcheck` and `netcheck` print.
✗ = failure (non-zero exit), ! = warning, · = information.

- [bootcheck](#bootcheck): [ESP mounted](#esp-mounted) · [ESP free space](#esp-free-space) · [Kernel image](#kernel-image-present) · [Initramfs](#initramfs-present-big-enough-not-older-than-the-kernel) · [Fallback](#fallback-initramfs) · [Kernel version](#kernel-on-esp-matches-the-package) · [Modules](#modules-directory) · [Reboot pending](#running-kernel--reboot-pending) · [Deleted code](#services-running-deleted-code)
- [netcheck](#netcheck): [wifi](#wifi-one-backend) · [link](#link-interface-and-address) · [default routes](#route-default-routes) · [ip rules](#route-ip-rules) · [exit node](#route-tailscale-exit-node) · [gw](#gw-gateway) · [icmp/tcp](#icmp--tcp-internet) · [dns](#dns-resolution) · [dns manager](#dns-manager)

---

# bootcheck

## ESP mounted

**What it means:** `/boot` (your ESP, `/dev/nvme0n1p1`, vfat) is not mounted, or something that isn't FAT is mounted there.

**Why it's serious:** this is the top cause of an unbootable Arch system. With the ESP unmounted,
`/boot` is just an empty directory on the btrfs root. pacman and mkinitcpio write the new kernel
and initramfs there and report success. The firmware never sees those files: it boots the
**old** kernel from the ESP, which then finds no matching modules. That means no `encrypt` hook
support files, no btrfs module, and the boot fails.

**How to fix:**
```bash
sudo mount /boot                  # uses the fstab entry (UUID=0B41-8688)
sudo pacman -S linux              # rewrite kernel + initramfs onto the real ESP
bootcheck
```
The copies written to the root filesystem stay hidden under the mount. They're harmless, but
they waste space. To remove them: `sudo umount /boot`, delete the files in `/boot`, then `sudo mount /boot`.

**How to prevent:** keep the `/boot` fstab entry without `noauto`. Always run `bootcheck` (or
`up`) after upgrading. For hard prevention you could add a `PreTransaction` pacman hook with
`AbortOnFail` that runs `mountpoint -q /boot` for kernel targets. That hook isn't installed.

## ESP free space

**What it means:** fewer than 60M are free on the ESP.

**Why it's serious:** a kernel upgrade rewrites `vmlinuz-linux` (~17M) and `initramfs-linux.img`
(~29M) in place. If the FAT partition fills up halfway through, the image is left truncated.
See the next two sections for why that's bad.

**How to fix:** `du -sh /boot/* /boot/EFI/*`. Remove images of kernels you uninstalled and
leftover bootloaders (e.g. `/boot/EFI/GRUB-test`, `/boot/grub` if you no longer use GRUB).

**How to prevent:** a 1G ESP holds this setup many times over. Watch out if you add several kernels
with fallback images, or UKIs.

## Kernel image present

**What it means:** `/boot/vmlinuz-<pkg>` doesn't exist for an installed kernel package.

**Why it's serious:** your systemd-boot entry (`/boot/loader/entries/arch.conf`) points at
`/vmlinuz-linux`. Without it the entry fails and there's nothing else to boot.

**How to fix:** `sudo pacman -S linux` (with the ESP mounted).

**How to prevent:** the ESP-mounted check. A missing image almost always means it was written elsewhere.

## Initramfs present, big enough, not older than the kernel

**What it means:** one of these:
- `initramfs-<pkg>.img` is missing.
- It's under 4MB. A real autodetect+zstd image here is ~29M, so this means a failed build or a cut-off write.
- Its mtime is older than the kernel's, so it was built for the previous kernel.

**Why it's serious:** a truncated initramfs is worse than a missing one. The bootloader loads it
without complaint and the kernel panics halfway through boot, before your LUKS prompt. An
initramfs built for the previous kernel has the wrong modules, so the `encrypt`/btrfs step
fails the same way.

"Not older", not "newer": FAT stores times in 2-second steps, so a kernel copy and an initramfs
build in the same step compare equal. That still counts as fine.

**How to fix:** `sudo mkinitcpio -p linux`, and read the output. Errors like missing firmware or a bad
`HOOKS=` line explain why the previous build failed.

**How to prevent:** don't interrupt `pacman` during `(n/n) Updating linux initcpios`. Keep ESP space free.

## Fallback initramfs

**What it means:** information only: whether `initramfs-<pkg>-fallback.img` exists. On this
machine it doesn't, because `/etc/mkinitcpio.d/linux.preset` has `PRESETS=('default')`.

**Why it's serious:** it isn't fatal. A fallback image skips `autodetect` and includes every module, so it
still boots after hardware changes or a bad autodetect run. Without it, a broken default image
means going straight to [recovery](recovery.md).

**How to fix / prevent:** set `PRESETS=('default' 'fallback')` in the preset, run
`sudo mkinitcpio -p linux`, and add a second loader entry pointing at `/initramfs-linux-fallback.img`.

## Kernel on ESP matches the package

**What it means:** the version string embedded in `/boot/vmlinuz-linux` is not the release that
the installed `linux` package ships (`/usr/lib/modules/<release>`).

**Why it's serious:** this is the concrete result of an upgrade that ran while the ESP was
unmounted, or of a copy to the ESP that failed. The machine boots the old kernel, which can't
load any module that matches it.

**How to fix:** mount the ESP if needed, `sudo pacman -S linux`, then `bootcheck`.

**How to prevent:** same as ESP mounted.

## Modules directory

**What it means:** `/usr/lib/modules/<release>` for an installed kernel package is missing,
or pacman's file list for the package has no modules directory at all.

**Why it's serious:** without modules the kernel can't load drivers for your NVMe disk,
dm-crypt, btrfs or wifi. The initramfs build also fails.

**How to fix:** `sudo pacman -S linux`. If pacman itself looks damaged, check with `sudo pacman -Qkk linux`.

**How to prevent:** don't delete things under `/usr/lib/modules` by hand. Let pacman own it.

## Running kernel / reboot pending

**What it means:** a warning, not a failure. The running kernel (`uname -r`) isn't the installed
one, or the pacman hook left `/var/run/reboot-required` after a firmware, microcode, systemd or
nvidia upgrade.

**Why it's serious:** after a kernel upgrade, pacman deletes the running kernel's modules. Anything
that needs a module not already loaded fails in confusing ways: USB drives, VPNs (`tun`),
new filesystems, docker networking. This was incident 1. systemd and firmware upgrades are
only half applied until you reboot.

**How to fix:** run `bootcheck`; if it passes, reboot.

**How to prevent:** reboot soon after `up` reports a pending reboot. The Waybar icon and the shell notice remind you.

## Services running deleted code

**What it means:** a warning. A running service still has an old `/usr` or `/opt` file mapped
(`/proc/<pid>/maps` shows `(deleted)`), so it's running pre-upgrade code, e.g. an old `libssl`.
As a normal user only your own processes can be read. `sudo ~/.local/bin/bootcheck` covers
root services too. `memfd:`, `/dev/shm` and SysV shm entries are ignored: they always
show `(deleted)` and mean nothing here.

**Why it's serious:** it's not a boot risk, which is why it doesn't fail. But the service still has
old code and the old security bugs, and it can crash when it loads a new plugin next to the old library.

**How to fix:** `sudo systemctl restart <unit>`, or reboot.

**How to prevent:** reboot after large upgrades. `needrestart` (not installed) automates this check and the restarts.

---

# netcheck

Runs bottom-up. The **first** ✗ is the layer to investigate; later ✗ lines are usually fallout from it.

## [wifi] one backend

**What it means:** `iwd` and `wpa_supplicant` are both running, or NetworkManager is configured
for one (`wifi.backend`, default `wpa_supplicant`) while only the other runs.

**Why it's serious:** both daemons drive the same card through nl80211. They cancel each other's
scans and tear down each other's associations. NetworkManager just reports "disconnected" and
nothing points at the cause. This was incident 2.

**How to fix:** this machine uses NetworkManager with wpa_supplicant:
```bash
sudo systemctl disable --now iwd
sudo systemctl restart NetworkManager
```

**How to prevent:** never enable `iwd.service` alongside NetworkManager unless you also set
`[device] wifi.backend=iwd` in `/etc/NetworkManager/conf.d/` and disable `wpa_supplicant`.
Remember the live ISO uses iwd (`iwctl`). Don't copy that habit to the installed system.

## [link] interface and address

**What it means:** there's no default route, or the default interface has no global IPv4/IPv6 address.

**Why it's serious:** nothing can leave the machine. Usually you're not associated with the
network, or DHCP didn't finish.

**How to fix:** `nmcli device status`, `nmcli device wifi list`, then `nmcli device wifi connect <ssid>`. For DHCP details: `journalctl -u NetworkManager -b`.

**How to prevent:** fix the wifi check first. A fighting backend is the usual cause here.

## [route] default routes

**What it means:** a warning: more than one default route in the same address family. One IPv4
plus one IPv6 is normal.

**Why it's serious:** with different metrics, all traffic uses the lowest one, which may be a
dead ethernet dongle or VPN. With equal metrics the kernel picks per destination, and some sites "randomly" fail.

**How to fix:** `ip route show default`. Bring down the unwanted connection (`nmcli connection down <name>`) or give it a higher metric.

**How to prevent:** set `ipv4.never-default yes` on VPN/secondary connections that shouldn't carry all traffic.

## [route] ip rules

**What it means:** a warning: policy routing rules exist beyond the kernel defaults (`0 local`,
`32766 main`, `32767 default`). Tailscale's rules (fwmark `0x80000`, table `52`) are recognised
and shown as information.

**Why it's serious:** a rule can send some or all traffic to a different routing table. That table
can be stale after a VPN client crashed, which makes routes that look correct in `ip route` get ignored.

**How to fix:** `ip rule` and `ip route show table <table>`. Restart or disconnect the VPN that owns the
rule. For a leftover: `sudo ip rule del priority <prio>`.

**How to prevent:** disconnect VPNs (openconnect/NTNU VPN) cleanly instead of killing them.

## [route] Tailscale exit node

**What it means:** Tailscale is routing all internet traffic through an exit node. That's a warning,
or a ✗ if the exit node is offline.

**Why it's serious:** an offline exit node black-holes all internet traffic while the LAN, the
gateway and `tailscale status` still look fine.

**How to fix:** `tailscale set --exit-node=` (empty value clears it).

**How to prevent:** use exit nodes on purpose and clear them when you leave the network that needed one.

## [gw] gateway

**What it means:** the default gateway doesn't answer ping. If it still answered ARP, that's only
a warning: the router just drops ICMP.

**Why it's serious:** with no ping and no ARP, nothing gets past your own link: wrong network,
a dropped association, or client isolation on the access point.

**How to fix:** reconnect (`nmcli device wifi connect <ssid>`), check `ip neigh`, try another access point or network.

**How to prevent:** nothing on your side. On eduroam-type networks, roaming between access points can cause this briefly.

## [icmp] / [tcp] internet

**What it means:** 1.1.1.1 can't be reached by ping and/or TCP port 80. Ping failing while TCP
works is only a warning: some networks drop ICMP.

**Why it's serious:** the gateway works, but traffic stops beyond it. Common causes are an upstream
outage, a captive portal, a firewall, or a VPN/exit node swallowing traffic.

**How to fix:** open any http:// page to trigger a captive portal. Check the exit node and ip
rules lines above. `tracepath -n 1.1.1.1` shows where it stops.

**How to prevent:** log into captive portals before debugging anything else.

## [dns] resolution

**What it means:** `getent ahosts archlinux.org` fails. netcheck then asks 1.1.1.1 directly with
`dig`. If that works, your local resolver config is broken. If not, DNS is blocked upstream.

**Why it's serious:** every name lookup fails, so it looks like "no internet" even though IP traffic flows.

**How to fix:** `cat /etc/resolv.conf` and `nmcli device show | grep DNS`. Reconnecting usually
rewrites a bad resolv.conf. As a test: `resolvectl query archlinux.org`.

**How to prevent:** keep exactly one program in charge of `/etc/resolv.conf` (see next section).

## [dns] manager

**What it means:** information only: which program writes `/etc/resolv.conf`, and whether
systemd-resolved is running without being used. On this machine NetworkManager writes the file
directly, while systemd-resolved runs alongside and is ignored by libc.

**Why it's serious:** it isn't broken today, but it's the DNS version of the iwd/wpa_supplicant
problem: two managers, one in effect. Tailscale MagicDNS and VPN split-DNS behave differently
depending on which one is in charge. That leads to "works in one app, not in another".

**How to fix / prevent:** pick one. Either `sudo systemctl disable --now systemd-resolved`
(NetworkManager keeps writing resolv.conf), or use resolved properly:
`sudo ln -sf ../run/systemd/resolve/stub-resolv.conf /etc/resolv.conf` plus
`[main] dns=systemd-resolved` in `/etc/NetworkManager/conf.d/dns.conf`, then restart NetworkManager.
