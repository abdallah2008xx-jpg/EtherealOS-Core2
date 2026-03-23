#!/bin/bash
# ==========================================================
# Ethereal Architect OS - Pro Features Injector
# ==========================================================
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo "╔══════════════════════════════════════════════╗"
echo "║  Injecting Enterprise Ethereal Features...   ║"
echo "╚══════════════════════════════════════════════╝"

# 1. Rofi Spotlight (MacOS Command Center equivalent)
mkdir -p "$HOME/.config/rofi"
if [ -f "$SCRIPT_DIR/ethereal-rofi.rasi" ]; then
    cp "$SCRIPT_DIR/ethereal-rofi.rasi" "$HOME/.config/rofi/ethereal-rofi.rasi"
    echo "✅ Workspace Command Center (Rofi Ethereal Theme) installed."
fi

# 2. Hardware Manager and Welcome Screen on Desktop
DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")
mkdir -p "$DESKTOP_DIR"

if [ -f "$SCRIPT_DIR/Ethereal-Hardware-Manager.sh" ]; then
    cp "$SCRIPT_DIR/Ethereal-Hardware-Manager.sh" "$DESKTOP_DIR/Ethereal-Hardware-Manager.sh"
    chmod +x "$DESKTOP_DIR/Ethereal-Hardware-Manager.sh"
    echo "✅ Professional Ethereal Hardware Assistant deployed to Desktop."
fi

if [ -f "$SCRIPT_DIR/Ethereal-Welcome.sh" ]; then
    cp "$SCRIPT_DIR/Ethereal-Welcome.sh" "$DESKTOP_DIR/Ethereal-Welcome.sh"
    chmod +x "$DESKTOP_DIR/Ethereal-Welcome.sh"
    echo "✅ Enterprise Ethereal Welcome App deployed to Desktop."
fi

# 3. Create .desktop files so they look polished (like native commercial apps)
cat <<EOF > "$DESKTOP_DIR/HardwareManager.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Hardware Manager
Comment=Auto-Install System Drivers
Exec=$DESKTOP_DIR/Ethereal-Hardware-Manager.sh
Icon=preferences-system
Terminal=false
Categories=System;Settings;
EOF

cat <<EOF > "$DESKTOP_DIR/Welcome.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Welcome to Ethereal
Comment=EtherealOS First Setup
Exec=$DESKTOP_DIR/Ethereal-Welcome.sh
Icon=user-home
Terminal=false
Categories=System;
EOF

chmod +x "$DESKTOP_DIR/"*.desktop

# Cleanup actual scripts from desktop if we created pretty .desktop launchers
rm "$DESKTOP_DIR/Ethereal-Hardware-Manager.sh" 2>/dev/null
rm "$DESKTOP_DIR/Ethereal-Welcome.sh" 2>/dev/null
# Wait, we need them to be in a bin folder or ~/.local/bin!
mkdir -p "$HOME/.local/bin"
cp "$SCRIPT_DIR/Ethereal-Hardware-Manager.sh" "$HOME/.local/bin/"
cp "$SCRIPT_DIR/Ethereal-Welcome.sh" "$HOME/.local/bin/"

sed -i "s|$DESKTOP_DIR|$HOME/.local/bin|g" "$DESKTOP_DIR/HardwareManager.desktop"
sed -i "s|$DESKTOP_DIR|$HOME/.local/bin|g" "$DESKTOP_DIR/Welcome.desktop"

echo "✅ App Shortcuts generated cleanly."
echo "✅ Enterprise features successfully injected into EtherealOS!"
