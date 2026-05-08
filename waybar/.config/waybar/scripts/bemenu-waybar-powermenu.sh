#!/usr/bin/env bash

choice=$(printf " Lock\n⏾ Suspend\n⏻ Shutdown\n Reboot\n Logout" | \
    bemenu --center --width-factor 0.6 --fn "JetBrainsMono Nerd Font 50" --line-height 40 \
    #--tb "#1e1e2e" \
    #--tf "#cdd6f4" \
    #--fb "#1e1e2e" \
    #--ff "#cdd6f4" \
    #--nb "#1e1e2e" \
    #--nf "#cdd6f4" \
    #--hb "#89b4fa" \
    #--hf "#1e1e2e" \
    --prompt "Power")


case "$choice" in
  " Lock")
    swaylock -f -c 000000 --scaling fill --clock --indicator
    ;;
  "⏾ Suspend")
    systemctl suspend
    ;;
  "⏻ Shutdown")
    systemctl poweroff
    ;;
  " Reboot")
    systemctl reboot
    ;;
  " Logout")
    hyprctl dispatch exit
    ;;
esac

