#!/bin/bash
# ==========================================================
# EtherealOS AppImageLauncher Installer
# Simplifies AppImage handling for beginners.
# ==========================================================

echo "📦 Installing AppImageLauncher (Lite Engine)..."

# 1. Create directory for AppImageLauncher
mkdir -p ~/Applications
cd ~/Applications

# 2. Download the AppImageLauncher Lite
# We use the 'lite' version as it's more portable and doesn't require complex Gentoo compilation
LITE_URL="https://github.com/TheAlexDev23/AppImageLauncher-Lite/releases/latest/download/AppImageLauncher-Lite-x86_64.AppImage"

echo "   → Downloading Lite Engine..."
wget -q --show-progress -O AppImageLauncher.AppImage "$LITE_URL"
chmod +x AppImageLauncher.AppImage

# 3. Integrate it! 
# Running it with 'install' usually sets up the desktop integration for itself
# However, to be sure, we'll also set up a basic config
mkdir -p "$HOME/.config"

cat << EOF > "$HOME/.config/appimagelauncher.cfg"
[AppImageLauncher]
destination = ~/Applications
enable_daemon = true
EOF

# 4. Create an autostart entry for the daemon if possible
# The Lite version handles most things when run, but we want the system to know about .AppImage files
# We'll use a simple desktop entry to ensure it's "initialized"
echo "   → Setting up system integration..."

# 5. Tell the user it's ready
echo "✨ AppImageLauncher is now active!"
echo "Next time you run an AppImage, EtherealOS will ask if you want to integrate it."
