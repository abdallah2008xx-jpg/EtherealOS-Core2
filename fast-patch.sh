#!/bin/bash
# ==========================================================
# EtherealOS - Super Fast ISO Patcher v5
# Fixes the Switch_Root freeze by adding missing directories
# ==========================================================
set -e

echo "🚀 Starting Lightning Fast ISO Patcher (Takes ~30 seconds)..."

ISO_IN="/media/sf_gentoo-files/EtherealOS-v3.0-Final.iso"
ISO_OUT="/media/sf_gentoo-files/EtherealOS-v5.0-Fixed.iso"
PATCH_DIR="/tmp/fast-patch"

# 1. Clean up old patch dir
rm -rf "$PATCH_DIR"
mkdir -p "$PATCH_DIR"
mkdir -p /mnt/iso

# 2. Add Dracut Hook to create missing directories before switch_root
echo "🛠️  Creating Dracut hook to fix missing /dev /sys /proc in squashfs..."
mkdir -p /tmp/dracut-hooks
cat << 'EOF' > /tmp/dracut-hooks/99-fix-sysroot.sh
#!/bin/sh
echo "--- ETHEREAL DRACUT HOOK: Creating essential directories in new root ---"
# System directories
mkdir -p "$NEWROOT/dev" "$NEWROOT/proc" "$NEWROOT/sys" "$NEWROOT/run" "$NEWROOT/mnt" "$NEWROOT/tmp" "$NEWROOT/var/tmp" "$NEWROOT/media"
chmod 1777 "$NEWROOT/tmp" "$NEWROOT/var/tmp"

# Application caches (Crucial for Cinnamon Desktop to not crash!)
mkdir -p "$NEWROOT/var/cache" "$NEWROOT/usr/src"

if [ -d "$NEWROOT/home/abdallah" ]; then
    echo "--- 🦊 FIXING FIREFOX AND HOME PERMISSIONS ---"
    # Purge the corrupted root firefox profiles completely
    rm -rf "$NEWROOT/home/abdallah/.mozilla" "$NEWROOT/home/abdallah/.cache"
    mkdir -p "$NEWROOT/home/abdallah/.cache"
    
    # Recursively take back ownership of the ENTIRE home folder!
    chroot "$NEWROOT" chown -R abdallah:abdallah /home/abdallah 2>/dev/null || chroot "$NEWROOT" chown -R 1000:1000 /home/abdallah 2>/dev/null
fi
echo "--- Fix Complete ---"
EOF
chmod +x /tmp/dracut-hooks/99-fix-sysroot.sh

# 3. Generate new initramfs with the new hook
echo "🧠 Rebuilding Live Initramfs..."
dracut -N --force --nofscks --nomdadm --add 'dmsquash-live' --add-drivers 'squashfs loop overlay' --omit 'nfs' --include /tmp/dracut-hooks/99-fix-sysroot.sh /lib/dracut/hooks/pre-pivot/99-fix-sysroot.sh /tmp/new-initrd.img

# 4. Mount original ISO
echo "💿 Extracting Original ISO..."
mount -o loop "$ISO_IN" /mnt/iso
cp -r /mnt/iso/* "$PATCH_DIR/"
umount /mnt/iso

# 5. Inject new Initramfs
echo "💉 Injecting fixed initramfs..."
cp /tmp/new-initrd.img "$PATCH_DIR/boot/initrd.img"

# 6. Fix GRUB (Ensure console output, clear init, etc.)
echo "🔧 Patching Bootloader for Maximum Visibility..."
cat << 'GRUBCFG' > "$PATCH_DIR/boot/grub/grub.cfg"
set timeout=5
set default=1

menuentry "🪐 EtherealOS - Start Desktop (Fast Boot)" {
    linux /boot/vmlinuz root=live:CDLABEL=ETHEREALOS rd.live.image rd.live.overlay.overlayfs init=/sbin/init mitigations=off
    initrd /boot/initrd.img
}

menuentry "🛠️ EtherealOS - Verbose Debug Mode (RECOMMENDED)" {
    linux /boot/vmlinuz root=live:CDLABEL=ETHEREALOS rd.live.image rd.live.overlay.overlayfs init=/sbin/init rd.debug console=tty1 
    initrd /boot/initrd.img
}

menuentry "🚨 EtherealOS - Emergency Shell (bash)" {
    linux /boot/vmlinuz root=live:CDLABEL=ETHEREALOS rd.live.image rd.live.overlay.overlayfs init=/bin/sh console=tty1
    initrd /boot/initrd.img
}
GRUBCFG

# 7. Burn new ISO
echo "🔥 Burning new insanely fast ISO..."
grub-mkrescue -o "$ISO_OUT" "$PATCH_DIR" -- -volid ETHEREALOS

# 8. Cleanup
rm -rf "$PATCH_DIR"
rm -f /tmp/new-initrd.img /tmp/dracut-hooks/99-fix-sysroot.sh

echo "✅ DONE! EtherealOS-v5.0-Fixed.iso is ready in your shared folder!"
echo "Boot into 'Verbose Debug Mode' to see what happens after dracut!"
