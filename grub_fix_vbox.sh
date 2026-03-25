#!/bin/bash
# إصلاح GRUB داخل Oracle VM VirtualBox — نفس تخطيط install.sh في هذا المشروع:
#   /dev/sda1 = FAT32 (كامل /boot = ESP)
#   /dev/sda2 = ext4 (جذر النظام)
#
# ابدأ هيك:
# 1) إعدادات VM → System → Enable EFI (شغّال)
# 2) اربط ISO Gentoo minimal واقلع منه
# 3) انسخ هالسكربت للـ VM (مثلاً Shared Folder أو لصق في nano) ثم:
#    chmod +x grub_fix_vbox.sh && sudo ./grub_fix_vbox.sh
#
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GENTOO_ROOT="${GENTOO_ROOT:-/dev/sda2}"
export EFI_PART="${EFI_PART:-/dev/sda1}"
export EFI_IN_CHROOT="${EFI_IN_CHROOT:-/boot}"
exec bash "$DIR/grub_fix.sh"
