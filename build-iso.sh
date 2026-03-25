#!/bin/bash
# ==========================================================
# EtherealOS - Live ISO Architect v1.2
# Fixes for mformat, lzma, and dracut dependencies
# ==========================================================

echo "🪐 EtherealOS ISO Manufacturer Started..."

echo "📦 [1/6] Installing ISO dependencies (SquashFS, GRUB Rescue, Mtools, LVM2)..."
emerge --autounmask-write --autounmask-continue -q sys-fs/squashfs-tools dev-libs/libisoburn sys-boot/grub sys-kernel/dracut sys-fs/mtools sys-fs/lvm2 sys-boot/syslinux

echo "🧠 [2/6] Generating Live Boot Environment (Initramfs)..."
# Force completely generic initramfs without host-only strict checks, and explicitly load squashfs and loop
dracut -N --force --nofscks --nomdadm --add-drivers "squashfs loop" --omit "nfs" --install "busybox" /boot/initramfs-live.img

echo "🏗️ [3/6] Preparing ISO Blueprint..."
rm -rf /tmp/ethereal-iso
mkdir -p /tmp/ethereal-iso/boot/grub
mkdir -p /tmp/ethereal-iso/LiveOS
cp -v /boot/vmlinuz* /tmp/ethereal-iso/boot/vmlinuz
cp -v /boot/initramfs-live.img /tmp/ethereal-iso/boot/initrd.img 2>/dev/null || touch /tmp/ethereal-iso/boot/initrd.img

echo "📜 [4/6] Writing GRUB Bootloader config..."
cat << 'EOF' > /tmp/ethereal-iso/boot/grub/grub.cfg
set timeout=10
set default=0
menuentry "Boot EtherealOS (Live Mode)" {
    linux /boot/vmlinuz root=live:CDLABEL=ETHEREALOS rd.live.image quiet splash
    initrd /boot/initrd.img
}
EOF

echo "🗜️ [5/6] Compressing System (SquashFS - Direct to Host Folder to save VM Disk Space)..."
# Limit to 2 processors and 1GB RAM to prevent "gzip uncompress failed -3" (Out of Memory crash)
# Writing directly to /tmp/ethereal-iso to avoid space limits
mksquashfs / /tmp/ethereal-iso/LiveOS/squashfs.img -comp gzip -b 256K -processors 2 -mem 1G -e /proc /sys /dev /mnt /tmp /var/tmp /media /run /home/abdallah/.cache /var/cache /usr/portage /usr/src

echo "💿 [6/6] Minting Final ISO..."
grub-mkrescue -o /media/sf_gentoo-files/EtherealOS-v1.2.0-Core.iso /tmp/ethereal-iso -- -volid ETHEREALOS

echo "✅ ISO Construction Complete! Find EtherealOS-v1.2.0-Core.iso in your Shared Folder."

