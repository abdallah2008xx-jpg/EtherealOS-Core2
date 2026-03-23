#!/bin/bash
# ==========================================================
# EtherealOS - Ultimate Installer
# Use this to install Ethereal Core to any Gentoo system.
# ==========================================================

echo "🪐 Welcome to EtherealOS Deployment."

# 1. Directories
mkdir -p ~/.config/autostart
mkdir -p ~/.local/bin

# 2. Applying Core System Settings
echo "🎨 Applying Ethereal Architecture UI..."
bash apply-theme.sh

# 3. Deploying Shortcuts
echo "🚀 Deploying Desktop Suite..."
cp *.desktop ~/Desktop/ 2>/dev/null
chmod +x ~/Desktop/*.desktop 2>/dev/null

# 4. Final Polish
echo "✨ Finishing touches (Icons & Cursors)..."
bash Ethereal-Final-Polish.sh

echo "✅ Deployment Successful! Welcome home."
