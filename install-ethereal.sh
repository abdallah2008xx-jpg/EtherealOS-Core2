#!/bin/bash
# ==========================================================
# EtherealOS - Ultimate Installer
# Use this to install Ethereal Core to any Gentoo system.
# ==========================================================

echo "🪐 Welcome to EtherealOS Deployment."

# 1. Directories
mkdir -p ~/.config/autostart
mkdir -p ~/.local/bin
mkdir -p ~/.local/share/icons/ethereal

# Download and install modern icons from internet
echo "⬇️ Downloading Modern Icon Theme from Internet..."
bash download-modern-icons.sh 2>/dev/null || echo "⚠️ Icon download skipped (offline)"

# Install custom Ethereal icons as fallback
echo "🎨 Installing Custom App Icons..."
cp icons/*.svg ~/.local/share/icons/ethereal/ 2>/dev/null

# Enable Background Updater 
cp Ethereal-Notifier-Autostart.desktop ~/.config/autostart/Ethereal-Notifier.desktop 2>/dev/null

# 2. Applying Core System Settings
echo "🎨 Applying Ethereal Architecture UI..."
bash apply-theme.sh

# 3. Deploying Shortcuts
echo "🚀 Deploying Desktop Suite..."
cp *.desktop ~/Desktop/ 2>/dev/null
chmod +x ~/Desktop/*.desktop 2>/dev/null

# Mark desktop files as trusted (Cinnamon/Nemo requirement)
echo "🔐 Marking launchers as trusted..."
for file in ~/Desktop/*.desktop; do
    [ -f "$file" ] && gio set "$file" metadata::trusted true 2>/dev/null || true
done

# 4. Final Polish
echo "✨ Finishing touches (Icons & Cursors)..."
bash Ethereal-Final-Polish.sh

echo "✅ Deployment Successful! Welcome home."
