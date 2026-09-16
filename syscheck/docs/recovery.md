# Recovery: arch-chroot from the live ISO

Use this when the laptop no longer boots after an upgrade: kernel panic, "no modules",
`cryptdevice` never asks for a passphrase, or systemd-boot shows no entry.
All paths below are this machine's real layout (taken from `/etc/fstab`, `lsblk`, `bootctl status`
and `/boot/loader/entries/arch.conf`, 2026-09-15).

## This machine's layout

| Device | Size | What | Mounted at |
|---|---|---|---|
| `/dev/nvme0n1p1` | 1G | ESP, vfat, `UUID=0B41-8688`, `PARTUUID=5cce2af9-e68d-448e-afc6-5619d26f9af3` | `/boot` |
| `/dev/nvme0n1p2` | 256G | LUKS, `PARTUUID=03e0fd1b-6bdf-4268-a4f3-ddc06c93f55c`, opened as `root` | - |
| `/dev/mapper/root` | | btrfs `UUID=2df4de4b-b7d8-42a9-8499-f8551558085c`: subvolume `@` → `/`, `@home` → `/home` | |
| `/dev/nvme0n1p3` | 18G | swap (unencrypted, auto-activated by partition type, not in fstab) | not needed |

- **Bootloader:** systemd-boot (`/boot/EFI/systemd/systemd-bootx64.efi`), entry `arch.conf`. The
  `GRUB-test` NVRAM entry and `/boot/grub` are leftovers. Don't `grub-install`.
- **Initramfs:** mkinitcpio, busybox `encrypt` hook:
  `HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)`.
- **Kernel cmdline:** `cryptdevice=PARTUUID=03e0fd1b-6bdf-4268-a4f3-ddc06c93f55c:root root=/dev/mapper/root rootflags=subvol=@ rw rootfstype=btrfs`
- **No `/etc/crypttab` entries:** root is unlocked by the initramfs alone.
- **No btrfs snapshots:** the only nested subvolumes are systemd's `var/lib/portables` and `var/lib/machines`.

## 1. Get the ISO

Download the current **Arch Linux ISO** (monthly release) from https://archlinux.org/download/
and write it to a USB stick from another machine:
```bash
sudo dd if=archlinux-*-x86_64.iso of=/dev/sdX bs=4M status=progress oflag=sync   # sdX = the USB stick, not a partition
```
Secure Boot is disabled on this laptop (`bootctl status`: "disabled (setup)"), so the stock ISO boots as is.
Open the firmware boot menu, pick the USB stick, and choose the UEFI entry.

Confirm you booted in UEFI mode, otherwise `bootctl install` can't work:
```bash
cat /sys/firmware/efi/fw_platform_size    # must print 64
```
The console keymap is `us`, same as the ISO, so the LUKS passphrase types the same way.

## 2. Networking in the live environment

You only need it to download packages (step 5). The live ISO uses **iwd**, not NetworkManager.

- **Easiest:** USB-tether a phone, or plug in ethernet. DHCP comes up by itself.
- **Home wifi (WPA2-Personal):**
  ```bash
  iwctl station wlan0 scan
  iwctl station wlan0 get-networks
  iwctl --passphrase '<password>' station wlan0 connect '<SSID>'
  ```
- **eduroam** (WPA2-Enterprise) needs an iwd profile in `/var/lib/iwd/eduroam.8021x`. Use tethering instead.

Check it: `ping -c 3 archlinux.org`.

## 3. Unlock and mount

```bash
lsblk -f                                        # confirm nvme0n1p1 = vfat, p2 = crypto_LUKS
cryptsetup open /dev/nvme0n1p2 root             # same mapper name the cmdline uses
mount -o subvol=@ /dev/mapper/root /mnt
```

**Look at `/mnt/boot` before mounting the ESP over it.** If there are `vmlinuz-linux` or
`initramfs-linux.img` files there, an upgrade ran while the ESP was unmounted. That's incident 1:
those files are the new kernel, and they landed on btrfs instead of the ESP.
```bash
ls -la /mnt/boot                                # should be empty
```
If it isn't empty, move them aside (`mkdir /root/stray && mv /mnt/boot/* /root/stray/`) so they
don't hide under the mount. Then mount the ESP and `/home`:
```bash
mount /dev/nvme0n1p1 /mnt/boot
mount -o subvol=@home /dev/mapper/root /mnt/home     # needed to run bootcheck inside the chroot
```

## 4. Chroot

```bash
arch-chroot /mnt
```
`arch-chroot` mounts `/proc`, `/sys`, `/dev` and efivarfs, and bind-mounts the live system's
`/etc/resolv.conf`. **Networking inside the chroot is the live environment's networking.**
It shares the same network stack, so there's nothing to start. Don't try to start NetworkManager or iwd
in there (systemctl doesn't work in a chroot). If DNS fails inside but works outside:
```bash
exit; cp /etc/resolv.conf /mnt/etc/resolv.conf; arch-chroot /mnt
```

See what's broken:
```bash
/home/bastel/.local/bin/bootcheck    # "reboot pending" is expected here: uname -r is the ISO's kernel
pacman -Q linux; ls /usr/lib/modules
```

## 5. Finish the upgrade / reinstall the kernel

If the upgrade was interrupted, finish it:
```bash
rm -f /var/lib/pacman/db.lck         # only if pacman says the database is locked and nothing else runs
pacman -Syu
```
If only the kernel files are wrong or missing:
```bash
pacman -S linux                      # rewrites /usr/lib/modules and copies vmlinuz to the ESP
```
To go back to the previous kernel from the package cache:
```bash
ls /var/cache/pacman/pkg/linux-[0-9]*
pacman -U /var/cache/pacman/pkg/linux-<previous-version>-x86_64.pkg.tar.zst
```

## 6. Regenerate the initramfs

```bash
mkinitcpio -P                        # every preset; currently just 'default' for linux
ls -la /boot/vmlinuz-linux /boot/initramfs-linux.img    # initramfs tens of MB, not older than vmlinuz
```
Read the output. An error about the `encrypt` hook or a missing module is the real problem, so fix
that and run it again. Don't reboot on a failed build.

## 7. Reinstall the bootloader

```bash
bootctl install                      # reinstalls systemd-boot to /boot and recreates the "Linux Boot Manager" NVRAM entry
bootctl status | sed -n '/Current Boot Loader/,/Random Seed/p'
efibootmgr                           # "Linux Boot Manager" should be first in BootOrder
```
If `/boot/loader/entries/arch.conf` is missing or damaged, recreate it exactly:
```bash
cat > /boot/loader/entries/arch.conf <<'EOF'
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options cryptdevice=PARTUUID=03e0fd1b-6bdf-4268-a4f3-ddc06c93f55c:root root=/dev/mapper/root rootflags=subvol=@ rw rootfstype=btrfs
EOF
printf 'timeout 5\ndefault arch.conf\n' > /boot/loader/loader.conf
```
If it is out of first place: `efibootmgr --bootorder 0003,0000,0004`. Check the number
`efibootmgr` shows for "Linux Boot Manager" first; it was `0003` on 2026-09-15.

## 8. Verify and reboot

```bash
/home/bastel/.local/bin/bootcheck    # no ✗ lines (reboot pending is fine)
exit
umount -R /mnt
cryptsetup close root
reboot
```
Remove the USB stick when the screen goes dark.

## After it boots

- Run `bootcheck` and `netcheck` on the real system.
- Consider turning on the fallback initramfs (`PRESETS=('default' 'fallback')` in
  `/etc/mkinitcpio.d/linux.preset`, plus a second loader entry). Then the next broken image has a
  boot entry to fall back to instead of this procedure.
