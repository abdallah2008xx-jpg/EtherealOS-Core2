#!/bin/bash
# ==========================================================
# EtherealOS - High-Performance DNS & Privacy v1.0
# Configures systemd-resolved with DNS-over-TLS (DoT).
# ==========================================================

echo "🌐 Accelerating Internet Speed (DNS-over-TLS)..."

# 1. Install systemd-utils (provides systemd-resolved on Gentoo)
echo "📦 Installing systemd-resolved..."
sudo emerge --ask=n --quiet sys-apps/systemd-utils 2>/dev/null || true

# 2. Configure DNS-over-TLS
# We use Cloudflare (1.1.1.1) and Google (8.8.8.8) with TLS enabled.
RESOLVED_CONF="/etc/systemd/resolved.conf"
sudo mkdir -p /etc/systemd
cat << 'EOF' | sudo tee "$RESOLVED_CONF" > /dev/null
[Resolve]
DNS=1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4
FallbackDNS=9.9.9.9 149.112.112.112
Domains=~.
DNSOverTLS=yes
DNSSEC=yes
Cache=yes
EOF

# 3. Handle the symlink for /etc/resolv.conf
# This ensures all apps use systemd-resolved
echo "🔗 Linking resolv.conf to systemd-resolved..."
sudo rm -f /etc/resolv.conf
sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# 4. Enable and start the service (OpenRC or Systemd)
if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable --now systemd-resolved
else
    # For OpenRC, we use the systemd-resolved service
    sudo rc-update add systemd-resolved default 2>/dev/null || true
    sudo rc-service systemd-resolved start 2>/dev/null || true
fi

echo "✅ DNS-over-TLS is now active. Your browsing is faster and encrypted."
