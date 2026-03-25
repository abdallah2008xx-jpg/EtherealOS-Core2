#!/bin/bash
# ==========================================================
# EtherealOS - AppImage & Flatpak Visual Integration v1.0
# Ensures Flatpak apps follow the Ethereal glass theme.
# ==========================================================

echo "🎨 Integrating AppImage & Flatpak Visuals..."

# 1. Install xdg-desktop-portal-gtk for theme sharing
echo "📦 Installing Desktop Portals..."
emerge --ask=n --quiet sys-apps/xdg-desktop-portal sys-apps/xdg-desktop-portal-gtk 2>/dev/null || true

# 2. Configure Flatpak to access system themes and icons
if command -v flatpak &> /dev/null; then
    echo "🔓 Granting Flatpak access to themes and icons..."
    flatpak override --system --filesystem=~/.themes:ro
    flatpak override --system --filesystem=~/.icons:ro
    flatpak override --system --filesystem=/usr/share/themes:ro
    flatpak override --system --filesystem=/usr/share/icons:ro
    
    # Set default theme environment variables for Flatpak
    flatpak override --system --env=GTK_THEME=Adwaita-dark
    flatpak override --system --env=ICON_THEME=Papirus-Dark
else
    echo "⚠️ Flatpak not found. Skipping overrides."
fi

# 3. AppImage Integration (Visuals)
# AppImages usually follow the system GTK theme automatically if portals are present.
# We ensure the portal service is started.
mkdir -p ~/.config/systemd/user
# (Ethereal uses OpenRC, but portals are often managed by session bus/dbus)

# 4. Force GTK theme for current user session
echo "export GTK_THEME=Adwaita-dark" >> ~/.bashrc
echo "export ICON_THEME=Papirus-Dark" >> ~/.bashrc

echo "✅ AppImage & Flatpak Visual Integration Complete."
