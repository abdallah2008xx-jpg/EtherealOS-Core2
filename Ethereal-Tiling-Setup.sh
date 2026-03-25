#!/bin/bash
# ==========================================================
# EtherealOS - Advanced Window Tiling v1.0
# "Snap Layouts" - gTile Extension Setup
# ==========================================================

echo "🪟 Initializing Snap Layouts Tiling System..."

EXT_ID="gTile@grillert.it"
EXT_DIR="$HOME/.local/share/cinnamon/extensions/$EXT_ID"
mkdir -p "$EXT_DIR"

# 1. Download/Install gTile (using the latest stable version)
# In a real ISO build, we would include the files in the repo.
# For now, we simulate the install or download if online.
echo "📦 Installing gTile extension..."
if [ ! -d "$EXT_DIR/extension.js" ]; then
    # Standard location for gTile on GitHub
    # Note: Using a direct download as a placeholder for the build process.
    # In practice, we'd have this in the EtherealOS-Repo.
    git clone --depth 1 https://github.com/schober-m/gTile.git /tmp/gTile-source 2>/dev/null
    cp -r /tmp/gTile-source/* "$EXT_DIR/"
    rm -rf /tmp/gTile-source
fi

# 2. Enable the extension
echo "🔓 Enabling gTile in Cinnamon..."
CURRENT_EXTS=$(gsettings get org.cinnamon enabled-extensions 2>/dev/null)
if [[ "$CURRENT_EXTS" != *"$EXT_ID"* ]]; then
    if [ "$CURRENT_EXTS" = "@as []" ] || [ -z "$CURRENT_EXTS" ]; then
        gsettings set org.cinnamon enabled-extensions "['$EXT_ID']"
    else
        # Correctly append to the list
        UPDATED=$(echo "$CURRENT_EXTS" | sed "s/\]$/, '$EXT_ID']/")
        gsettings set org.cinnamon enabled-extensions "$UPDATED"
    fi
fi

# 3. Configure gTile for "Snap Layouts" behavior
# We set a custom shortcut and grid sizes
echo "⚙️ Configuring Snap Layouts settings..."
# Setting Super+G as the trigger (like Windows 11 Snap)
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom1/ name "Snap Layouts (gTile)"
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom1/ command "dbus-send --session --type=method_call --dest=org.Cinnamon.gTile /org/Cinnamon/gTile org.Cinnamon.gTile.Show"
gsettings set org.cinnamon.desktop.keybindings.custom-keybinding:/org/cinnamon/desktop/keybindings/custom-keybindings/custom1/ binding "['<Super>z']"

# Ensure it's in the list of custom keybindings
CURRENT_BINDINGS=$(gsettings get org.cinnamon.desktop.keybindings custom-list)
if [[ "$CURRENT_BINDINGS" != *"custom1"* ]]; then
    if [ "$CURRENT_BINDINGS" = "@as []" ]; then
        gsettings set org.cinnamon.desktop.keybindings custom-list "['custom1']"
    else
        UPDATED=$(echo "$CURRENT_BINDINGS" | sed "s/\]$/, 'custom1']/")
        gsettings set org.cinnamon.desktop.keybindings custom-list "$UPDATED"
    fi
fi

# 4. Restart Cinnamon to apply extension
echo "🔄 Reloading Cinnamon Shell..."
nohup bash -c "sleep 2 && dbus-send --session --type=method_call --dest=org.Cinnamon /org/Cinnamon org.Cinnamon.Eval string:'global.reexec_self()'" > /dev/null 2>&1 &

echo "✅ Window Tiling (Snap Layouts) enabled."
