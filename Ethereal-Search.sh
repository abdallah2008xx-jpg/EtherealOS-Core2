#!/bin/bash
# ==========================================================
# EtherealOS - Global Instant Search v1.0
# "Search everything, instantly."
# ==========================================================

echo "🔍 Initializing Global Search..."

# 1. Install dependencies (fd-find is extremely fast)
echo "📦 Installing Search Engine..."
emerge --ask=n --quiet sys-apps/fd 2>/dev/null || true

# 2. Create the unified Search script
# This script will be bound to the Super key.
cat << 'EOF' > /usr/local/bin/ethereal-search
#!/bin/bash
THEME="/etc/ethereal/ethereal-rofi.rasi"
[ ! -f "$THEME" ] && THEME="$HOME/.config/rofi/ethereal-rofi.rasi"

# Launch Rofi with drun, window, and file-browser modes
# We add a custom "Files" mode using fd
rofi -show drun \
     -modi "drun,window,files:ethereal-file-search" \
     -show-icons \
     -theme "$THEME" \
     -placeholder "Search Apps, Windows, or Files..."
EOF

chmod +x /usr/local/bin/ethereal-search

# 3. Create the file search backend
cat << 'EOF' > /usr/local/bin/ethereal-file-search
#!/bin/bash
if [ -z "$1" ]; then
    # Initial state: Show recent files or home directory
    fd --max-depth 2 --exclude .git --exclude .cache . "$HOME"
else
    # Search state: Query fd
    fd --exclude .git --exclude .cache "$1" "$HOME"
fi
EOF

chmod +x /usr/local/bin/ethereal-file-search

# 4. Bind Super key to Ethereal Search in Cinnamon
echo "⌨️ Binding Search to Super Key..."
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ name "Ethereal Search"
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ command "/usr/local/bin/ethereal-search"
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom0/ binding "['Super_L', 'Super_R']"

# Ensure it's in the list of custom keybindings
CURRENT_BINDINGS=$(gsettings get org.cinnamon.desktop.keybindings custom-list)
if [[ "$CURRENT_BINDINGS" != *"custom0"* ]]; then
    gsettings set org.cinnamon.desktop.keybindings custom-list "['custom0']"
fi

echo "✅ Global Search successfully integrated."
