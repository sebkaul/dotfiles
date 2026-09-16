# syscheck

Two one-shot diagnostics, plus the hooks that make you run them:

- **`bootcheck`**: is it safe to reboot? Exit 0 = safe, 1 = the next boot is at risk.
- **`netcheck`**: where does connectivity break? It checks layers bottom-up, so the first ✗ is where to look.

## Why

1. A big `pacman -Syu` replaced the kernel. I didn't reboot, and things broke in confusing
   ways: the running kernel's modules were gone. Worse cases are an unmounted ESP (pacman
   writes the kernel into an empty `/boot` on root and reports success) or a truncated initramfs.
   Both only show up at the next boot.
2. NetworkManager's `wpa_supplicant` and `iwd` were both running. They fought over the wifi
   card and nothing showed it. It took hours to find.

## Install

```bash
cd ~/dotfiles
stow syscheck                 # bootcheck, netcheck, lib -> ~/.local  (also in install.sh)
./install.sh --system         # ROOT: copies the pacman hook to /etc/pacman.d/hooks/
```

`--system` copies instead of symlinking. pacman runs hooks as root, and a symlink into a
user-writable repo would let anything running as you change what root executes. Re-run it
after editing the hook.

The rest of the integration lives in other packages:
| Where | What |
|---|---|
| `zsh/.zshrc` | `up` / `update`: `paru -Syu` → `bootcheck` → notification; reboot notice at the first prompt |
| `waybar/…/modules.jsonc` | `custom/reboot`: icon only while a reboot is pending; click runs bootcheck in ghostty |
| `system/etc/pacman.d/hooks/95-reboot-pending.hook` | touches `/var/run/reboot-required` after kernel/firmware/ucode/systemd/nvidia upgrades |

## Usage

```bash
up                            # upgrade + bootcheck; non-zero exit if either failed
bootcheck                     # before any reboot
sudo ~/.local/bin/bootcheck   # also inspects root-owned services for deleted code
netcheck                      # when "the internet is broken"
syscheck/tests/run.sh         # tests against fake ESP/proc/network (SHOW=1 prints output)
```

Every line explained: [docs/checks.md](docs/checks.md) · Unbootable: [docs/recovery.md](docs/recovery.md) ·
Not installed but useful: `needrestart` (a fuller version of the deleted-code check that can also restart services).

## Example output

Passing (real output from this laptop):
```
bootcheck
  ✓ ESP mounted at /boot (/dev/nvme0n1p1, vfat)
  ✓ ESP free space: 948M
  ✓ linux: /boot/vmlinuz-linux present
  ✓ linux: initramfs 27M, built after the kernel
  · linux: no fallback initramfs (PRESETS in /etc/mkinitcpio.d/linux.preset)
  ✓ linux: kernel on ESP is 7.2.4-arch1-2, matches the package
  ✓ linux: modules present in /usr/lib/modules/7.2.4-arch1-2
  ✓ running kernel 7.2.4-arch1-2 (linux) is the installed one
  ✓ no inspected service runs deleted code
  · 23 process(es) not readable as bastel - run: sudo ~/.local/bin/bootcheck

✓ safe to reboot
```

Failing: fixture output from `tests/run.sh` (an upgrade that ran with the ESP unmounted).
Temp paths are shown as `/boot`:
```
  ✓ linux: initramfs 20M, built after the kernel
  ✗ linux: kernel on ESP is 7.1.9-arch1-1, but installed package is 7.2.4-arch1-2
      → the upgrade wrote the kernel somewhere else - was /boot mounted? sudo pacman -S linux

✗ NOT safe to reboot - 1 problem(s) above
```

Passing `netcheck` (real; addresses redacted because this repo is public):
```
  ✓ [wifi]  one backend: wpa_supplicant (NetworkManager expects wpa_supplicant)
  ✓ [link]  wlan0: 10.x.x.x/18 2001:db8::x/64
  ✓ [route] no unexpected ip rules
  · [route] 8 Tailscale ip rule(s) (normal while tailscaled runs)
  ✓ [gw]    10.x.x.1 answers ping
  ✓ [tcp]   1.1.1.1:80 connects
  ✓ [dns]   archlinux.org resolves

✓ connected
```

Failing `netcheck` (fixture: incident 2):
```
  ✗ [wifi]  iwd AND wpa_supplicant are BOTH running - they fight over the wifi card
      → NetworkManager uses wpa_supplicant. Stop the other: sudo systemctl disable --now iwd

✗ connectivity breaks at: wifi backend
```
