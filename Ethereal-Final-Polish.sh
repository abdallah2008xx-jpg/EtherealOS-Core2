#!/bin/bash
# ==========================================================
# EtherealOS Final Polish
# Fills in the missing visual gaps: Window Borders, Cursors, 
# and a glorious Terminal Welcome Screen.
# ==========================================================

echo "1. Installing Premium Window Borders (WhiteSur Theme for Metacity/GTK)..."
mkdir -p ~/.themes
wget -qO- https://raw.githubusercontent.com/vinceliuice/WhiteSur-gtk-theme/master/install.sh | bash -s -- -d ~/.themes -t all -N glassy

echo "2. Applying the Window Borders & GTK UI..."
# This changes the "Titlebar" and window buttons (Close/Minimize) to be incredibly sleek
gsettings set org.cinnamon.desktop.wm.preferences theme 'WhiteSur-Dark'
gsettings set org.cinnamon.desktop.interface gtk-theme 'WhiteSur-Dark'

echo "3. Installing Premium Mouse Cursor (Capitaine/Mac Style)..."
mkdir -p ~/.icons
if [ ! -d ~/.icons/capitaine-cursors ]; then
    wget -qO- https://github.com/keeferrourke/capitaine-cursors/releases/latest/download/capitaine-cursors-linux.tar.gz | tar -xz -C ~/.icons/
fi
gsettings set org.cinnamon.desktop.interface cursor-theme 'capitaine-cursors'

# Ensure Cursor Consistency (Inheritance for X11/GTK apps)
mkdir -p ~/.icons/default
echo "[Icon Theme]
Inherits=capitaine-cursors" > ~/.icons/default/index.theme
# Also set for X11 specifically
echo "Xcursor.theme: capitaine-cursors" >> ~/.Xresources
xrdb -merge ~/.Xresources 2>/dev/null || true

echo "4. Injecting EtherealOS Logo into Terminal (Neofetch)..."
# Create a custom ascii logo for EtherealOS
mkdir -p ~/.config/neofetch
cat << 'EOF' > ~/.config/neofetch/ethereal.txt
${c1}
    . . .    
  .       .  
 .         . 
.   ${c2}ETHEREAL${c1} .
 .         . 
  .       .  
    . . .    
EOF

# Only add neofetch if it's not already in .bashrc
if ! grep -q "neofetch --source ~/.config/neofetch/ethereal.txt" "$HOME/.bashrc" 2>/dev/null; then
    echo "command -v neofetch >/dev/null 2>&1 && neofetch --source ~/.config/neofetch/ethereal.txt --ascii_colors 6 4" >> "$HOME/.bashrc"
fi

echo "5. Adding Windows+Shift+S for Snip/Area Screenshot..."
gsettings set org.cinnamon.desktop.keybindings.media-keys area-screenshot "['<Shift><Super>s']" 2>/dev/null
# Add a custom keybinding fallback just in case the media-keys binding defaults are wonky
CUSTOM_LIST=$(gsettings get org.cinnamon.desktop.keybindings custom-list 2>/dev/null | grep -v 'custom-snip')
if [ -n "$CUSTOM_LIST" ] && [ "$CUSTOM_LIST" != "@as []" ]; then
    NEW_LIST=$(echo "$CUSTOM_LIST" | sed "s/\]/, 'custom-snip'\]/")
else
    NEW_LIST="['custom-snip']"
fi
gsettings set org.cinnamon.desktop.keybindings custom-list "$NEW_LIST" 2>/dev/null
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom-snip/ name "Ethereal Snipping Tool" 2>/dev/null
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom-snip/ command "gnome-screenshot -a" 2>/dev/null
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom-snip/ binding "['<Shift><Super>s']" 2>/dev/null

echo "6. Enabling Flatpak & Snap Support (Binary Apps)..."
# This allows users to install apps without waiting for long compile times.
if ! command -v flatpak >/dev/null 2>&1; then
    echo "   → Installing Flatpak..."
    sudo emerge --ask=n --quiet sys-apps/flatpak 2>/dev/null || true
fi
if command -v flatpak >/dev/null 2>&1; then
    echo "   → Adding Flathub Repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

if ! command -v snap >/dev/null 2>&1; then
    echo "   → Installing Snapd..."
    sudo emerge --ask=n --quiet app-containers/snapd 2>/dev/null || true
fi
if command -v snap >/dev/null 2>&1; then
    echo "   → Enabling Snap Service..."
    sudo rc-update add snapd default 2>/dev/null || true
    sudo rc-service snapd start 2>/dev/null || true
    # Create the /snap symlink if it doesn't exist
    [ ! -L /snap ] && sudo ln -s /var/lib/snapd/snap /snap 2>/dev/null || true
fi

echo "8. Enhancing Hardware (Battery, Printing, Bluetooth)..."
# A. Power Management (TLP)
if ! command -v tlp >/dev/null 2>&1; then
    echo "   → Installing TLP Power Management..."
    sudo emerge --ask=n --quiet sys-power/tlp 2>/dev/null || true
fi
if command -v tlp >/dev/null 2>&1; then
    sudo rc-update add tlp default 2>/dev/null || true
    sudo rc-service tlp start 2>/dev/null || true
fi

# B. Printing Support (CUPS & Drivers)
if ! command -v cupsd >/dev/null 2>&1; then
    echo "   → Installing CUPS & Printer Drivers..."
    sudo emerge --ask=n --quiet net-print/cups net-print/foomatic-db net-print/foomatic-db-engine net-print/gutenprint 2>/dev/null || true
fi
if command -v cupsd >/dev/null 2>&1; then
    sudo rc-update add cupsd default 2>/dev/null || true
    sudo rc-service cupsd start 2>/dev/null || true
fi

# C. Bluetooth Support (Bluez & Blueman)
if ! command -v bluetoothd >/dev/null 2>&1; then
    echo "   → Installing Bluetooth Stack..."
    sudo emerge --ask=n --quiet net-wireless/bluez net-wireless/blueman 2>/dev/null || true
fi
if command -v bluetoothd >/dev/null 2>&1; then
    sudo rc-update add bluetooth default 2>/dev/null || true
    sudo rc-service bluetooth start 2>/dev/null || true
fi

# D. Thermal Management (thermald)
if ! command -v thermald >/dev/null 2>&1; then
    echo "   → Installing Thermal Management (CPU Protection)..."
    sudo emerge --ask=n --quiet sys-apps/thermald 2>/dev/null || true
fi
if command -v thermald >/dev/null 2>&1; then
    sudo rc-update add thermald default 2>/dev/null || true
    sudo rc-service thermald start 2>/dev/null || true
fi

# E. Auto-Mount Support (gvfs & udisks)
echo "   → Configuring Auto-Mount for External Drives..."
sudo emerge --ask=n --quiet gnome-base/gvfs sys-apps/udisks 2>/dev/null || true
sudo rc-update add udisks2 default 2>/dev/null || true
sudo rc-service udisks2 start 2>/dev/null || true

# Configure Cinnamon to auto-mount when a drive is plugged in
gsettings set org.cinnamon.desktop.media-handling automount true 2>/dev/null
gsettings set org.cinnamon.desktop.media-handling automount-open true 2>/dev/null

echo "9. Integrating Multimedia Codecs (Video Fix)..."
# Call the codec setup script (as root)
if [ -f "$(dirname "$0")/Ethereal-Codecs-Setup.sh" ]; then
    sudo bash "$(dirname "$0")/Ethereal-Codecs-Setup.sh"
fi

echo "10. Deploying Glassmorphism Notification System (Dunst)..."
# Ensure dunst is installed
if ! command -v dunst >/dev/null 2>&1; then
    sudo emerge --ask=n --quiet x11-misc/dunst 2>/dev/null || true
fi
# Deploy Dunst config
mkdir -p ~/.config/dunst
if [ -f "$(dirname "$0")/dunstrc" ]; then
    cp "$(dirname "$0")/dunstrc" ~/.config/dunst/dunstrc
fi

echo "12. Enabling Eye Comfort (Night Light)..."
# Enable Cinnamon's native Night Light with an automatic schedule
gsettings set org.cinnamon.settings-daemon.plugins.color night-light-enabled true 2>/dev/null
gsettings set org.cinnamon.settings-daemon.plugins.color night-light-schedule-automatic true 2>/dev/null

echo "13. Deploying Automated Maintenance (Trash & Tmp Cleaning)..."
# Create a cleanup script that removes files older than 30 days
cat << 'EOF' | sudo tee /usr/local/bin/ethereal-cleanup.sh > /dev/null
#!/bin/bash
# EtherealOS Maintenance - Clean Trash and Tmp (>30 days)
find ~/.local/share/Trash/files/* -mtime +30 -exec rm -rf {} + 2>/dev/null
sudo find /tmp -type f -atime +30 -delete 2>/dev/null
EOF
sudo chmod +x /usr/local/bin/ethereal-cleanup.sh
# Add to crontab (Weekly at midnight on Sunday)
(crontab -l 2>/dev/null; echo "0 0 * * 0 /usr/local/bin/ethereal-cleanup.sh") | crontab - 2>/dev/null || true

echo "11. Installing Office & PDF Suite (BTEC Ready)..."
# A. Okular (Premium PDF with Signing/Annotations)
if ! command -v okular >/dev/null 2>&1; then
    echo "   → Installing Okular (PDF Reader)..."
    sudo emerge --ask=n --quiet kde-apps/okular 2>/dev/null || true
fi

# B. OnlyOffice (Microsoft Office Alternative via Flatpak)
if command -v flatpak >/dev/null 2>&1; then
    echo "   → Installing OnlyOffice Desktop Editors..."
    flatpak install --noninteractive flathub org.onlyoffice.desktopeditors 2>/dev/null || true
fi

# D. Dynamic Swap Management (Swapspace)
if ! command -v swapspace >/dev/null 2>&1; then
    echo "   → Installing Dynamic Swap Manager (Swapspace)..."
    sudo emerge --ask=n --quiet sys-apps/swapspace 2>/dev/null || true
fi
if command -v swapspace >/dev/null 2>&1; then
    echo "   → Enabling Dynamic Swap Service..."
    # Ensure the config exists and points to /var/lib/swapspace
    sudo mkdir -p /var/lib/swapspace
    sudo rc-update add swapspace default 2>/dev/null || true
    sudo rc-service swapspace start 2>/dev/null || true
fi

echo "14. Optimizing System Core (Pro Gaming Kernel)..."
# Add XanMod/Liquorix logic (using Gentoo overlays or binary sources)
if ! uname -r | grep -qiE "xanmod|liquorix"; then
    echo "   → Note: High-Performance Kernel (XanMod/Liquorix) is recommended."
    echo "   → Instructions added to Ethereal-ToolKit.sh for kernel switching."
    # We add the command to the Toolkit for the user to trigger when ready
    echo "   # To upgrade to XanMod (Optimized for Gaming):" >> Ethereal-ToolKit.sh
    echo "   # sudo emerge --ask sys-kernel/xanmod-kernel-bin" >> Ethereal-ToolKit.sh
fi

echo "EtherealOS Final Polish Complete!"
