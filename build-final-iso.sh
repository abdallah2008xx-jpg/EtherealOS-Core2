#!/bin/bash
# ==========================================================
# EtherealOS - DEFINITIVE Bootable ISO Builder v3.1
# FIX: All temp files written to SHARED FOLDER (host disk)
# ==========================================================
set -e

WORK="/media/sf_gentoo-files/iso-workspace"

echo "🪐 ============================================="
echo "   EtherealOS Definitive ISO Manufacturer v3.1"
echo "   Writing to HOST disk (unlimited space)"
echo "============================================="

# -----------------------------------------------------------
# STEP 1: Clean old workspace + create new one on HOST disk
# -----------------------------------------------------------
echo ""
echo "🧹 [1/9] Preparing workspace on HOST disk..."
rm -rf "$WORK"
mkdir -p "$WORK/boot/grub"
mkdir -p "$WORK/LiveOS"
echo "   ✅ Workspace ready at $WORK"

# -----------------------------------------------------------
# STEP 2: Create Dracut config directory
# -----------------------------------------------------------
echo ""
echo "📁 [2/9] Creating Dracut configuration..."
mkdir -p /etc/dracut.conf.d
echo "   ✅ Done"

# -----------------------------------------------------------
# STEP 3: Build Initramfs with dmsquash-live
# -----------------------------------------------------------
echo ""
echo "🧠 [3/9] Generating Live Boot Initramfs..."

# Create the pre-pivot hook to guarantee folder structure exists before root pivot
echo "   -> Injecting EtherealOS Pre-Pivot Safety Hook..."
mkdir -p /etc/dracut.conf.d
mkdir -p /tmp/ethereal-hooks
cat << 'EOF' > /tmp/ethereal-hooks/99-fix-sysroot.sh
#!/bin/sh
echo "--- ETHEREAL DRACUT HOOK: Creating essential directories in new root ---"
mkdir -p "$NEWROOT/dev" "$NEWROOT/proc" "$NEWROOT/sys" "$NEWROOT/run" "$NEWROOT/mnt" "$NEWROOT/tmp" "$NEWROOT/var/tmp" "$NEWROOT/media"
chmod 1777 "$NEWROOT/tmp" "$NEWROOT/var/tmp"

mkdir -p "$NEWROOT/var/cache" "$NEWROOT/usr/src"

if [ -d "$NEWROOT/home/abdallah" ]; then
    echo "--- 🦊 FIXING FIREFOX AND HOME PERMISSIONS ---"
    rm -rf "$NEWROOT/home/abdallah/.mozilla" "$NEWROOT/home/abdallah/.cache"
    mkdir -p "$NEWROOT/home/abdallah/.cache"
    chroot "$NEWROOT" chown -R abdallah:abdallah /home/abdallah 2>/dev/null || chroot "$NEWROOT" chown -R 1000:1000 /home/abdallah 2>/dev/null
fi
echo "--- Fix Complete ---"
EOF
chmod +x /tmp/ethereal-hooks/99-fix-sysroot.sh

dracut -N --force --nofscks --nomdadm --add 'dmsquash-live' --add-drivers 'squashfs loop overlay' --omit 'nfs' --include /tmp/ethereal-hooks/99-fix-sysroot.sh /lib/dracut/hooks/pre-pivot/99-fix-sysroot.sh /boot/initramfs-live.img

echo "   ✅ Initramfs created with Pre-Pivot Safety features!"

# -----------------------------------------------------------
# STEP 4: Apply LiveCD-safe configurations
# -----------------------------------------------------------
echo ""
echo "🔧 [4/9] Applying LiveCD-safe configurations..."

# Backup original fstab
cp /etc/fstab /etc/fstab.original.bak 2>/dev/null || true

# Empty fstab (prevents hanging on non-existent disks)
echo "# EtherealOS Live - No disk mounts needed" > /etc/fstab

# Configure LightDM auto-login
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/50-autologin.conf << 'AUTOLOGIN'
[Seat:*]
autologin-user=abdallah
autologin-session=cinnamon
user-session=cinnamon
AUTOLOGIN

# --- SYSTEM O.T.A UPDATER (Bypasses all shared folders) ---
echo "   -> Baking Flawless OTA Updater onto the Desktop..."
mkdir -p /home/abdallah/Desktop

cat << 'DLINK' > /home/abdallah/Desktop/Update_Ethereal.desktop
[Desktop Entry]
Type=Application
Name=🪐 Update EtherealOS
Comment=Fetch and apply latest system updates from GitHub
Exec=bash -c "rm -rf ~/ethereal-update 2>/dev/null; git clone https://github.com/abdallah2008xx-jpg/EtherealOS-Core.git ~/ethereal-update && cd ~/ethereal-update && bash Ethereal-Update.sh"
Icon=system-software-update
Terminal=false
Categories=System;Settings;
DLINK

echo "   -> Injecting Permanent Autostart Notifier..."
mkdir -p /opt/EtherealOS-Core
# Fetch the absolute latest repo natively from GitHub so git fetch always works when booted standalone!
git clone https://github.com/abdallah2008xx-jpg/EtherealOS-Core.git /opt/EtherealOS-Core 2>/dev/null || true

mkdir -p /home/abdallah/.config/autostart
cat << 'AUTO' > /home/abdallah/.config/autostart/Ethereal-Notifier-Autostart.desktop
[Desktop Entry]
Type=Application
Exec=bash -c "sleep 15 && bash /opt/EtherealOS-Core/Ethereal-Notifier.sh"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=EtherealOS Updater
Comment=OTA Update Notifier
AUTO

chmod +x /home/abdallah/Desktop/Update_Ethereal.desktop
chown -R abdallah:abdallah /home/abdallah/Desktop /home/abdallah/.config 2>/dev/null || true
# ----------------------------------------------------------


# Disable services that hang on LiveCD
for svc in fsck swap localmount netmount; do
  rc-update del $svc boot 2>/dev/null || true
  rc-update del $svc default 2>/dev/null || true
done

# Ensure LightDM is enabled
rc-update add lightdm default 2>/dev/null || true

echo "   ✅ All LiveCD configs applied"

# -----------------------------------------------------------
# STEP 5: Build SquashFS DIRECTLY on host disk
# -----------------------------------------------------------
echo ""
echo "🗜️ [5/9] Compressing system (writing to HOST disk - NO space issues!)..."
echo "   This takes 10-15 minutes. DO NOT close the terminal!"

mksquashfs / "$WORK/LiveOS/squashfs.img" \
  -comp gzip -b 256K -processors 2 -mem 512M \
  -e /proc /sys /dev /mnt /tmp /var/tmp /media /run \
     /home/abdallah/.cache /var/cache /usr/src

echo "   ✅ SquashFS compression complete!"
ls -lh "$WORK/LiveOS/squashfs.img"

# -----------------------------------------------------------
# STEP 6: Restore original system files
# -----------------------------------------------------------
echo ""
echo "🔄 [6/9] Restoring original system configuration..."
cp /etc/fstab.original.bak /etc/fstab 2>/dev/null || true
for svc in fsck swap localmount; do
  rc-update add $svc boot 2>/dev/null || true
done
echo "   ✅ Original system restored"

# -----------------------------------------------------------
# STEP 7: Copy Kernel + Initramfs
# -----------------------------------------------------------
echo ""
echo "🐧 [7/9] Copying Kernel and Initramfs..."

# Mount /boot just in case it's a separate unmounted partition
mount /boot 2>/dev/null || true

KERNEL_FOUND=false
for k in /boot/vmlinuz* /boot/kernel-* /boot/bzImage*; do
    if [ -f "$k" ]; then
        echo "   -> Found kernel natively: $k"
        cp -v "$k" "$WORK/boot/vmlinuz"
        KERNEL_FOUND=true
        break
    fi
done

# If not found natively, extract it smartly from the previous ISO!
if [ "$KERNEL_FOUND" = false ]; then
    echo "   -> Kernel not found in /boot! Extracting from previous EtherealOS ISO..."
    OLD_ISO="/media/sf_gentoo-files/EtherealOS-v3.0-Final.iso"
    if [ -f "$OLD_ISO" ]; then
        mkdir -p /tmp/old_iso_mount
        mount -o loop "$OLD_ISO" /tmp/old_iso_mount 2>/dev/null || true
        if [ -f "/tmp/old_iso_mount/boot/vmlinuz" ]; then
            cp -v "/tmp/old_iso_mount/boot/vmlinuz" "$WORK/boot/vmlinuz"
            KERNEL_FOUND=true
        fi
        umount /tmp/old_iso_mount 2>/dev/null || true
    fi
fi

if [ "$KERNEL_FOUND" = false ]; then
    echo "❌ ERROR: No kernel found anywhere! Ensure you have an OS kernel to pack."
    exit 1
fi

cp -v /boot/initramfs-live.img "$WORK/boot/initrd.img"
echo "   ✅ Kernel ready"

# -----------------------------------------------------------
# STEP 8: Write GRUB Config
# -----------------------------------------------------------
echo ""
echo "📜 [8/9] Writing GRUB bootloader config..."

cat << 'GRUBCFG' > "$WORK/boot/grub/grub.cfg"
set timeout=5
set default=0

menuentry "EtherealOS - Start Desktop" {
    linux /boot/vmlinuz root=live:CDLABEL=ETHEREALOS rd.live.image rd.live.overlay.overlayfs nomodeset
    initrd /boot/initrd.img
}

menuentry "EtherealOS - Safe Mode" {
    linux /boot/vmlinuz root=live:CDLABEL=ETHEREALOS rd.live.image rd.live.overlay.overlayfs nomodeset rd.debug
    initrd /boot/initrd.img
}
GRUBCFG

echo "   ✅ GRUB configured"

# -----------------------------------------------------------
# STEP 9: Mint Final ISO
# -----------------------------------------------------------
echo ""
echo "💿 [9/9] Building Final Bootable ISO..."
grub-mkrescue -o /media/sf_gentoo-files/EtherealOS-v3.0-Final.iso "$WORK" -- -volid ETHEREALOS

echo ""
echo "🏆 ============================================="
echo "   EtherealOS v3.0 ISO BUILD COMPLETE!"
ls -lh /media/sf_gentoo-files/EtherealOS-v3.0-Final.iso
echo "============================================="

# Cleanup workspace
rm -rf "$WORK"
echo "   ✅ Workspace cleaned up"
