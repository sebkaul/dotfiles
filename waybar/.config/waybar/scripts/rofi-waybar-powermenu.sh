#!/usr/bin/env bash
choice=$(printf " Lock\n⏾ Suspend\n⏻ Shutdown\n Reboot\n Logout" | \
    rofi -dmenu -theme ~/.config/rofi/powermenu.rasi --prompt "Power")

case "$choice" in
  " Lock") swaylock -f -c 000000 --scaling fill --clock --indicator ;;
  "⏾ Suspend") systemctl suspend ;;
  "⏻ Shutdown") systemctl poweroff ;;
  " Reboot") systemctl reboot ;;
  " Logout") hyprctl dispatch exit ;;
esac

