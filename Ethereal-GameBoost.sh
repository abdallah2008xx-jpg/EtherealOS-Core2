#!/bin/bash
# ==========================================================
# EtherealOS Game Boost Feature (Added in Update v1.2)
# ==========================================================

if [ "$1" == "--install" ]; then
    # Create the Desktop Entry the correct way
    cat << 'EOF' > /home/abdallah/Desktop/Ethereal_GameBoost.desktop
[Desktop Entry]
Name=🚀 Ethereal Game Boost
Comment=Maximize CPU performance and free RAM for gaming
Exec=bash -c "/media/sf_gentoo-files/EtherealOS-Repo/Ethereal-GameBoost.sh --activate"
Icon=input-gaming
Terminal=false
Type=Application
EOF
    chmod +x /home/abdallah/Desktop/Ethereal_GameBoost.desktop
    chmod +x "$0"
    exit 0
fi

if [ "$1" == "--activate" ]; then
    # Ask for root using Zenity to do system-level optimizations
    pkexec bash -c '
        echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null 2>&1
        sync; echo 3 > /proc/sys/vm/drop_caches
    '
    
    if [ $? -eq 0 ]; then
        zenity --info --title="Ethereal Game Boost" --text="⚡ <b>Game Boost Activated!</b>\n\n- Unnecessary RAM Cache Cleared\n- CPU set to Maximum Performance limit\n\nYour system is now optimized for gaming." --width=300
    fi
    exit 0
fi
