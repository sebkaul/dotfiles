#!/bin/bash
while ! hyprctl monitors | grep -q "eDP-1"; do
    sleep 0.2
done
hyprpaper --config ~/.config/hypr/hyprpaper.conf &

