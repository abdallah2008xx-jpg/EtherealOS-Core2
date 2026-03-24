#!/bin/bash
# ==========================================================
# EtherealOS Update v4.13 - LIGHTWEIGHT Auto-Updater
# ==========================================================

cd "$(dirname "$0")"
REPO_DIR="$(pwd)"

# ═══════════════════════════════════════════
# STEP 1: Fix Browser FIRST (outside zenity pipe!)
# ═══════════════════════════════════════════
mkdir -p /home/abdallah/.mozilla/firefox/ethereal.default-release
if [ ! -f /home/abdallah/.mozilla/firefox/profiles.ini ]; then
    cat > /home/abdallah/.mozilla/firefox/profiles.ini << 'PROF'
[Install4F96D1932A9F858E]
Default=ethereal.default-release
Locked=1

[General]
StartWithLastProfile=1
Version=2

[Profile0]
Name=default-release
IsRelative=1
Path=ethereal.default-release
Default=1
PROF
fi

# Deploy autostart for future boots
mkdir -p /home/abdallah/.config/autostart
cp Ethereal-Browser-Autostart.desktop /home/abdallah/.config/autostart/ 2>/dev/null
cp Ethereal-Notifier-Autostart.desktop /home/abdallah/.config/autostart/ 2>/dev/null

# ═══════════════════════════════════════════
# STEP 2: Update & Deploy (inside zenity for UI)
# ═══════════════════════════════════════════
(
echo "10"; echo "# 📡 Contacting Ethereal Servers..." ; sleep 1

echo "25"; echo "# ⬇️ Downloading Updates..."
git pull origin main > /dev/null 2>&1
sleep 1

echo "45"; echo "# 🧹 Cleaning old desktop icons..."
# Remove ALL old .desktop files from Desktop, then re-copy fresh ones
# This ensures deleted icons (like TaskMgr) get removed properly
rm -f /home/abdallah/Desktop/*.desktop 2>/dev/null

echo "55"; echo "# 📂 Deploying Desktop Icons..."
mkdir -p /home/abdallah/Desktop
# Copy all .desktop files from repo EXCEPT internal Autostart ones
find "$REPO_DIR" -maxdepth 1 -name "*.desktop" ! -name "*-Autostart.desktop" -exec cp {} /home/abdallah/Desktop/ \;
chmod +x /home/abdallah/Desktop/*.desktop 2>/dev/null

echo "80"; echo "# 🎨 Applying Theme..."
bash apply-theme.sh > /dev/null 2>&1

echo "100"; echo "# ✨ Update Complete!"
sleep 1
) | zenity --progress --title="🪐 EtherealOS Update" \
           --text="Checking for updates..." \
           --percentage=0 --auto-close --auto-kill --width=400 2>/dev/null

VERSION=$(cat "$REPO_DIR/version.txt" 2>/dev/null || echo "latest")
zenity --info --title="Update Complete" --text="✅ EtherealOS v${VERSION} Updated!\n\n🦊 Firefox is ready.\n🖱️ Right-click taskbar → Task Manager" --width=300 2>/dev/null &
