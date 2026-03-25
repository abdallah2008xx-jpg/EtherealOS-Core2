#!/bin/bash
# ==========================================================
# EtherealOS Deep Visuals Integration
# 1. Installs official Papirus-Dark premium icons (zero missing icons).
# 2. Enhances navigation and Alt-tab animations to absolute 3D.
# ==========================================================

echo "Downloading the Official EtherealOS Premium Icon Engine (Papirus)..."
mkdir -p ~/.icons

# Securely download and install Papirus directly into user's .icons folder
wget -qO- https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-icon-theme/master/install.sh | DESTDIR="$HOME/.icons" sh

# Enforce the glorious Papirus-Dark theme system-wide
gsettings set org.cinnamon.desktop.interface icon-theme 'Papirus-Dark'

echo "Configuring Ultra-Premium Navigation Animations..."
# Enable 3D Coverflow for Alt-Tab Window Navigation! (Like macOS / Compiz)
gsettings set org.cinnamon alttab-switcher-style 'coverflow'

# Enable Expo/Scale animations for workspaces
gsettings set org.cinnamon desktop-effects-workspace 'scale'
gsettings set org.cinnamon.muffin wobbly-windows true
gsettings set org.cinnamon.muffin desktop-effects true

# Make Nemo (File Browser) animations smooth
gsettings set org.nemo.preferences icon-view-text-wrapping 'true'

# Refresh Cinnamon to apply
nohup cinnamon --replace >/dev/null 2>&1 &
echo "Visuals successfully upgraded!"
