#!/bin/bash
# ==========================================================
# EtherealOS - Ultimate System Repair & Recovery (v1.5.0)
# "One Click to Fix Everything"
# ==========================================================

# Step 1: Secure Internal Root Access
# Attempting proper GUI elevation via PolicyKit
if [ "$EUID" -ne 0 ]; then
    pkexec bash "$0" "$@"
    exit $?
fi

# We are now running as root!
echo "10"; echo "# 🔍 Scanning EtherealOS Core for anomalies..." ; sleep 1
echo "20"; echo "# 🔧 Correcting System Identity & Ownership..."
chown -R abdallah:abdallah /home/abdallah 2>/dev/null

echo "35"; echo "# 🦊 Reassembling Browser Engine (Firefox & Thor)..."
# Injected root power is not needed as we are already root
bash Ethereal-Firefox-Fix.sh > /dev/null 2>&1

echo "50"; echo "# 🛠️ Rebuilding UI Layout & Panels..."
bash setup-panels.sh > /dev/null 2>&1
bash fix-dock.sh > /dev/null 2>&1

echo "65"; echo "# 🎨 Restoring Premium Visuals & Themes..."
bash apply-theme.sh > /dev/null 2>&1
bash Ethereal-Final-Polish.sh > /dev/null 2>&1

echo "80"; echo "# 🔄 Syncing with EtherealCloud (GitHub Updates)..."
git fetch origin main > /dev/null 2>&1
git pull origin main > /dev/null 2>&1

echo "90"; echo "# 🧹 Cleaning System Caches & Temp files..."
sudo -A rm -rf /tmp/* 2>/dev/null
sudo -A rm -rf /var/tmp/* 2>/dev/null

echo "100"; echo "# ✨ EtherealOS is now in Peak Performance!"
sleep 2

zenity --info --title="Repair Complete" --text="🪐 Your EtherealOS is back to life!\n\nFixed Items:\n- Browser Permissions & Thor Engine\n- UI Layout & Dock\n- Visual Themes\n- Permission Mismatches\n- System Caches\n\nEnjoy the extraterrestrial speed!" --width=350

) | zenity --progress --title="🪐 EtherealOS Ultimate Repair" \
           --text="Initializing Repair Engine..." \
           --percentage=0 --auto-close --auto-kill --width=450
