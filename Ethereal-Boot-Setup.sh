#!/bin/bash
# ==========================================================
# EtherealOS - Boot Animation & Startup Sound v1.0
# "The First Impression" - Plymouth & Audio Setup
# ==========================================================

echo "🔊 Initializing EtherealOS Boot Experience..."

# 1. Install Plymouth
echo "📦 Installing Plymouth..."
emerge --ask=n --quiet sys-boot/plymouth 2>/dev/null || true

# 2. Create Ethereal Plymouth Theme
THEME_DIR="/usr/share/plymouth/themes/ethereal"
mkdir -p "$THEME_DIR"

# Metadata file
cat << 'EOF' > "$THEME_DIR/ethereal.plymouth"
[Plymouth Theme]
Name=EtherealOS
Description=A premium dark cosmic boot animation.
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/ethereal
ScriptFile=/usr/share/plymouth/themes/ethereal/ethereal.script
EOF

# Animation Script (Minimalist Fade-in)
cat << 'EOF' > "$THEME_DIR/ethereal.script"
Window.SetBackgroundTopColor(0.05, 0.05, 0.09);
Window.SetBackgroundBottomColor(0.05, 0.05, 0.09);

logo_image = Image("logo.png");
logo_sprite = Sprite(logo_image);

logo_sprite.SetX(Window.GetWidth()  / 2 - logo_image.GetWidth()  / 2);
logo_sprite.SetY(Window.GetHeight() / 2 - logo_image.GetHeight() / 2);
logo_sprite.SetOpacity(0);

opacity = 0;
progress = 0;

fun refresh_callback () {
    if (opacity < 1) {
        opacity += 0.02;
        logo_sprite.SetOpacity(opacity);
    }
}

Plymouth.SetRefreshFunction (refresh_callback);
EOF

# Note: The logo.png should be copied by the installer script or build process.
# Mapping the generated image here (placeholder for now, will be replaced in ISO build).

# 3. Apply Plymouth Theme
if command -v plymouth-set-default-theme &> /dev/null; then
    plymouth-set-default-theme -R ethereal
fi

# 4. Update GRUB for Splash
echo "🚀 Updating GRUB configuration..."
if [ -f /etc/default/grub ]; then
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 quiet splash"/' /etc/default/grub
    grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
fi

# 5. Startup Sound Setup (OpenRC Service)
echo "🎵 Configuring Startup Sound..."
SOUND_FILE="/usr/share/sounds/ethereal-startup.mp3"
# (Assuming sound file exists or will be provided)

cat << 'EOF' > /etc/init.d/ethereal-sound
#!/sbin/openrc-run
description="Plays the EtherealOS startup sound"

start() {
    ebegin "Playing EtherealOS Startup Sound"
    # Play sound using paplay or mpv (run as the main user if possible)
    # Since we are in OpenRC (root), we use a generic play command
    ( sleep 5 && /usr/bin/mpv --no-video "$SOUND_FILE" ) &
    eend $?
}
EOF

chmod +x /etc/init.d/ethereal-sound
rc-update add ethereal-sound default

echo "✅ Boot Experience configured successfully."
