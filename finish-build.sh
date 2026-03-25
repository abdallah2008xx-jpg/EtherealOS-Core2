#!/bin/bash
# ==========================================================
# EtherealOS - Immortal ISO Builder v6.0
# Fixes Switch_Root freeze with proper dracut hooks
# ==========================================================
set -e
WORK="/media/sf_gentoo-files/iso-workspace"

echo "================================================="
echo "   🚀 BOMB-PROOF RECOVERY SYSTEM (VIRTUALBOX SAFE)"
echo "   Powered by Native Dracut Generation"
echo "================================================="

# Create necessary directories first!
mkdir -p "$WORK/boot"
rm -f "$WORK/boot/initrd.img" 2>/dev/null

echo "🐧 Extracting Flawless Kernel from Native Boot Environment..."
KERNEL_SRC=""
for k in /run/initramfs/live/boot/vmlinuz* /mnt/cdrom/boot/vmlinuz* /mnt/cdrom/boot/gentoo /run/initramfs/live/boot/gentoo /boot/vmlinuz* /boot/kernel-* /boot/bzImage*; do
    if [ -f "$k" ]; then
        KERNEL_SRC="$k"
        break
    fi
done

if [ -n "$KERNEL_SRC" ]; then
    echo "   -> Found kernel: $KERNEL_SRC"
    cp -v "$KERNEL_SRC" "$WORK/boot/vmlinuz"
else
    echo "❌ FATAL: Kernel couldn't be extracted! File not found."
    exit 1
fi

echo "🧠 Rebuilding Live Initramfs natively (Guaranteed Switch_Root Fix)..."
mkdir -p /tmp/dracut-hooks

cat << 'EOF' > /tmp/dracut-hooks/99-fix-sysroot.sh
#!/bin/sh
echo "--- ETHEREAL DRACUT HOOK: Creating essential directories in new root ---"

# Create ALL missing directories BEFORE switch_root
mkdir -p "$NEWROOT/dev" "$NEWROOT/proc" "$NEWROOT/sys" "$NEWROOT/run" "$NEWROOT/mnt" "$NEWROOT/tmp" "$NEWROOT/var/tmp" "$NEWROOT/media"
chmod 1777 "$NEWROOT/tmp" "$NEWROOT/var/tmp"
mkdir -p "$NEWROOT/var/cache" "$NEWROOT/usr/src" "$NEWROOT/root" "$NEWROOT/home"

# CRITICAL: Create essential device nodes
mknod -m 622 "$NEWROOT/dev/console" c 5 1 2>/dev/null || true
mknod -m 666 "$NEWROOT/dev/null" c 1 3 2>/dev/null || true
mknod -m 666 "$NEWROOT/dev/zero" c 1 5 2>/dev/null || true
mknod -m 666 "$NEWROOT/dev/random" c 1 8 2>/dev/null || true
mknod -m 666 "$NEWROOT/dev/urandom" c 1 9 2>/dev/null || true
mknod -m 666 "$NEWROOT/dev/tty" c 5 0 2>/dev/null || true

echo "--- 🔥 FIXING STARTUP CRASH AND HOME PERMISSIONS ---"
if [ -d "$NEWROOT/home/abdallah" ]; then
    # Clear ONLY cache (not .mozilla!) to prevent crash
    rm -rf "$NEWROOT/home/abdallah/.cache"
    mkdir -p "$NEWROOT/home/abdallah/.cache"
    
    # BUILD a working Firefox profile
    mkdir -p "$NEWROOT/home/abdallah/.mozilla/firefox/ethereal.default-release"
    cat > "$NEWROOT/home/abdallah/.mozilla/firefox/profiles.ini" << 'PROFILE'
[Install4F96D1932A9F858E]
Default=ethereal.default-release
Locked=1

[General]
StartWithLastProfile=1
Version=2

[Profile0]
Name=default-release
IsRelative=1
Path=ethereal.default-release
Default=1
PROFILE
    
    cat > "$NEWROOT/home/abdallah/.mozilla/firefox/installs.ini" << 'INSTALLS'
[4F96D1932A9F858E]
Default=ethereal.default-release
Locked=1
INSTALLS
    
    # Fix ALL permissions
    chroot "$NEWROOT" chown -R abdallah:abdallah /home/abdallah 2>/dev/null || chroot "$NEWROOT" chown -R 1000:1000 /home/abdallah 2>/dev/null
fi

echo "--- Hook Execution Complete ---"
EOF

chmod +x /tmp/dracut-hooks/99-fix-sysroot.sh

# Run dracut with the fix
dracut -N --force --nofscks --nomdadm \
  --add 'dmsquash-live' \
  --add-drivers 'squashfs loop overlay' \
  --omit 'nfs' \
  --include /tmp/dracut-hooks/99-fix-sysroot.sh /lib/dracut/hooks/pre-pivot/99-fix-sysroot.sh \
  "$WORK/boot/initrd.img"

if [ -f "$WORK/boot/initrd.img" ]; then
    echo "   ✅ Flawless Native Dracut Initramfs built successfully!"
else
    echo "❌ FATAL: Dracut failed to generate initramfs!"
    exit 1
fi

cd "$WORK"

echo "📜 Writing GRUB bootloader config..."
mkdir -p "$WORK/boot/grub"

cat << 'GRUBCFG' > "$WORK/boot/grub/grub.cfg"
set timeout=5
set default=0

menuentry "🪐 EtherealOS - Start Desktop (Fast Boot)" {
    linux /boot/vmlinuz root=live:CDLABEL=ETHEREALOS rd.live.image rd.live.overlay.overlayfs init=/sbin/init mitigations=off quiet
    initrd /boot/initrd.img
}

menuentry "🛠️ EtherealOS - Verbose Debug Mode (VBOX SAFE)" {
    linux /boot/vmlinuz root=live:CDLABEL=ETHEREALOS rd.live.image rd.live.overlay.overlayfs init=/sbin/init rd.debug console=tty1 nomodeset
    initrd /boot/initrd.img
}

menuentry "🚨 EtherealOS - Emergency Shell (bash)" {
    linux /boot/vmlinuz root=live:CDLABEL=ETHEREALOS rd.live.image rd.live.overlay.overlayfs init=/bin/sh console=tty1 nomodeset
    initrd /boot/initrd.img
}
GRUBCFG

echo "💿 MINTING THE FLAWLESS ISO..."
grub-mkrescue -o /media/sf_gentoo-files/EtherealOS-v6.0-Immortal.iso "$WORK" -- -volid ETHEREALOS -iso_level 3 -udf on -allow_limited_size

echo "🏆 =========================================="
echo "   ✅ ISO SUCCESS: EtherealOS-v6.0-Immortal.iso"
echo "============================================="
