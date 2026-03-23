#!/bin/bash
# ==========================================================
# EtherealOS - Update Notifier v1.0.0
# Background service to check for new GitHub releases.
# ==========================================================

REPO_URL="https://github.com/abdallah2008xx-jpg/EtherealOS-Core"

echo "📡 Ethereal Notifier checking for updates..."

# Get current folder of the script to compare with the local git
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

if [ ! -d ".git" ]; then
    echo "Notifier not running in a git repo! Skipping."
    exit 1
fi

# Fetch from github silently
git fetch origin main > /dev/null 2>&1

# Check if we are behind main branch
NEW_COMMITS=$(git rev-list HEAD..origin/main --count)

if [ "$NEW_COMMITS" -gt 0 ]; then
    echo "⚠️ $NEW_COMMITS New Updates Found!"
    
    # Send a system notification using Zenity (native to Linux/Cinnamon)
    zenity --info --title="🪐 EtherealOS Update Available!" \
           --text="Your system has discovered $NEW_COMMITS new extraterrestrial updates on GitHub.\n\nRun 'Ethereal Update' from your desktop to apply them now." \
           --width=400 2>/dev/null &
fi
