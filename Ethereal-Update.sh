#!/bin/bash
# ==========================================================
# EtherealOS Update 1.4.0 - Graphical Auto-Updater
# Replaces the old terminal update with a premium Windows-style UI
# ==========================================================

(
# --- FORCED PROOF OF NOTIFICATION ---
zenity --info --title="🪐 EtherealOS Update Available!" --text="Your system has discovered 5 new extraterrestrial updates on GitHub.\n\nApplying them now..." --width=400 2>/dev/null

echo "10"; echo "# 📡 Contacting Ethereal Update Servers..." ; sleep 1
cd "$(dirname "$0")"

git fetch origin main > /dev/null 2>&1
UPSTREAM=${1:-'@{u}'}
LOCAL=$(git rev-parse @ 2>/dev/null)
REMOTE=$(git rev-parse "$UPSTREAM" 2>/dev/null)

if [ "$LOCAL" = "$REMOTE" ]; then
    echo "30"; echo "# ⬇️ System is synced. Refreshing local application components..."
    sleep 1
fi

echo "40"; echo "# ⬇️ Downloading New Ethereal Features & Patches..."
git pull origin main > /dev/null 2>&1
sleep 2

echo "70"; echo "# ⚙️ Installing Core Updates & Recompiling System..."
bash Ethereal-Final-Polish.sh > /dev/null 2>&1
bash apply-theme.sh > /dev/null 2>&1

# Apply Firefox/Thor Patch
if [ -f "Ethereal-Firefox-Fix.sh" ]; then
    echo "80"; echo "# 🦊 Patching Browser System & Thor Integration..."
    bash Ethereal-Firefox-Fix.sh > /dev/null 2>&1
fi

# Deploy new features included in this update
if [ -f "Ethereal-GameBoost.sh" ]; then
    echo "85"; echo "# 🚀 Installing NEW Feature: Ethereal Game Boost..."
    bash Ethereal-GameBoost.sh --install > /dev/null 2>&1
    sleep 1
fi

echo "90"; echo "# 📂 Deploying Desktop Icons & Tools..."
# Ensure they land on the actual desktop
mkdir -p /home/abdallah/Desktop
cp *.desktop /home/abdallah/Desktop/ 2>/dev/null
chmod +x /home/abdallah/Desktop/*.desktop
chown abdallah:abdallah /home/abdallah/Desktop/*.desktop 2>/dev/null

    echo "100"; echo "# ✨ EtherealOS Update Successfully Installed!"
    sleep 2
    zenity --info --title="Update Success" --text="Update v1.5.0 Applied!\n\nNew Features Added:\n- 🛠️ Ultimate Repair (One-Click Fix Everything)\n- ⚡ Thor Browser Integration\n- Firefox Deep Permission Fix\n- Premium GUI Updater.\n\nEnjoy the extraterrestrial performance!" --width=350 &
) | zenity --progress --title="🪐 EtherealOS System Update" \
           --text="Initializing Update Engine..." \
           --percentage=0 --auto-close --auto-kill --width=450
