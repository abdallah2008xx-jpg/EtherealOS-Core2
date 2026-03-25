#!/bin/bash
# ==========================================================
# EtherealOS - Fast ISO Repacker (Fixes BOOT_LIVE missing)
# ==========================================================

echo "🩹 EtherealOS Fast Repacker Started (Skipping 15 min compression)..."

echo "📦 [1/4] Installing BusyBox (Critical for Dracut LiveCD Rescue)..."
emerge -q sys-apps/busybox

echo "🧠 [2/4] Regenerating Live Boot Environment (Adding dmsquash-live)..."
# The secret sauce: dracut MUST have dmsquash-live to understand root=live:CDLABEL
dracut -N --force --nofscks --nomdadm --add 'dmsquash-live' --add-drivers "squashfs loop" --omit "nfs" /boot/initramfs-live.img

echo "🏗️ [3/4] Updating ISO Blueprint..."
# Just replace the initramfs, keep the existing 4GB squashfs
cp -v /boot/initramfs-live.img /tmp/ethereal-iso/boot/initrd.img

echo "💿 [4/4] Minting Final Bootable ISO..."
grub-mkrescue -o /media/sf_gentoo-files/EtherealOS-Final-Bootable.iso /tmp/ethereal-iso -- -volid ETHEREALOS

echo "✅ Bootable ISO Construction Complete! Find EtherealOS-Final-Bootable.iso in your Shared Folder."
