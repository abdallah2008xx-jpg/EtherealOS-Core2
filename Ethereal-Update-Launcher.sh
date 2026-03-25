#!/bin/bash
# ==========================================================
# EtherealOS Update Launcher - VM/LiveCD Safe v2
# Robust update system that works even after VM restarts
# ==========================================================

UPDATE_DIR="$HOME/ethereal-update"
REPO_URL="https://github.com/abdallah2008xx-jpg/EtherealOS-Core.git"

echo "🪐 EtherealOS Update System v2"
echo "==============================="

# 1. Check if update directory exists, create if needed
if [ ! -d "$UPDATE_DIR" ]; then
    echo "📁 Creating update directory..."
    mkdir -p "$UPDATE_DIR"
fi

cd "$UPDATE_DIR" || exit 1

# 2. Check if git repo exists and is valid
if [ -d ".git" ]; then
    # Test if git repo is valid
    git status >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "⚠️ Corrupted git repo detected. Cleaning..."
        rm -rf .git
    fi
fi

# 3. Clone if no valid repo
if [ ! -d ".git" ]; then
    echo "⬇️ Cloning EtherealOS repository..."
    git clone --depth 1 "$REPO_URL" . 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "❌ Failed to clone. Trying with full cleanup..."
        cd "$HOME"
        rm -rf "$UPDATE_DIR"
        mkdir -p "$UPDATE_DIR"
        cd "$UPDATE_DIR" || exit 1
        git clone --depth 1 "$REPO_URL" . 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "❌ Failed to clone repository. Check internet connection."
            read -p "Press Enter to exit..."
            exit 1
        fi
    fi
    echo "✅ Repository cloned!"
fi

# 4. Pull latest updates
echo "🔄 Checking for updates..."
git pull origin main 2>/dev/null
if [ $? -ne 0 ]; then
    echo "⚠️ Git pull failed. Forcing fresh fetch..."
    git fetch --depth 1 origin main 2>/dev/null
    git reset --hard origin/main 2>/dev/null
fi

# 5. Check if Update Manager exists
if [ ! -f "Ethereal-Update-Manager.py" ]; then
    echo "❌ Update Manager not found! Re-cloning..."
    cd "$HOME"
    rm -rf "$UPDATE_DIR"
    mkdir -p "$UPDATE_DIR"
    cd "$UPDATE_DIR" || exit 1
    git clone --depth 1 "$REPO_URL" . 2>/dev/null
    if [ ! -f "Ethereal-Update-Manager.py" ]; then
        echo "❌ Update Manager still not found! Repository issue."
        read -p "Press Enter to exit..."
        exit 1
    fi
fi

# 6. Run the Update Manager
echo "🚀 Starting Update Manager..."
python3 Ethereal-Update-Manager.py
