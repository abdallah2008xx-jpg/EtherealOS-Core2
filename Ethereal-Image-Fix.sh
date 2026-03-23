#!/bin/bash
# ==========================================================
# EtherealOS Image Recognition & Thumbnail Fix
# Resolves missing JPG/PNG recognition, regenerates caches, 
# and sets default viewers.
# ==========================================================

echo "1. Refreshing GTK Image Loaders (GDK Pixbuf)..."
gdk-pixbuf-query-loaders --update-cache 2>/dev/null

echo "2. Refreshing System MIME and Icon Caches..."
update-mime-database /usr/share/mime 2>/dev/null
gtk-update-icon-cache -f /usr/share/icons/hicolor 2>/dev/null
update-desktop-database 2>/dev/null

echo "3. Forcing Nemo (File Manager) to generate and display thumbnails..."
gsettings set org.nemo.preferences show-image-thumbnails 'always'
gsettings set org.nemo.preferences thumbnail-limit 10485760

echo "4. Assigning Default Image Viewer..."
# Check if a native viewer exists, otherwise fallback to Firefox for guaranteed viewing!
if command -v xviewer &> /dev/null; then
    VIEWER="xviewer.desktop"
elif command -v eog &> /dev/null; then
    VIEWER="eog.desktop"
elif command -v feh &> /dev/null; then
    VIEWER="feh.desktop"
else
    # Firefox is incredibly reliable for viewing images if no native C app exists
    VIEWER="firefox.desktop"
fi

xdg-mime default $VIEWER image/jpeg
xdg-mime default $VIEWER image/png
xdg-mime default $VIEWER image/gif
xdg-mime default $VIEWER image/webp

# Create a custom mimeapps.list entry just in case
mkdir -p ~/.config
grep -q "image/jpeg" ~/.config/mimeapps.list 2>/dev/null || echo "image/jpeg=$VIEWER;" >> ~/.config/mimeapps.list
grep -q "image/png" ~/.config/mimeapps.list 2>/dev/null || echo "image/png=$VIEWER;" >> ~/.config/mimeapps.list

# Restart Nemo file manager to apply thumbnail settings instantly
nemo -q &> /dev/null
nohup nemo-desktop >/dev/null 2>&1 &

echo "Image formats (JPG/PNG) successfully registered and thumbnail generation enabled!"
