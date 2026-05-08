#!/bin/bash
# Check if Waybar is running
if pgrep -x "waybar" > /dev/null; then
    # Kill Waybar if running
    pkill -x waybar
else
    # Start Waybar in the background
    waybar &
            fi

