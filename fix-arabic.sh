#!/bin/bash
# Fix Arabic fonts - use Modern Premium fonts (Cairo & Tajawal) + MS Fonts
# ==========================================================

echo "=== ✍️ Enhancing System Fonts (Arabic & English) ==="

# 1. Install Microsoft Core Fonts (Arial, Times New Roman, etc.)
echo "📦 Installing Microsoft Compatibility Fonts..."
emerge --ask=n --quiet media-fonts/corefonts 2>/dev/null || true

# 2. Remove old decorative/calligraphic Arabic fonts
echo "🧹 Removing legacy decorative fonts..."
emerge --unmerge -q media-fonts/kacst-fonts 2>/dev/null || true

# 3. Download Modern Premium Arabic Fonts (Cairo & Tajawal)
echo "📥 Downloading Cairo & Tajawal Fonts..."
mkdir -p /usr/share/fonts/google-fonts
FONT_DIR="/usr/share/fonts/google-fonts"

# Function to download and extract fonts
install_font() {
    local family=$1
    local url="https://fonts.google.com/download?family=${family}"
    wget -qO "/tmp/${family}.zip" "$url"
    unzip -q -o "/tmp/${family}.zip" -d "${FONT_DIR}/${family}"
    rm "/tmp/${family}.zip"
}

if [ ! -d "${FONT_DIR}/Cairo" ]; then
    install_font "Cairo"
fi
if [ ! -d "${FONT_DIR}/Tajawal" ]; then
    install_font "Tajawal"
fi

# 4. Create fontconfig to force Modern Arabic fonts
echo "⚙️ Configuring Font Priorities..."
TARGET_USER="${SUDO_USER:-$(whoami)}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

mkdir -p /etc/fonts/conf.d
mkdir -p "$TARGET_HOME/.config/fontconfig"

# System-wide fontconfig: prefer Cairo for Arabic script
cat > /etc/fonts/local.conf << 'FONTCONF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <!-- Force Premium Modern Arabic font globally -->
  
  <!-- Set Cairo as the preferred Arabic font -->
  <match>
    <test name="lang" compare="contains">
      <string>ar</string>
    </test>
    <edit name="family" mode="prepend" binding="strong">
      <string>Cairo</string>
      <string>Tajawal</string>
      <string>Noto Sans Arabic</string>
    </edit>
  </match>

  <!-- Fallback: any Arabic text should use Cairo -->
  <match target="pattern">
    <test qual="any" name="family">
      <string>serif</string>
    </test>
    <edit name="family" mode="prepend" binding="strong">
      <string>Cairo</string>
    </edit>
  </match>

  <match target="pattern">
    <test qual="any" name="family">
      <string>sans-serif</string>
    </test>
    <edit name="family" mode="prepend" binding="strong">
      <string>Cairo</string>
    </edit>
  </match>

  <match target="pattern">
    <test qual="any" name="family">
      <string>monospace</string>
    </test>
    <edit name="family" mode="prepend" binding="strong">
      <string>Cairo</string>
    </edit>
  </match>

  <!-- Block decorative/calligraphic Arabic fonts from being selected -->
  <selectfont>
    <rejectfont>
      <pattern><patelt name="family"><string>KacstArt</string></patelt></pattern>
      <pattern><patelt name="family"><string>KacstBook</string></patelt></pattern>
      <pattern><patelt name="family"><string>KacstDecorative</string></patelt></pattern>
      <pattern><patelt name="family"><string>KacstDigital</string></patelt></pattern>
      <pattern><patelt name="family"><string>KacstFarsi</string></patelt></pattern>
      <pattern><patelt name="family"><string>KacstLetter</string></patelt></pattern>
      <pattern><patelt name="family"><string>KacstNaskh</string></patelt></pattern>
      <pattern><patelt name="family"><string>KacstOffice</string></patelt></pattern>
      <pattern><patelt name="family"><string>KacstOne</string></patelt></pattern>
      <pattern><patelt name="family"><string>KacstPen</string></patelt></pattern>
      <pattern><patelt name="family"><string>KacstPoster</string></patelt></pattern>
      <pattern><patelt name="family"><string>KacstQurn</string></patelt></pattern>
      <pattern><patelt name="family"><string>KacstScreen</string></patelt></pattern>
      <pattern><patelt name="family"><string>KacstTitle</string></patelt></pattern>
      <pattern><patelt name="family"><string>KacstTitleL</string></patelt></pattern>
    </rejectfont>
  </selectfont>

</fontconfig>
FONTCONF

# 5. User-level sync
if [ -d "$TARGET_HOME/.config/fontconfig" ]; then
    cp /etc/fonts/local.conf "$TARGET_HOME/.config/fontconfig/fonts.conf"
    chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.config/fontconfig/fonts.conf"
fi

# 6. Rebuild font cache
fc-cache -f -v

# 7. Kill terminal to refresh
killall gnome-terminal-server 2>/dev/null

echo ""
echo "=== ✨ Done! Cairo & Tajawal are now the default Arabic fonts. ==="
echo "=== 🏢 Microsoft fonts (Arial/Times) are also installed. ==="
