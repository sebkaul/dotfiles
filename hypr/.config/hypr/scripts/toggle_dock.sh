#!/bin/bash

# Check if nwg-dock is running
if pgrep "nwg-dock" > /dev/null; then
    # Kill Waybar if running
    pkill nwg-dock
else
    # Start Waybar in the background
    nwg-dock-hyprland -i 32 -nolauncher -l "top" -mb -49 &
fi

