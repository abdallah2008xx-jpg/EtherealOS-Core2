#!/bin/bash
# ==========================================================
# EtherealOS - System Snapshot (Timeshift Wrapper)
# ==========================================================

if [[ $EUID -ne 0 ]]; then
   zenity --error --text="Root privileges required to create snapshots. Please run as root or via sudo." --width=300
   exit 1
fi

(
echo "10"; echo "# 🔍 Checking Timeshift configuration..." ; sleep 1
if ! command -v timeshift &> /dev/null; then
    echo "100"; echo "# ❌ Timeshift not found! Please install it via Ethereal Store."
    sleep 2
    exit 1
fi

echo "30"; echo "# 📸 Creating System Snapshot..."
pkexec timeshift --create --comments "Manual Snapshot (Ethereal Tool)" --tags M

echo "100"; echo "# ✨ Snapshot created successfully!"
sleep 1
) | zenity --progress --title="🪐 EtherealOS Snapshot" \
           --text="Initializing..." \
           --percentage=0 --auto-close --width=400 2>/dev/null

if [ $? -eq 0 ]; then
    zenity --info --title="Success" --text="✅ System snapshot created.\nYou can restore it anytime using Timeshift GUI." --width=300 2>/dev/null
fi
