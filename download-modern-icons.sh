#!/bin/bash
# ==========================================================
# Download and Install Modern Icons (Fluent/WhiteSur)
# ==========================================================

set -e

echo "🎨 Downloading Modern Icon Theme..."

# Create directories
mkdir -p ~/.icons
mkdir -p ~/.local/share/icons
mkdir -p /tmp/icon-download
cd /tmp/icon-download

# Download Fluent Icon Theme (Windows 11 style)
echo "⬇️ Downloading Fluent Icon Theme..."
wget -q --show-progress "https://github.com/vinceliuice/Fluent-icon-theme/releases/download/2023-06-01/Fluent-icon-theme-2023-06-01.tar.xz" -O fluent.tar.xz 2>/dev/null || \
curl -L -o fluent.tar.xz "https://github.com/vinceliuice/Fluent-icon-theme/releases/download/2023-06-01/Fluent-icon-theme-2023-06-01.tar.xz" 2>/dev/null || {
    echo "⚠️ Direct download failed, trying alternative..."
}

if [ -f fluent.tar.xz ]; then
    echo "📦 Extracting Fluent icons..."
    tar -xf fluent.tar.xz
    
    # Copy Fluent icons
    if [ -d "Fluent" ]; then
        cp -r Fluent ~/.icons/ 2>/dev/null || true
        cp -r Fluent ~/.local/share/icons/ 2>/dev/null || true
        echo "✅ Fluent icons installed"
    fi
    
    if [ -d "Fluent-dark" ]; then
        cp -r Fluent-dark ~/.icons/ 2>/dev/null || true
        cp -r Fluent-dark ~/.local/share/icons/ 2>/dev/null || true
        echo "✅ Fluent-dark icons installed"
    fi
fi

# Download WhiteSur Icon Theme (macOS style - very beautiful)
echo "⬇️ Downloading WhiteSur Icon Theme..."
wget -q --show-progress "https://github.com/vinceliuice/WhiteSur-icon-theme/releases/download/2023-06-01/WhiteSur-icon-theme-2023-06-01.tar.xz" -O whitesur.tar.xz 2>/dev/null || \
curl -L -o whitesur.tar.xz "https://github.com/vinceliuice/WhiteSur-icon-theme/releases/download/2023-06-01/WhiteSur-icon-theme-2023-06-01.tar.xz" 2>/dev/null || {
    echo "⚠️ WhiteSur download failed"
}

if [ -f whitesur.tar.xz ]; then
    echo "📦 Extracting WhiteSur icons..."
    tar -xf whitesur.tar.xz
    
    if [ -d "WhiteSur" ]; then
        cp -r WhiteSur ~/.icons/ 2>/dev/null || true
        cp -r WhiteSur ~/.local/share/icons/ 2>/dev/null || true
        echo "✅ WhiteSur icons installed"
    fi
    
    if [ -d "WhiteSur-dark" ]; then
        cp -r WhiteSur-dark ~/.icons/ 2>/dev/null || true
        cp -r WhiteSur-dark ~/.local/share/icons/ 2>/dev/null || true
        echo "✅ WhiteSur-dark icons installed"
    fi
fi

# Cleanup
cd /
rm -rf /tmp/icon-download

# Update icon cache
echo "🔄 Updating icon cache..."
for theme in ~/.icons/*/ ~/.local/share/icons/*/; do
    if [ -d "$theme" ]; then
        gtk-update-icon-cache -f "$theme" 2>/dev/null || true
    fi
done

echo "✅ Modern Icon Themes Ready!"
echo ""
echo "Available themes: Fluent, Fluent-dark, WhiteSur, WhiteSur-dark"
