#!/bin/bash
# Control MacBook Pro 2012 keyboard and display backlights (gmux)
# Run from ~/.local/bin/: backlight.sh {kbd_up|kbd_down|kbd_set|disp_up|disp_down|disp_set}

KBD_BACKLIGHT="/sys/class/leds/smc::kbd_backlight/brightness"
DISP_BACKLIGHT="/sys/class/backlight/gmux_backlight/brightness"
KBD_MAX=100
DISP_MAX=$(cat /sys/class/backlight/gmux_backlight/max_brightness 2>/dev/null || echo 82311)

# Check if nodes exist
[ ! -f "$KBD_BACKLIGHT" ] && { echo "Error: Keyboard backlight not found"; exit 1; }
[ ! -f "$DISP_BACKLIGHT" ] && { echo "Error: Display backlight not found"; exit 1; }

# Get current brightness
KBD_CURRENT=$(cat "$KBD_BACKLIGHT")
DISP_CURRENT=$(cat "$DISP_BACKLIGHT")

# Step size (~10% of max)
KBD_STEP=10
DISP_STEP=8200

case "$1" in
    kbd_up)
        NEW_KBD=$((KBD_CURRENT + KBD_STEP))
        [ "$NEW_KBD" -gt "$KBD_MAX" ] && NEW_KBD="$KBD_MAX"
        sudo sh -c "echo $NEW_KBD > $KBD_BACKLIGHT"
        echo "Keyboard brightness: $NEW_KBD"
        ;;
    kbd_down)
        NEW_KBD=$((KBD_CURRENT - KBD_STEP))
        [ "$NEW_KBD" -lt 0 ] && NEW_KBD=0
        sudo sh -c "echo $NEW_KBD > $KBD_BACKLIGHT"
        echo "Keyboard brightness: $NEW_KBD"
        ;;
    kbd_set)
        if [[ "$2" =~ ^[0-9]+$ && "$2" -le "$KBD_MAX" ]]; then
            sudo sh -c "echo $2 > $KBD_BACKLIGHT"
            echo "Keyboard brightness set to $2"
        else
            echo "Invalid keyboard brightness (0-$KBD_MAX)"
            exit 1
        fi
        ;;
    disp_up)
        NEW_DISP=$((DISP_CURRENT + DISP_STEP))
        [ "$NEW_DISP" -gt "$DISP_MAX" ] && NEW_DISP="$DISP_MAX"
        sudo sh -c "echo $NEW_DISP > $DISP_BACKLIGHT"
        echo "Display brightness: $NEW_DISP"
        ;;
    disp_down)
        NEW_DISP=$((DISP_CURRENT - DISP_STEP))
        [ "$NEW_DISP" -lt 0 ] && NEW_DISP=0
        sudo sh -c "echo $NEW_DISP > $DISP_BACKLIGHT"
        echo "Display brightness: $NEW_DISP"
        ;;
    disp_set)
        if [[ "$2" =~ ^[0-9]+$ && "$2" -le "$DISP_MAX" ]]; then
            sudo sh -c "echo $2 > $DISP_BACKLIGHT"
            echo "Display brightness set to $2"
        else
            echo "Invalid display brightness (0-$DISP_MAX)"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 {kbd_up|kbd_down|kbd_set <0-$KBD_MAX>|disp_up|disp_down|disp_set <0-$DISP_MAX>}"
        exit 1
        ;;
esac