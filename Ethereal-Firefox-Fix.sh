#!/bin/bash
# ==========================================================
# EtherealOS - Firefox Profile Fixer
# Included in Update v1.2.1
# ==========================================================

echo "🦊 Applying Live Firefox Permission Patch..."

# Step 1: Create a secure GUI Password Prompt for root access
cat << 'PWH' > /tmp/gui-askpass.sh
#!/bin/bash
zenity --password --title="EtherealOS Security" --text="Fixing Firefox Permissions...\n\nPlease enter the root password (123456):"
PWH
chmod +x /tmp/gui-askpass.sh
export SUDO_ASKPASS=/tmp/gui-askpass.sh

# Step 2: Fix the root of the problem: The entire Home Folder!
# We use sudo -A to force sudo to use our graphical password prompt!
if sudo -A true 2>/dev/null; then
    sudo -A bash -c '
        echo "🔧 Correcting full home directory ownership..."
        chown -R abdallah:abdallah /home/abdallah 2>/dev/null
        
        echo "🦊 Purging corrupted Firefox Root Profile..."
        rm -rf /home/abdallah/.mozilla
        rm -rf /home/abdallah/.cache/mozilla
    '
    zenity --notification --window-icon="firefox" --text="🦊 Firefox Profile successfully repaired!"
else
    zenity --error --text="Failed to get root privileges. Firefox fix aborted." --title="EtherealOS Error"
fi
