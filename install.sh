#!/bin/bash
set -e
echo "========================================================="
echo " abdallahOS - Automatic Installation Script (Phase 3-8) "
echo "========================================================="

# PHASE 3
echo ">>> [Phase 3] Starting Networking (dhcpcd)..."
dhcpcd || true
sleep 3

echo ">>> [Phase 3] Partitioning Disk (/dev/sda)..."
# Using parted non-interactive
parted -s -a optimal /dev/sda \
  mklabel gpt \
  mkpart primary fat32 1MiB 513MiB \
  name 1 boot \
  set 1 efi on \
  mkpart primary ext4 513MiB 100% \
  name 2 root

echo ">>> [Phase 3] Formatting Partitions..."
mkfs.fat -F32 /dev/sda1
mkfs.ext4 -F /dev/sda2

echo ">>> [Phase 3] Mounting Partitions..."
mount /dev/sda2 /mnt/gentoo
mkdir -p /mnt/gentoo/boot
mount /dev/sda1 /mnt/gentoo/boot

echo ">>> [Phase 3] Extracting Stage3 (This will take a few minutes)..."
if [ ! -f /gentoo-files/stage3-amd64-desktop-openrc-20260316T093103Z.tar.xz ]; then
  echo "Error: Stage 3 not found in /gentoo-files!"
  exit 1
fi
tar xpf /gentoo-files/stage3-amd64-desktop-openrc-20260316T093103Z.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo

# PHASE 4
echo ">>> [Phase 4] Setting up Chroot mounts..."
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run

echo ">>> Setting up inside-chroot script..."
cp /gentoo-files/chroot_script.sh /mnt/gentoo/
chmod +x /mnt/gentoo/chroot_script.sh

echo ">>> Entering Chroot to continue Phases 4-7..."
chroot /mnt/gentoo /bin/bash /chroot_script.sh

echo "========================================================="
echo " abdallahOS Installation Complete! Rebooting VM... "
echo "========================================================="
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo
reboot
