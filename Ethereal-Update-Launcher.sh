#!/bin/bash
# ==========================================================
# EtherealOS Update Launcher - VM/LiveCD Safe
# Robust update system that works even after VM restarts
# ==========================================================

UPDATE_DIR="$HOME/ethereal-update"
REPO_URL="https://github.com/abdallah2008xx-jpg/EtherealOS-Core.git"

echo "🪐 EtherealOS Update System"
echo "============================"

# 1. Check if update directory exists, create/clone if needed
if [ ! -d "$UPDATE_DIR" ]; then
    echo "📁 Creating update directory..."
    mkdir -p "$UPDATE_DIR"
fi

cd "$UPDATE_DIR" || exit 1

# 2. Check if it's a git repo, if not clone it
if [ ! -d ".git" ]; then
    echo "⬇️ First run: Cloning EtherealOS repository..."
    git clone --depth 1 "$REPO_URL" . 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "❌ Failed to clone repository. Check internet connection."
        read -p "Press Enter to exit..."
        exit 1
    fi
    echo "✅ Repository cloned successfully!"
fi

# 3. Pull latest updates
echo "🔄 Checking for updates..."
git pull origin main 2>/dev/null
if [ $? -ne 0 ]; then
    echo "⚠️ Git pull failed. Trying to fetch fresh..."
    git fetch --depth 1 origin main 2>/dev/null
    git reset --hard origin/main 2>/dev/null
fi

# 4. Check if Update Manager exists
if [ ! -f "Ethereal-Update-Manager.py" ]; then
    echo "❌ Update Manager not found in repository!"
    read -p "Press Enter to exit..."
    exit 1
fi

# 5. Run the Update Manager
echo "🚀 Starting Update Manager..."
python3 Ethereal-Update-Manager.py
