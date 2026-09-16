#!/usr/bin/env bash
# waybar-reboot.sh — custom/reboot: shows an icon only while a reboot is pending.
# Empty text makes waybar hide the module entirely.
#
# Pending means either:
#   * the 95-reboot-pending pacman hook left its flag (kernel, firmware,
#     microcode, systemd or nvidia upgrade), or
#   * the running kernel's modules are gone - the kernel was upgraded before
#     the hook was deployed, or by a transaction the hook didn't cover.
set -euo pipefail

flag=/var/run/reboot-required
running="$(uname -r)"

if [[ ! -d "/usr/lib/modules/$running" ]]; then
    tooltip="Reboot pending: kernel $running is running, its modules were replaced by an upgrade.\nClick to run bootcheck."
elif [[ -e "$flag" ]]; then
    tooltip="Reboot pending: boot-time packages were upgraded.\nClick to run bootcheck."
else
    printf '{"text": "", "class": "idle"}\n'
    exit 0
fi

icon=$'\U000F0709' # nf-md-restart
printf '{"text": "%s", "tooltip": "%s", "class": "pending"}\n' "$icon" "$tooltip"
