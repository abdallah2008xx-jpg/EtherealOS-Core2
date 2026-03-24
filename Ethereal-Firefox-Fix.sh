#!/bin/bash
# ==========================================================
# EtherealOS - Ultimate Browser Fixer (v2.0.0)
# Included in Update v3.2.0 - NUCLEAR PROFILE RESET
# ==========================================================

echo "🦊 Starting Advanced Browser Repair Engine..."

# Step 1: Force Kill Firefox and Wipe Corruption
su -c "pkill -f firefox" 2>/dev/null
su -c "pkill -f epiphany" 2>/dev/null
su -c "pkill -f thor" 2>/dev/null

echo "🔧 Executing Ultra-Deep Profile Reconstruction..."

# Step 2: Nuclear Cleaning & Reconstruction of Home Folders
su -c "
    # Correct all base permissions
    chown -R abdallah:abdallah /home/abdallah
    
    # Absolute Wipe of mozilla folder to clear 'Profile Missing' errors
    rm -rf /home/abdallah/.mozilla
    rm -rf /home/abdallah/.cache/mozilla
    
    # Re-build the structure manually (Firefox hates missing root dirs)
    mkdir -p /home/abdallah/.mozilla/firefox/ethereal.default
    
    # Create the CRITICAL profiles.ini file (This solves the popup!)
    cat << 'INI' > /home/abdallah/.mozilla/firefox/profiles.ini
[General]
StartWithLastProfile=1

[Profile0]
Name=Ethereal
IsRelative=1
Path=ethereal.default
Default=1
INI

    # Final ownership fix on the new files
    chown -R abdallah:abdallah /home/abdallah/.mozilla
" > /dev/null 2>&1

# Step 3: Ensure Thor (Emergency Backup) works too
if command -v epiphany >/dev/null 2>&1; then
    su -c "ln -sf /usr/bin/epiphany /usr/bin/thor" > /dev/null 2>&1
fi

# Step 4: Final Success Notification
zenity --info --title="Browser Repaired" --text="🦊 Firefox Profile has been reconstructed!\n\nTry opening it now. It will start with a fresh 'Ethereal' profile.\n\n⚡ Thor Browser is also available as backup." --width=350 2>/dev/null
