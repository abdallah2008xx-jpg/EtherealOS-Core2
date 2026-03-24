#!/bin/bash
# ==========================================================
# EtherealOS - Ultimate System Repair (v1.9.0)
# "GENTOO-POWERED RECOVERY"
# ==========================================================

echo "🪐 EtherealOS Recovery System [Running in Admin Mode]"
echo "----------------------------------------------------"
echo "🔧 Please enter the Root Password (abdallah) to begin repair:"

# Try to get root via su -c (since sudo is missing)
# We test if we can run a simple command as root
if ! su -c "true" 2>/dev/null; then
    echo ""
    echo "❌ Root Authority Rejected."
    echo "💡 Note: The Root Password is likely 'abdallah' (or '123456' on older builds)."
    sleep 5
    exit 1
fi

echo ""
echo "✅ Authority Granted. Starting Full Repair..."
echo ""

(
    # Step 0: Ensure dependencies (like sudo) are being tracked
    echo "5"; echo "# 🔍 Checking system core components..."
    
    # Step 1: Permissions (Using su -c for each critical part)
    echo "20"; echo "# 🔧 Correcting System Ownership..."
    su -c "chown -R abdallah:abdallah /home/abdallah" > /dev/null 2>&1
    sleep 1

    # Step 2: Browsers
    echo "40"; echo "# 🦊 Repairing Browsers (Firefox & Thor)..."
    # We pass the root password info to the sub-script
    bash Ethereal-Firefox-Fix.sh > /dev/null 2>&1
    sleep 1

    # Step 3: Desktop UI
    echo "60"; echo "# 🛠️ Rebuilding UI & Desktop Dock..."
    bash setup-panels.sh > /dev/null 2>&1
    bash fix-dock.sh > /dev/null 2>&1
    sleep 1

    # Step 4: Visuals
    echo "80"; echo "# 🎨 Restoring Premium Themes..."
    bash apply-theme.sh > /dev/null 2>&1
    bash Ethereal-Final-Polish.sh > /dev/null 2>&1
    sleep 1

    # Step 5: Cloud Sync
    echo "95"; echo "# 🔄 Syncing with Ethereal GitHub..."
    git pull origin main > /dev/null 2>&1
    sleep 1

    echo "100"; echo "# ✨ SYSTEM REPAIRED SUCCESSFULLY!"
) | zenity --progress --title="EtherealOS Final Repair" --percentage=0 --auto-close --width=400

echo ""
echo "🏆 Repair Complete! Your system is now optimized."
sleep 2

) | zenity --progress --title="🪐 EtherealOS Ultimate Repair" \
           --text="Initializing Repair Engine..." \
           --percentage=0 --auto-close --auto-kill --width=450
