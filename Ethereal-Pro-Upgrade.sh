#!/bin/bash
# ==========================================================
# Ethereal Architect OS - Pro Upgrade v2
# Adds Desklets, bespoke terminal aesthetics, and smooth animations.
# ==========================================================

echo "╔══════════════════════════════════════════════╗"
echo "║  Upgrading EtherealOS to Pro Level...      ║"
echo "╚══════════════════════════════════════════════╝"

# 1. Add ultra-smooth window animations
gsettings set org.cinnamon.muffin desktop-effects true
gsettings set org.cinnamon.desktop.interface enable-animations true

# Cinnamon actually has specific effect dconfs:
# This changes traditional 'fade' to more dynamic 'scale' or 'fly'
gsettings set org.cinnamon desktop-effects-maximize-effect 'scale'
gsettings set org.cinnamon desktop-effects-minimize-effect 'scale'
gsettings set org.cinnamon desktop-effects-close-effect 'scale'
gsettings set org.cinnamon desktop-effects-map-effect 'scale'

# 2. Add an elegant Clock Desklet to the Desktop (Center right)
echo "Adding Desktop Widget (Desklet)..."
# Format is 'uuid:instance_id:x:y'
gsettings set org.cinnamon enabled-desklets "['clock@cinnamon.org:1:800:100', 'launcher@cinnamon.org:2:800:300']"

# 3. Create a Custom Bespoke Terminal Prompt for 'abdallah'
echo "Configuring bespoke OS Terminal Prompt..."
cat << 'EOF' >> "$HOME/.bashrc"

# Ethereal Architect Custom Prompt
export PS1="\[\033[38;5;111m\]╭─ \[\033[38;5;14m\]\u\[\033[0m\]@\[\033[38;5;13m\]EtherealOS \[\033[38;5;220m\]\w\n\[\033[38;5;111m\]╰─ ⚡ \[\033[0m\]"
EOF

# 4. Hide generic Desktop Icons (like Computer, Home, Trash) to make it look clean like macOS
gsettings set org.nemo.desktop computer-icon-visible false
gsettings set org.nemo.desktop home-icon-visible false
gsettings set org.nemo.desktop trash-icon-visible false
gsettings set org.nemo.desktop volumes-visible false
gsettings set org.nemo.desktop network-icon-visible false

# 5. Make sure the window buttons are consistently styled (Mac style on left or Win style on right)
# Let's set Windows 11 style (Right side, minimize, maximize, close)
gsettings set org.cinnamon.desktop.wm.preferences button-layout ':minimize,maximize,close'

echo "✅ Pro Upgrade Complete!"
echo "Please restart Cinnamon or open a new terminal to see the changes."
