#!/bin/bash
# ==========================================================
# EtherealOS Welcome Setup
# The first-run experience for the High-End Distro
# ==========================================================

VERSION="1.0-Ultimate"
KERNEL=$(uname -r)
RAM=$(free -m | awk '/^Mem:/{print $2}')
UI="The Ethereal Architect (Cinnamon Glass Edition)"

# ASCII Art / Main Window
zenity --info --title="Welcome to EtherealOS $VERSION" \
       --text="<b>Welcome to EtherealOS</b>\nYou are running the ultimate, handcrafted operating system designed for aesthetics, performance, and limitless computing.\n\n<b>System Info:</b>\n• Interface: $UI\n• Kernel Engine: Linux $KERNEL\n• Memory: ${RAM}MB\n\n<b>What's Next?</b>\nGo to the Desktop and use the <i>Ethereal Hardware Controller</i> to instantly configure your PC's components with optimal drivers." \
       --width=450 --height=200

# Open Github or something? Or just exit cleanly.
exit 0
