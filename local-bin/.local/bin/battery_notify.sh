#!/bin/bash

BAT="/org/freedesktop/UPower/devices/battery_BAT1"
THRESHOLD=20
CRITICAL=10
CHARGENOW=5

LOW_SENT=0
CRIT_SENT=0
NOW_SENT=0

while true; do
    INFO=$(upower -i "$BAT")

    PERCENT=$(echo "$INFO" | awk -F': *' '/^ *percentage:/ {gsub("%","",$2); print $2}')
    STATE=$(echo "$INFO"   | awk -F': *' '/^ *state:/ {print $2}')

    # Reset flags if battery level goes above thresholds
    if [ "$PERCENT" -gt "$THRESHOLD" ]; then
        LOW_SENT=0
    fi

    if [ "$PERCENT" -gt "$CRITICAL" ]; then
        CRIT_SENT=0
    fi

    if [ "$PERCENT" -gt "$CHARGENOW" ]; then
        NOW_SENT=0
    fi

    if [ "$STATE" = "discharging" ]; then

        if [ "$PERCENT" -le "$CHARGENOW" ] && [ "$NOW_SENT" -eq 0 ]; then
            notify-send -u critical "CHARGE THE PC BRUH" "${PERCENT}% remaining"
            NOW_SENT=1

        elif [ "$PERCENT" -le "$CRITICAL" ] && [ "$CRIT_SENT" -eq 0 ]; then
            notify-send -u critical "Battery Critical" "${PERCENT}% remaining"
            CRIT_SENT=1

        elif [ "$PERCENT" -le "$THRESHOLD" ] && [ "$LOW_SENT" -eq 0 ]; then
            notify-send "Battery Low" "${PERCENT}% remaining"
            LOW_SENT=1
        fi

    fi

    sleep 10
done
