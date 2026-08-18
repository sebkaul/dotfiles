#!/usr/bin/env bash
# Toggle between the layouts declared in hyprland.conf (kb_layout = us,no).
# Uses switchxkblayout so nothing is written to disk and no reload happens --
# a reload would re-apply the monitor= rules and make the screen flash.

hyprctl switchxkblayout all next >/dev/null

case "$(hyprctl -j devices | jq -r '.keyboards[] | select(.main) | .active_keymap')" in
    Norwegian*) notify-send -t 1000 -h string:x-canonical-private-synchronous:kblayout "Keyboard layout: Norwegian" ;;
    *)          notify-send -t 1000 -h string:x-canonical-private-synchronous:kblayout "Keyboard layout: American" ;;
esac
