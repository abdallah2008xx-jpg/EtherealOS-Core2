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

echo "5. Reloading Window Manager..."
nohup cinnamon --replace >/dev/null 2>&1 &

echo "EtherealOS Final Polish Complete!"
