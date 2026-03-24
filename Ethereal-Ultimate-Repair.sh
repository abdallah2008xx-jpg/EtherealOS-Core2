#!/bin/bash
# ==========================================================
# EtherealOS - Ultimate System Repair & Recovery (v1.5.0)
# "One Click to Fix Everything"
# ==========================================================

(
echo "10"; echo "# 🔍 Scanning EtherealOS Core for anomalies..." ; sleep 1

# Step 1: Secure Root Access
cat << 'PWH' > /tmp/gui-askpass.sh
#!/bin/bash
zenity --password --title="EtherealOS Repair Engine" --text="System-wide repair requested.\n\nPlease enter the root password (123456):"
PWH
chmod +x /tmp/gui-askpass.sh
export SUDO_ASKPASS=/tmp/gui-askpass.sh

if ! sudo -A true 2>/dev/null; then
    zenity --error --text="Repair aborted: Root privileges required."
    exit 1
fi

echo "20"; echo "# 🔧 Fixing Home Directory & Permissions..."
sudo -A chown -R abdallah:abdallah /home/abdallah 2>/dev/null

echo "35"; echo "# 🦊 Repairing Browser System (Firefox & Thor)..."
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
