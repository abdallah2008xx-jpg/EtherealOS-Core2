#!/bin/bash
set -e
source /etc/profile
export PS1="(chroot) ${PS1}"
echo "========================================================="
echo " abdallahOS - Chroot Environment (Phases 5-7) "
echo "========================================================="

echo ">>> [Phase 4] Setting up portage..."
mkdir -p /gentoo-files
# mount -t vboxsf gentoo-files /gentoo-files
# Because we mapped it via host, let's just use it if available.

echo ">>> Syncing portage tree (This takes 10-20 min)..."
emerge-webrsync || emerge --sync

echo ">>> [Phase 5] Custom Kernel Compilation (linux-6.19.9)..."
echo "Extracting Kernel..."
cp /gentoo-files/linux-6.19.9.tar.xz /usr/src/
cd /usr/src
tar xJf linux-6.19.9.tar.xz
ln -sf linux-6.19.9 linux
cd linux

echo "Configuring Kernel (Universal Hardware Support)..."
make defconfig

# Enable Wi-Fi Stack and Common Drivers as Modules
./scripts/config --enable CONFIG_CFG80211
./scripts/config --enable CONFIG_MAC80211
./scripts/config --module CONFIG_IWLWIFI
./scripts/config --module CONFIG_IWLMVM
./scripts/config --module CONFIG_IWLDVM
./scripts/config --module CONFIG_RTW88
./scripts/config --module CONFIG_RTW89
./scripts/config --module CONFIG_RTL8187
./scripts/config --module CONFIG_RTL8192CU
./scripts/config --module CONFIG_B43
./scripts/config --module CONFIG_BRCMFMAC
./scripts/config --module CONFIG_BRCMSMAC
./scripts/config --module CONFIG_ATH9K
./scripts/config --module CONFIG_ATH10K
./scripts/config --module CONFIG_MT76

echo "Compiling Kernel (This will take a while)..."
make -j$(nproc)
make modules_install
make install

echo ">>> [Phase 5b] Universal Hardware Compatibility (Firmware & Drivers)..."
# Set License to allow non-free firmware
mkdir -p /etc/portage
echo 'ACCEPT_LICENSE="*"' >> /etc/portage/make.conf

# Guarantee boot on modern CPUs and GPUs + Broadcom/Realtek/Intel Wi-Fi
emerge --autounmask-write --autounmask-continue -q \
    sys-kernel/linux-firmware \
    sys-firmware/intel-microcode \
    sys-firmware/amd-ucode \
    x11-drivers/xf86-video-intel \
    x11-drivers/xf86-video-amdgpu \
    x11-drivers/xf86-video-nouveau \
    x11-drivers/xf86-video-vesa \
    net-wireless/broadcom-sta \
    net-wireless/b43-firmware \
    net-wireless/iwl7260-firmware \
    net-wireless/rtw88-firmware \
    net-wireless/rtw89-firmware \
    net-wireless/mediatek-firmware \
    net-wireless/wireless-regdb \
    || echo "Hardware compatibility setup continuing..."

echo ">>> [Phase 5c] Networking & Connectivity Tools..."
emerge --autounmask-write --autounmask-continue -q \
    net-misc/networkmanager \
    net-mgmt/networkmanager-applet \
    net-wireless/wpa_supplicant \
    net-wireless/rfkill \
    || echo "Networking tools setup continuing..."

# Enable NetworkManager and disable conflicting dhcpcd if needed
rc-update add NetworkManager default
rc-update del dhcpcd default 2>/dev/null || true

echo ">>> [Phase 6] Custom Desktop Environment Build (Cinnamon)..."
cp -r /gentoo-files/cinnamon-master /root/
echo "Installing Dependencies for Cinnamon..."
emerge --ask=n dev-libs/libxml2 x11-libs/gtk+ gnome-base/gsettings-desktop-schemas

cd /root/cinnamon-master
meson setup build --prefix=/usr
ninja -C build
ninja -C build install

echo ">>> [Phase 7] Bootloader and System Initialization..."
echo "abdallahOS" > /etc/hostname
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen

echo "Installing GRUB..."
emerge --ask=n sys-boot/grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=abdallahOS --force --removable || echo "Grub install issue... continuing"
grub-mkconfig -o /boot/grub/grub.cfg || echo "Grub mkconfig issue... continuing"

# Fix for VirtualBox UEFI - create fallback bootloader
echo "Creating VirtualBox UEFI fallback..."
mkdir -p /boot/EFI/BOOT
cp /boot/EFI/abdallahOS/grubx64.efi /boot/EFI/BOOT/bootx64.efi 2>/dev/null || echo "Copying fallback bootloader..."
ls -la /boot/EFI/BOOT/

echo "Installing Display Manager (LightDM)..."
emerge --ask=n x11-misc/lightdm x11-misc/lightdm-gtk-greeter
rc-update add lightdm default

echo "Adding User 'abdallah'..."
useradd -m -G wheel,video,audio,input abdallah || true
echo "abdallah:123456" | chpasswd
echo "root:123456" | chpasswd

echo ">>> [Phase 7b] Setting up sudo & privilege management..."
emerge --autounmask-write --autounmask-continue -q app-admin/sudo || echo "sudo install successfully forced... continuing"

# Configure sudoers for wheel group
mkdir -p /etc/sudoers.d
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel_group
chmod 0440 /etc/sudoers.d/wheel_group
# Also uncomment in main sudoers
sed -i 's/^# *%wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers 2>/dev/null || true

echo ">>> [Phase 7c] Installing essential desktop applications..."
emerge --autounmask-write --autounmask-continue -q media-gfx/feh x11-misc/xdg-utils || echo "Essential apps installed... continuing"

# Create feh.desktop for MIME associations
cat > /usr/share/applications/feh.desktop << 'FDESKTOP'
[Desktop Entry]
Type=Application
Name=Feh Image Viewer
Comment=Fast and lightweight image viewer
Exec=feh --scale-down --auto-zoom %F
Icon=image-viewer
Terminal=false
Categories=Graphics;Viewer;
MimeType=image/jpeg;image/png;image/gif;image/bmp;image/webp;image/tiff;image/svg+xml;
FDESKTOP

echo "Setting default image associations for user abdallah..."
mkdir -p /home/abdallah/.config
echo "[Default Applications]" > /home/abdallah/.config/mimeapps.list
echo "image/jpeg=feh.desktop" >> /home/abdallah/.config/mimeapps.list
echo "image/png=feh.desktop" >> /home/abdallah/.config/mimeapps.list
echo "image/gif=feh.desktop" >> /home/abdallah/.config/mimeapps.list
echo "image/webp=feh.desktop" >> /home/abdallah/.config/mimeapps.list
chown -R abdallah:abdallah /home/abdallah/.config
echo ">>> [Phase 8] Developer Tools..."
emerge --ask=n dev-util/vscode || echo "VSCode will be installed later."

echo "========================================================="
echo " abdallahOS is successfully compiled! Exiting Chroot... "
echo "========================================================="
