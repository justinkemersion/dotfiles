#!/bin/bash
if [ "$1" = "usb" ]; then
    echo -e "defaults.pcm.card 2\ndefaults.pcm.device 0\ndefaults.ctl.card 2" > ~/.asoundrc
    echo "Switched to USB Headphones (card 2)"
elif [ "$1" = "builtin" ]; then
    echo -e "defaults.pcm.card 0\ndefaults.pcm.device 0\ndefaults.ctl.card 0" > ~/.asoundrc
    echo "Switched to Built-in Audio (card 0)"
else
    echo "Usage: $0 {usb|builtin}"
    exit 1
fi
systemctl --user restart mpd
