#!/bin/bash
# ==========================================================
# EtherealOS - Security Setup Engine v1.0
# Simplifies firewall protection via GUFW/UFW.
# ==========================================================

echo "🛡️ Configuring System Security (Firewall)..."

# 1. Install UFW and GUFW
# GUFW is the graphical frontend for UFW
if ! command -v ufw >/dev/null 2>&1; then
    sudo emerge --ask=n --quiet net-firewall/ufw net-firewall/gufw 2>/dev/null || true
fi

# 2. Configure UFW Default Rules
if command -v ufw >/dev/null 2>&1; then
    echo "   → Setting up 'Deny Incoming' default policy..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # 3. Enable UFW
    # This might require a restart to fully apply the kernel module, but we enable the service now.
    sudo ufw --force enable 2>/dev/null
    
    # 4. Enable and start the UFW service (OpenRC)
    sudo rc-update add ufw default 2>/dev/null || true
    sudo rc-service ufw start 2>/dev/null || true
    echo "✅ Firewall is now active and protecting your system."
else
    echo "❌ Firewall installation failed. Check internet/portage."
fi

echo "✨ Security Setup Complete!"
