#!/bin/bash
# ==========================================================
# EtherealOS OTA Global Updater v1.1.0
# Optimized for Seamless GitHub Synchronization
# ==========================================================

REPO_URL="https://github.com/abdallah2008xx-jpg/EtherealOS-Core"

echo "📡 Contacting Ethereal Update Servers..."

# Check if running inside a Git directory, if not, download the fresh repo
if [ ! -d ".git" ]; then
    echo "⬇️ Downloading Ethereal Core Bundle..."
    git clone $REPO_URL.git /tmp/ethereal-update
    cd /tmp/ethereal-update
else
    echo "🔄 Checking for new system patches..."
    git fetch origin main
    
    # Check if local is behind remote
    UPSTREAM=${1:-'@{u}'}
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse "$UPSTREAM")
    
    if [ $LOCAL = $REMOTE ]; then
        echo "✅ Your EtherealOS is already up to date!"
        exit 0
    else
        echo "⚠️ New extraterrestrial update detected! Applying..."
        git pull origin main
    fi
fi

# Apply the actual visual/system updates
echo "⚙️ Re-compiling system visuals..."
bash Ethereal-Final-Polish.sh
bash apply-theme.sh

echo "✨ EtherealOS is now powered by the latest core! (v1.1.0)"
