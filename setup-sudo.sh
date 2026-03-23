#!/bin/bash
# ==========================================================
#  EtherealOS — Root Access & Essential Software Fix
#
#  المشكلة: النظام مبني بدون sudo ولا صلاحيات root للمستخدم
#  الحل: هذا السكربت يجب تشغيله كـ root عبر su
#
#  HOW TO RUN:
#  1. Open terminal
#  2. Type: su -
#  3. Enter root password (123456)
#  4. Run: bash /gentoo-files/setup-sudo.sh
#     OR:  bash /mnt/shared/setup-sudo.sh
# ==========================================================

set -e

# ── Verify running as root ──
if [ "$(id -u)" -ne 0 ]; then
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║  ❌ ERROR: This script must be run as root!             ║"
  echo "║                                                          ║"
  echo "║  الخطوات:                                               ║"
  echo "║  1. افتح الطرفية (Terminal)                              ║"
  echo "║  2. اكتب: su -                                          ║"
  echo "║  3. ادخل كلمة سر الروت: 123456                         ║"
  echo "║  4. شغل السكربت:                                        ║"
  echo "║     bash /gentoo-files/setup-sudo.sh                     ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  exit 1
fi

echo "╔══════════════════════════════════════════════════════════╗"
echo "║   🔧 EtherealOS — System Privilege & Software Fix       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Sync portage (needed to install anything) ──
echo "[1/7] 📡 Syncing portage tree..."
if ! ls /var/db/repos/gentoo/metadata/timestamp.chk >/dev/null 2>&1; then
  echo "  → Full sync needed (first time)..."
  emerge-webrsync 2>/dev/null || emerge --sync 2>/dev/null || echo "  ⚠ Sync failed — will try installing anyway"
else
  SYNC_AGE=$(( ( $(date +%s) - $(stat -c %Y /var/db/repos/gentoo/metadata/timestamp.chk) ) / 86400 ))
  if [ "$SYNC_AGE" -gt 7 ]; then
    echo "  → Portage tree is ${SYNC_AGE} days old, syncing..."
    emerge --sync 2>/dev/null || echo "  ⚠ Sync failed — continuing with existing tree"
  else
    echo "  → Portage tree is fresh (${SYNC_AGE} days old)"
  fi
fi
echo "  ✅ Portage ready."

# ── Step 2: Install sudo ──
echo ""
echo "[2/7] 📦 Installing sudo..."
if command -v sudo >/dev/null 2>&1; then
  echo "  ✅ sudo is already installed."
else
  emerge --ask=n --quiet app-admin/sudo && echo "  ✅ sudo installed." || {
    echo "  ⚠ emerge failed, trying alternative method..."
    # Try with autounmask if USE flags are the issue
    emerge --autounmask-write --autounmask-continue --ask=n app-admin/sudo || echo "  ❌ Could not install sudo"
  }
fi

# ── Step 3: Install image viewer + essential apps ──
echo ""
echo "[3/7] 📦 Installing essential applications..."
ESSENTIAL_PKGS=""

# Image viewer — try feh first (lightweight), fallback to eog
if ! command -v feh >/dev/null 2>&1 && ! command -v eog >/dev/null 2>&1; then
  ESSENTIAL_PKGS="$ESSENTIAL_PKGS media-gfx/feh"
fi

# File manager check
if ! command -v nemo >/dev/null 2>&1 && ! command -v nautilus >/dev/null 2>&1; then
  ESSENTIAL_PKGS="$ESSENTIAL_PKGS gnome-extra/nemo"
fi

# xdg-utils for MIME associations
if ! command -v xdg-mime >/dev/null 2>&1; then
  ESSENTIAL_PKGS="$ESSENTIAL_PKGS x11-misc/xdg-utils"
fi

if [ -n "$ESSENTIAL_PKGS" ]; then
  echo "  → Installing: $ESSENTIAL_PKGS"
  emerge --ask=n --quiet $ESSENTIAL_PKGS || {
    echo "  ⚠ Some packages failed. Trying one by one..."
    for pkg in $ESSENTIAL_PKGS; do
      emerge --ask=n --quiet "$pkg" 2>/dev/null || echo "  ⚠ Failed: $pkg"
    done
  }
else
  echo "  ✅ Essential apps already present."
fi
echo "  ✅ Essential packages done."

# ── Step 4: Configure sudo for wheel group ──
echo ""
echo "[4/7] 🔑 Configuring sudo privileges..."
mkdir -p /etc/sudoers.d

# Method 1: sudoers.d drop-in (clean, modular)
cat > /etc/sudoers.d/wheel_group << 'SUDOERS'
## Allow members of the 'wheel' group to execute any command
%wheel ALL=(ALL:ALL) ALL
SUDOERS
chmod 0440 /etc/sudoers.d/wheel_group

# Method 2: Also uncomment wheel in main sudoers if it exists
if [ -f /etc/sudoers ]; then
  # Uncomment the wheel line if it's commented
  sed -i 's/^# *%wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers 2>/dev/null
  sed -i 's/^# *%wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers 2>/dev/null
fi

echo "  ✅ Wheel group can now use sudo."

# ── Step 5: Ensure user 'abdallah' is in wheel group ──
echo ""
echo "[5/7] 👤 Configuring user 'abdallah'..."
if id abdallah >/dev/null 2>&1; then
  # Add to wheel, video, audio groups
  usermod -aG wheel,video,audio,input abdallah
  echo "  ✅ User 'abdallah' added to: wheel, video, audio, input"
  echo "  → Groups: $(groups abdallah)"
else
  echo "  ⚠ User 'abdallah' does not exist! Creating..."
  useradd -m -G wheel,video,audio,input -s /bin/bash abdallah
  echo "abdallah:123456" | chpasswd
  echo "  ✅ User 'abdallah' created with password 123456"
fi

# ── Step 6: Set root password (if not already set) ──
echo ""
echo "[6/7] 🔐 Ensuring root password is set..."
# Check if root has a password
if grep -q '^root:!' /etc/shadow 2>/dev/null || grep -q '^root:\*' /etc/shadow 2>/dev/null; then
  echo "  → Root has no password, setting to '123456'..."
  echo "root:123456" | chpasswd
  echo "  ✅ Root password set."
else
  echo "  ✅ Root password already configured."
fi

# ── Step 7: Configure MIME associations for images ──
echo ""
echo "[7/7] 🖼️  Setting up image file associations..."
if command -v feh >/dev/null 2>&1; then
  # Create feh.desktop if missing
  if [ ! -f /usr/share/applications/feh.desktop ]; then
    cat > /usr/share/applications/feh.desktop << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=Feh Image Viewer
Comment=Fast and lightweight image viewer
Exec=feh --scale-down --auto-zoom %F
Icon=image-viewer
Terminal=false
Categories=Graphics;Viewer;
MimeType=image/jpeg;image/png;image/gif;image/bmp;image/webp;image/tiff;image/svg+xml;
DESKTOP
  fi

  # Set as default for common image types
  su - abdallah -c "
    xdg-mime default feh.desktop image/jpeg 2>/dev/null
    xdg-mime default feh.desktop image/png 2>/dev/null
    xdg-mime default feh.desktop image/gif 2>/dev/null
    xdg-mime default feh.desktop image/webp 2>/dev/null
    xdg-mime default feh.desktop image/bmp 2>/dev/null
    xdg-mime default feh.desktop image/svg+xml 2>/dev/null
  " 2>/dev/null
  echo "  ✅ feh set as default image viewer."
elif command -v eog >/dev/null 2>&1; then
  su - abdallah -c "
    xdg-mime default org.gnome.eog.desktop image/jpeg 2>/dev/null
    xdg-mime default org.gnome.eog.desktop image/png 2>/dev/null
  " 2>/dev/null
  echo "  ✅ Eye of GNOME set as default image viewer."
fi

# ── Final verification ──
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ SYSTEM FIX COMPLETE!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Verification:"

# Check sudo
if command -v sudo >/dev/null 2>&1; then
  echo "  ✅ sudo: installed ($(which sudo))"
else
  echo "  ❌ sudo: NOT installed"
fi

# Check image viewer
if command -v feh >/dev/null 2>&1; then
  echo "  ✅ Image viewer: feh ($(which feh))"
elif command -v eog >/dev/null 2>&1; then
  echo "  ✅ Image viewer: eog ($(which eog))"
else
  echo "  ❌ Image viewer: NOT installed"
fi

# Check groups
echo "  ✅ User groups: $(groups abdallah 2>/dev/null || echo 'N/A')"
echo ""
echo "  الآن يمكن للمستخدم abdallah استخدام:"
echo "    sudo emerge --ask=n <package>"
echo "    sudo reboot"
echo ""
echo "  لفتح الصور: انقر مرتين على أي صورة"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
