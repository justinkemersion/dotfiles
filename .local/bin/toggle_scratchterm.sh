#!/bin/sh
# Check if a terminal with the title "scratchterm" exists
if swaymsg -t get_tree | grep -q '"title": "scratchterm"'; then
    # If it exists, toggle its visibility
    swaymsg [title="scratchterm"] scratchpad show
else
    # If it doesn’t exist, launch it with a unique title
    alacritty --title scratchterm &
    # Wait for the window to appear
    while ! swaymsg -t get_tree | grep -q '"title": "scratchterm"'; do
        sleep 0.1
    done
    # Move it to the scratchpad and show it
    swaymsg [title="scratchterm"] move scratchpad
    swaymsg [title="scratchterm"] scratchpad show
fi
