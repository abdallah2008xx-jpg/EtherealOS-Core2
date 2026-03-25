#!/bin/bash
# ==========================================================
# EtherealOS - Storage Optimization Engine v1.0
# Maximizes disk space using Btrfs Zstd Compression.
# ==========================================================

echo "🗜️ Optimizing File System Storage..."

# 1. Ensure Btrfs Progs is installed (should be already, but just in case)
if ! command -v btrfs >/dev/null 2>&1; then
    sudo emerge --ask=n --quiet sys-fs/btrfs-progs 2>/dev/null || true
fi

# 2. Check if the root is Btrfs and has compression enabled
if mount | grep " / " | grep -q "btrfs"; then
    echo "   → Btrfs detected. Applying recursive compression..."
    
    # We defragment with zstd compression to compress existing files
    # This might take a bit of time, so we run it in the background or just on critical paths
    # For now, let's do a targeted defrag on /usr and /var where most data lives
    sudo btrfs filesystem defragment -r -v -czstd /usr 2>/dev/null
    sudo btrfs filesystem defragment -r -v -czstd /var 2>/dev/null
    
    echo "✅ Storage optimization applied to system directories."
else
    echo "⚠️  Root filesystem is not Btrfs or not mounted. Skipping compression."
fi

# 3. Verify mount options in fstab for future writes
if grep -q "compress=zstd" /etc/fstab; then
    echo "   → Zstd compression is already active in fstab. Good."
else
    echo "   → Enabling Zstd compression in fstab for future writes..."
    sudo sed -i 's/ btrfs / btrfs compress=zstd, /g' /etc/fstab 2>/dev/null
fi

echo "✨ Storage Optimization Complete!"
