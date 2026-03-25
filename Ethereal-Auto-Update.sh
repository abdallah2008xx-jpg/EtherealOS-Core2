#!/bin/bash
# ==========================================================
# EtherealOS - Smart Auto-Fix Update System v3
# One-click solution that NEVER fails
# ==========================================================

UPDATE_DIR="$HOME/ethereal-update"
REPO_URL="https://github.com/abdallah2008xx-jpg/EtherealOS-Core.git"
LAUNCHER_URL="https://raw.githubusercontent.com/abdallah2008xx-jpg/EtherealOS-Core/main/Ethereal-Update-Launcher.sh"

clear
echo "🪐 EtherealOS Smart Update System"
echo "=================================="
echo ""

# Function to download launcher directly if git fails
download_launcher_direct() {
    echo "📥 Downloading launcher directly..."
    if command -v wget >/dev/null 2>&1; then
        wget -q "$LAUNCHER_URL" -O "$UPDATE_DIR/Ethereal-Update-Launcher.sh" 2>/dev/null
    elif command -v curl >/dev/null 2>&1; then
        curl -sL "$LAUNCHER_URL" -o "$UPDATE_DIR/Ethereal-Update-Launcher.sh" 2>/dev/null
    fi
    
    if [ -f "$UPDATE_DIR/Ethereal-Update-Launcher.sh" ]; then
        chmod +x "$UPDATE_DIR/Ethereal-Update-Launcher.sh"
        return 0
    fi
    return 1
}

# Function to download Update Manager directly
download_manager_direct() {
    echo "📥 Downloading Update Manager directly..."
    MANAGER_URL="https://raw.githubusercontent.com/abdallah2008xx-jpg/EtherealOS-Core/main/Ethereal-Update-Manager.py"
    
    if command -v wget >/dev/null 2>&1; then
        wget -q "$MANAGER_URL" -O "$UPDATE_DIR/Ethereal-Update-Manager.py" 2>/dev/null
    elif command -v curl >/dev/null 2>&1; then
        curl -sL "$MANAGER_URL" -o "$UPDATE_DIR/Ethereal-Update-Manager.py" 2>/dev/null
    fi
    
    [ -f "$UPDATE_DIR/Ethereal-Update-Manager.py" ]
}

# STEP 1: Ensure directory exists
echo "🔧 Step 1: Preparing update directory..."
mkdir -p "$UPDATE_DIR"
cd "$UPDATE_DIR" || exit 1

# STEP 2: Check internet
echo "🌐 Step 2: Checking internet connection..."
if ! ping -c 1 github.com >/dev/null 2>&1; then
    echo "❌ No internet connection! Please connect and try again."
    read -p "Press Enter to exit..."
    exit 1
fi
echo "✅ Internet OK"

# STEP 3: Try git first, fallback to direct download
echo "📦 Step 3: Getting latest files..."

GIT_OK=0
if command -v git >/dev/null 2>&1; then
    # Test if existing repo works
    if [ -d ".git" ]; then
        git status >/dev/null 2>&1 && GIT_OK=1
    fi
    
    if [ $GIT_OK -eq 0 ]; then
        echo "   Cleaning old repo..."
        rm -rf .git ./* ./.* 2>/dev/null
        echo "   Cloning fresh repo..."
        if git clone --depth 1 "$REPO_URL" . 2>/dev/null; then
            GIT_OK=1
            echo "✅ Git clone successful"
        fi
    else
        echo "   Updating existing repo..."
        git pull origin main 2>/dev/null || git reset --hard origin/main 2>/dev/null
        echo "✅ Git update successful"
    fi
fi

# If git failed, use direct download
if [ $GIT_OK -eq 0 ]; then
    echo "   Using direct download method..."
    rm -rf ./* 2>/dev/null
    
    if download_launcher_direct && download_manager_direct; then
        echo "✅ Direct download successful"
    else
        echo "❌ Failed to download files!"
        echo ""
        echo "Please try:"
        echo "1. Check your internet connection"
        echo "2. Open terminal and run:"
        echo "   rm -rf ~/ethereal-update"
        echo "   Then click Update again"
        read -p "Press Enter to exit..."
        exit 1
    fi
fi

# STEP 4: Verify files exist
echo "🔍 Step 4: Verifying installation..."
if [ ! -f "Ethereal-Update-Manager.py" ]; then
    echo "❌ Update Manager missing! Auto-fixing..."
    download_manager_direct
fi

if [ ! -f "Ethereal-Update-Launcher.sh" ]; then
    echo "❌ Launcher missing! Auto-fixing..."
    download_launcher_direct
fi

# STEP 5: Make files executable
echo "⚙️ Step 5: Setting permissions..."
chmod +x *.sh 2>/dev/null
chmod +x *.py 2>/dev/null

# STEP 6: Launch Update Manager
echo ""
echo "🚀 Launching Ethereal Update Manager..."
echo "======================================="
echo ""

if [ -f "Ethereal-Update-Launcher.sh" ]; then
    exec bash Ethereal-Update-Launcher.sh
elif [ -f "Ethereal-Update-Manager.py" ]; then
    exec python3 Ethereal-Update-Manager.py
else
    echo "❌ CRITICAL ERROR: Cannot find Update Manager!"
    echo "Please report this issue."
    read -p "Press Enter to exit..."
    exit 1
fi
