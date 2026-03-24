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

echo "command -v neofetch >/dev/null 2>&1 && neofetch --source ~/.config/neofetch/ethereal.txt --ascii_colors 6 4" >> ~/.bashrc

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

echo "6. Reloading Window Manager..."
nohup cinnamon --replace >/dev/null 2>&1 &

echo "EtherealOS Final Polish Complete!"
