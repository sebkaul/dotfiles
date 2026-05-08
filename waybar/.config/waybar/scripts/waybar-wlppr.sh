#!/bin/bash
wallpapers=(/home/bastel/Wallpapers/*)
current=$(cat ~/.cache/current_wallpaper_index 2>/dev/null || echo -1)
next=$(( (current + 1) % ${#wallpapers[@]} ))
hyprctl dispatch wallpaper "eDP-1:${wallpapers[$next]}"
echo $next > ~/.cache/current_wallpaper_index

