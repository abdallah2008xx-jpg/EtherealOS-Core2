#!/bin/bash
#
# إصلاح GRUB لـ abdallahOS / Gentoo — شغّله من ISO حيّ (USB)، ليس من ويندوز.
#
# قبل التشغيل:
# 1) نزّل ISO (Gentoo minimal أو أي توزيعة live) واصنع USB.
# 2) اقلع من الـ USB (Boot Menu).
# 3) افتح طرفية root وانقل هذا الملف للجهاز (USB ثاني أو wget) ثم:
#    chmod +x grub_fix.sh && sudo ./grub_fix.sh
#
# إن كان Secure Boot مفعّل وما اشتغل بعد الإصلاح، عطّله مؤقتاً من إعدادات UEFI.
#
# تنبيه: إذا عندك قسم منفصل لـ /boot (ليس نفس ESP)، لازم تركّبه يدوياً على /mnt/gentoo-fix/boot
# قبل تشغيل باقي الخطوات — السكربت يركّب جذر النظام + ESP فقط.
#
# VirtualBox + تثبيت هذا المشروع (install.sh): القسم الأول FAT32 يُركّب على /boot كاملًا — اختر 2) وليس /boot/efi.
#
set -e

BOOTLOADER_ID="${BOOTLOADER_ID:-abdallahOS}"

echo "=== إصلاح GRUB (UEFI) ==="
echo ""

if [[ $EUID -ne 0 ]]; then
  echo "شغّل السكربت كـ root: sudo $0"
  exit 1
fi

list_parts() {
  echo "--- الأقسام (انسخ الاسم الصحيح مثل /dev/nvme0n1p2) ---"
  lsblk -o NAME,SIZE,FSTYPE,PARTLABEL,MOUNTPOINTS 2>/dev/null || lsblk
  echo ""
}

if [[ -z "${GENTOO_ROOT:-}" ]]; then
  list_parts
  read -r -p "قسم جذر Linux (root) — مثال /dev/nvme0n1p2 أو /dev/sda2: " GENTOO_ROOT
fi
if [[ -z "${GENTOO_ROOT}" || ! -b "$GENTOO_ROOT" ]]; then
  echo "خطأ: '$GENTOO_ROOT' ليس قسماً صالحاً."
  exit 1
fi

if [[ -z "${EFI_PART:-}" ]]; then
  echo "عادة يكون قسم صغير FAT32 (ESP)، غالباً قبل قسم الجذر."
  read -r -p "قسم EFI (FAT32) — مثال /dev/nvme0n1p1 أو /dev/sda1: " EFI_PART
fi
if [[ -z "${EFI_PART}" || ! -b "$EFI_PART" ]]; then
  echo "خطأ: '$EFI_PART' ليس قسماً صالحاً."
  exit 1
fi

# أين يُركّب GRUB داخل النظام المثبّت؟ غالباً /boot/efi أحياناً يكون كامل /boot هو الـ ESP
if [[ -z "${EFI_IN_CHROOT:-}" ]]; then
  echo ""
  echo "اختر أين يُركّب الـ ESP داخل نظامك المثبّت:"
  echo "  1) /boot/efi  (الأشيع مع Gentoo)"
  echo "  2) /boot      (كامل مجلد boot هو الـ ESP)"
  read -r -p "اختر 1 أو 2 [افتراضي 1]: " _choice
  case "${_choice:-1}" in
    2) EFI_IN_CHROOT="/boot" ;;
    *) EFI_IN_CHROOT="/boot/efi" ;;
  esac
fi

MNT="/mnt/gentoo-fix"
mkdir -p "$MNT"

echo ""
echo "=== ربط الأقسام ==="
mount "$GENTOO_ROOT" "$MNT"

mkdir -p "${MNT}${EFI_IN_CHROOT}"
mount "$EFI_PART" "${MNT}${EFI_IN_CHROOT}"

mount -t proc proc "$MNT/proc"
mount -t sysfs sys "$MNT/sys"
mount -o bind /dev "$MNT/dev"
mount -o bind /run "$MNT/run" 2>/dev/null || true

cleanup() {
  set +e
  umount -R "$MNT" 2>/dev/null
}
trap cleanup EXIT

echo ""
echo "=== حالة EFI قبل الإصلاح ==="
ls -la "${MNT}${EFI_IN_CHROOT}/EFI/" 2>/dev/null || echo "(لا يوجد مجلد EFI بعد)"

if [[ ! -d "$MNT/etc" ]]; then
  echo "خطأ: لا يبدو أن $GENTOO_ROOT يحتوي نظاماً مثبتاً (لا يوجد etc/)."
  exit 1
fi

echo ""
echo "=== تثبيت GRUB داخل chroot ==="
chroot "$MNT" /bin/bash -lc "
  set -e
  [[ -f /etc/profile ]] && source /etc/profile
  export PATH=\"/usr/sbin:/usr/bin:/sbin:/bin\"
  if ! command -v grub-install >/dev/null 2>&1; then
    echo 'تثبيت حزمة sys-boot/grub (يحتاج إنترنت على الـ live)...'
    emerge -n sys-boot/grub
  fi
  mkdir -p /boot/grub
  grub-install --target=x86_64-efi --efi-directory=$EFI_IN_CHROOT --bootloader-id=$BOOTLOADER_ID --recheck --force
  grub-mkconfig -o /boot/grub/grub.cfg
"

echo ""
echo "=== نسخة احتياطية لـ UEFI (Fallback) ==="
BOOT_EFI_DIR="${MNT}${EFI_IN_CHROOT}/EFI"
if [[ -d "$BOOT_EFI_DIR/$BOOTLOADER_ID" ]]; then
  mkdir -p "$BOOT_EFI_DIR/BOOT"
  if [[ -f "$BOOT_EFI_DIR/$BOOTLOADER_ID/grubx64.efi" ]]; then
    cp -f "$BOOT_EFI_DIR/$BOOTLOADER_ID/grubx64.efi" "$BOOT_EFI_DIR/BOOT/BOOTX64.EFI"
    cp -f "$BOOT_EFI_DIR/$BOOTLOADER_ID/grubx64.efi" "$BOOT_EFI_DIR/BOOT/bootx64.efi"
    echo "تم نسخ grubx64.efi إلى EFI/BOOT/"
  fi
else
  echo "تحذير: لم يُعثر على $BOOT_EFI_DIR/$BOOTLOADER_ID"
fi

echo ""
echo "=== ملفات .efi ==="
find "$BOOT_EFI_DIR" -name '*.efi' -type f 2>/dev/null || true

# efibootmgr يقرأ متغيرات الـ UEFI من الجهاز الحيّ — لا تشغّله داخل chroot (قد لا يكون مثبتاً هناك أو يضلّ المسار).
if command -v efibootmgr >/dev/null 2>&1; then
  echo ""
  echo "=== إدخالات التمهيد الحالية (efibootmgr) ==="
  efibootmgr -v 2>/dev/null || true
fi

trap - EXIT
umount -R "$MNT"
echo ""
echo "تم. أعد التشغيل واختر القرص الداخلي أو '$BOOTLOADER_ID' من Boot Menu."
echo "إذا بقي نفس السلوك: عطّل Secure Boot من UEFI ثم جرّب مجدداً."
