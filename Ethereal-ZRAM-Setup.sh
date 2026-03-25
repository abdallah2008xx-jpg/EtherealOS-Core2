#!/bin/bash
# ==========================================================
# EtherealOS - ZRAM Performance Engine v1.0
# "Compressed Speed" - RAM-based Swap Protection
# ==========================================================

echo "⚡ Initializing ZRAM Engine..."

# 1. Install ZRAM-init for OpenRC
echo "📦 Installing ZRAM utilities..."
emerge --ask=n --quiet sys-apps/zram-init 2>/dev/null || true

# 2. Configure ZRAM (50% of RAM, zstd compression)
echo "⚙️ Configuring ZRAM parameters..."
cat << 'EOF' > /etc/conf.d/zram-init
# Use zstd for best compression/speed ratio
load_modules="yes"
num_devices=1

# DEVICE 0: SWAP
type0="swap"
flag0=""
# Size is 50% of total RAM
size0="50%"
# Compression algorithm
comp0="zstd"
EOF

# 3. Enable the service
echo "🔓 Activating ZRAM Service..."
rc-update add zram-init boot
rc-service zram-init start

# 4. Verification
echo "📊 Verifying ZRAM Status..."
zramctl

echo "✅ ZRAM Engine is active. Enjoy the speed boost!"
