#!/bin/bash
# Complete AhmadOS Installation Script
set -e

echo "=============================================="
echo " AhmadOS - Complete Installation"
echo "=============================================="

# PHASE 1: Partitioning
echo "[1/8] Partitioning disk..."
parted -s /dev/sda mklabel gpt
parted -s /dev/sda mkpart primary fat32 1MiB 513MiB
parted -s /dev/sda name 1 boot
parted -s /dev/sda set 1 esp on
parted -s /dev/sda mkpart primary ext4 513MiB 100%
parted -s /dev/sda name 2 root

# PHASE 2: Formatting
echo "[2/8] Formatting partitions..."
mkfs.fat -F32 /dev/sda1
mkfs.ext4 -F /dev/sda2

# PHASE 3: Mounting
echo "[3/8] Mounting..."
mount /dev/sda2 /mnt/gentoo
mkdir -p /mnt/gentoo/boot
mount /dev/sda1 /mnt/gentoo/boot

# PHASE 4: Stage3
echo "[4/8] Extracting Stage3..."
if [ -f /gentoo-files/stage3-amd64-desktop-openrc-20260316T093103Z.tar.xz ]; then
    tar xpf /gentoo-files/stage3-amd64-desktop-openrc-20260316T093103Z.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo
else
    echo "ERROR: Stage3 not found!"
    exit 1
fi

# PHASE 5: Prepare chroot
echo "[5/8] Preparing chroot..."
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev

# PHASE 6: Basic config
echo "[6/8] Basic configuration..."
chroot /mnt/gentoo /bin/bash -c "
source /etc/profile

# Hostname and locale
echo 'abdallahOS' > /etc/hostname
echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
locale-gen

# Sync portage
emerge-webrsync || emerge --sync

# Install kernel
emerge -n sys-kernel/gentoo-kernel-bin
"

# PHASE 7: GRUB (CRITICAL - with VirtualBox fixes)
echo "[7/8] Installing GRUB with VirtualBox fixes..."
chroot /mnt/gentoo /bin/bash -c "
source /etc/profile

# Install GRUB package
emerge -n sys-boot/grub

# Install GRUB to EFI with force and removable options
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=abdallahOS --force --recheck --removable

# Create config
grub-mkconfig -o /boot/grub/grub.cfg

# CRITICAL: Create fallback bootloader for VirtualBox
mkdir -p /boot/EFI/BOOT
cp /boot/EFI/abdallahOS/grubx64.efi /boot/EFI/BOOT/bootx64.efi

# Verify
ls -la /boot/EFI/abdallahOS/
ls -la /boot/EFI/BOOT/
"

# PHASE 8: Finish
echo "[8/8] Finishing..."
chroot /mnt/gentoo /bin/bash -c "
# Add user
useradd -m -G wheel,video,audio abdallah 2>/dev/null || true
echo 'abdallah:123456' | chpasswd

# Enable networking
rc-update add dhcpcd default
"

echo "=============================================="
echo " Installation Complete! Rebooting..."
echo "=============================================="
umount -l /mnt/gentoo/dev{/shm,/pts,} 2>/dev/null
umount -R /mnt/gentoo
reboot
