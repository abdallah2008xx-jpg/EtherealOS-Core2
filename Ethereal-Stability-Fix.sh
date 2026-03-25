#!/bin/bash
# ==========================================================
# EtherealOS - System Stability Engine v1.0
# Prevents RAM-related freezes using Nohang (OOM Daemon).
# ==========================================================

echo "🚨 Configuring System Stability (OOM Protection)..."

# 1. Install Nohang
# We use the 'app-admin/nohang' package for Gentoo
if ! command -v nohang >/dev/null 2>&1; then
    sudo emerge --ask=n --quiet app-admin/nohang 2>/dev/null || true
fi

# 2. Configure Nohang for notifications
# We enable high-verbosity and notifications to the user
CONFIG_FILE="/etc/nohang/nohang.conf"
if [ -f "$CONFIG_FILE" ]; then
    sudo sed -i 's/show_notifications = False/show_notifications = True/g' "$CONFIG_FILE" 2>/dev/null
    sudo sed -i 's/notification_timeout = 5000/notification_timeout = 10000/g' "$CONFIG_FILE" 2>/dev/null
fi

# 3. Enable and start the Nohang service (OpenRC)
if command -v nohang >/dev/null 2>&1; then
    sudo rc-update add nohang default 2>/dev/null || true
    sudo rc-service nohang start 2>/dev/null || true
    echo "✅ Nohang stability daemon is active and configured."
else
    echo "❌ Nohang installation failed. Check internet/portage."
fi

echo "✨ Stability Fix Complete!"
