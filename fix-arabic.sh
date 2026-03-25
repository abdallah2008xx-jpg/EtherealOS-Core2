#!/bin/bash
# Fix Arabic fonts - use clean simple Noto Sans Arabic instead of decorative fonts

echo "=== Fixing Arabic Fonts ==="

# 1. Remove decorative/calligraphic Arabic fonts
emerge --unmerge -q media-fonts/kacst-fonts 2>/dev/null

# 2. Create fontconfig to force simple clean Arabic font (Noto Sans Arabic)
mkdir -p /etc/fonts/conf.d
mkdir -p /home/abdallah/.config/fontconfig

# System-wide fontconfig: prefer Noto Sans Arabic for Arabic script
cat > /etc/fonts/local.conf << 'FONTCONF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <!-- Force simple clean Arabic font globally -->
  
  <!-- Set Noto Sans Arabic as the preferred Arabic font -->
  <match>
    <test name="lang" compare="contains">
      <string>ar</string>
    </test>
    <edit name="family" mode="prepend" binding="strong">
      <string>Noto Sans Arabic</string>
    </edit>
  </match>

  <!-- Fallback: any Arabic text should use Noto Sans Arabic -->
  <match target="pattern">
    <test qual="any" name="family">
      <string>serif</string>
    </test>
    <edit name="family" mode="prepend" binding="strong">
      <string>Noto Sans Arabic</string>
    </edit>
  </match>

  <match target="pattern">
    <test qual="any" name="family">
      <string>sans-serif</string>
    </test>
    <edit name="family" mode="prepend" binding="strong">
      <string>Noto Sans Arabic</string>
    </edit>
  </match>

  <match target="pattern">
    <test qual="any" name="family">
      <string>monospace</string>
    </test>
    <edit name="family" mode="prepend" binding="strong">
      <string>Noto Sans Arabic</string>
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
      <pattern><patelt name="family"><string>Noto Kufi Arabic</string></patelt></pattern>
      <pattern><patelt name="family"><string>Noto Naskh Arabic</string></patelt></pattern>
      <pattern><patelt name="family"><string>Noto Nastaliq Urdu</string></patelt></pattern>
    </rejectfont>
  </selectfont>

</fontconfig>
FONTCONF

# 3. Same for user-level
cp /etc/fonts/local.conf /home/abdallah/.config/fontconfig/fonts.conf
chown abdallah:abdallah /home/abdallah/.config/fontconfig/fonts.conf

# 4. Rebuild font cache
fc-cache -f -v

# 5. Fix keyboard layout - remove Arabic keyboard, keep only US
sudo -u abdallah DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u abdallah)/bus" gsettings set org.gnome.libgnome-desktop.keyboard sources "[('xkb', 'us')]"
sudo -u abdallah DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u abdallah)/bus" gsettings set org.cinnamon.desktop.input-sources sources "[('xkb', 'us')]"

# 6. Kill gnome-terminal-server so it restarts with new font config
killall gnome-terminal-server 2>/dev/null

echo ""
echo "=== Done! Arabic fonts are now clean and simple (Noto Sans Arabic) ==="
echo "=== Restart Cinnamon to apply everywhere ==="
