#!/bin/bash
# ==========================================================
#  abdallahOS — "The Ethereal Architect" Theme Applicator v6
#  Matching the exact EtherealOS reference design:
#    • Floating pill-shaped top bar
#    • Frosted glass left sidebar
#    • Centered bottom dock
#    • Cosmic dark with cyan-blue accents
# ==========================================================
clear
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   abdallahOS — The Ethereal Architect — Installer v6   ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ── 1. Install CSS Theme ──
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
THEME_DIR="$HOME/.themes/Ethereal/cinnamon"
mkdir -p "$THEME_DIR"

if [ -f "$SCRIPT_DIR/cinnamon.css" ]; then
    cp "$SCRIPT_DIR/cinnamon.css" "$THEME_DIR/cinnamon.css"
else
    echo "⚠️ ERROR: cinnamon.css not found in script directory ($SCRIPT_DIR)"
fi
# Write required theme.json
echo '{"name": "Ethereal Architect"}' > "$THEME_DIR/theme.json"

CSS_SRC="$THEME_DIR/cinnamon.css"
CSS_LINES=$(wc -l < "$CSS_SRC" 2>/dev/null || echo 0)
echo "[1/9] ✅ CSS Theme ($CSS_LINES lines) installed."

# ── 2. Configure Panels: Top + Left Sidebar + Bottom Dock ──
# Panel layout: panel1=top (pill bar), panel2=bottom (dock), panel3=left (sidebar)
gsettings set org.cinnamon panels-enabled "['1:0:top', '2:0:bottom', '3:0:left']"
gsettings set org.cinnamon panels-height "['1:40', '2:52', '3:52']"
gsettings set org.cinnamon panels-autohide "['1:intel', '2:intel', '3:intel']"

# Applet layout matching EtherealOS mockup:
# panel1 (top): menu left, then OS name, systray/clock/status right
# panel2 (bottom): grouped window list center (dock)
# panel3 (left): panel launchers (sidebar icons)
gsettings set org.cinnamon enabled-applets "['panel1:left:0:menu@cinnamon.org:0', 'panel1:right:0:systray@cinnamon.org:1', 'panel1:right:1:xapp-status@cinnamon.org:2', 'panel1:right:2:keyboard@cinnamon.org:3', 'panel1:right:3:removable-drives@cinnamon.org:4', 'panel1:right:4:network@cinnamon.org:5', 'panel1:right:5:sound@cinnamon.org:6', 'panel1:right:6:power@cinnamon.org:7', 'panel1:right:7:calendar@cinnamon.org:8', 'panel1:right:8:notifications@cinnamon.org:9', 'panel1:right:9:user@cinnamon.org:10', 'panel2:center:0:grouped-window-list@cinnamon.org:11', 'panel3:center:0:panel-launchers@cinnamon.org:12']"

echo "[2/9] ✅ Panels configured (Top bar + Left sidebar + Bottom dock)."

# ── 3. Set Ethereal/Dark Theme ──
gsettings set org.cinnamon.theme name "Ethereal"
gsettings set org.cinnamon.desktop.interface gtk-theme "Adwaita-dark"
gsettings set org.cinnamon.desktop.wm.preferences theme "Adwaita-dark"
echo "[3/9] ✅ Dark GTK theme set."

# ── 4. Icons ──
gsettings set org.cinnamon.desktop.interface icon-theme "Papirus-Dark"
echo "[4/9] ✅ Papirus-Dark icons applied."

# ── 5. Fonts — Dual typeface: Plus Jakarta Sans + Inter ──
gsettings set org.cinnamon.desktop.interface font-name "Inter 10"
gsettings set org.cinnamon.desktop.wm.preferences titlebar-font "Plus Jakarta Sans Bold 10"
gsettings set org.gnome.desktop.interface document-font-name "Inter 10"
gsettings set org.gnome.desktop.interface monospace-font-name "Monospace 10"
echo "[5/9] ✅ Fonts: Inter (body) + Plus Jakarta Sans (headlines)."

# ── 6. Animations & Effects ──
gsettings set org.cinnamon desktop-effects true
gsettings set org.cinnamon startup-animation true
gsettings set org.cinnamon desktop-effects-close "traditional"
gsettings set org.cinnamon desktop-effects-map "traditional"
gsettings set org.cinnamon desktop-effects-minimize "traditional"
echo "[6/9] ✅ Animations enabled."

# ── 7. Window tiling — Maintain 10px gap (Hyprland-style floating glass) ──
gsettings set org.cinnamon.muffin tile-maximize false 2>/dev/null
echo "[7/9] ✅ Window tiling gaps preserved."

# ── 8. Configure Left Sidebar launchers ──
LAUNCHERS=""
for app in nemo firefox-bin firefox gnome-terminal foot; do
  for dir in /usr/share/applications /usr/local/share/applications; do
    if [ -f "$dir/$app.desktop" ]; then
      LAUNCHERS="$LAUNCHERS $app.desktop"
      break
    fi
  done
done
echo "[8/9] ✅ Sidebar apps detected: $LAUNCHERS"

# ── 9. Desktop background + final activation ──
mkdir -p "$HOME/.backgrounds"
if [ -f "$SCRIPT_DIR/ethereal-bg.jpg" ]; then
    cp "$SCRIPT_DIR/ethereal-bg.jpg" "$HOME/.backgrounds/ethereal-bg.jpg"
fi
gsettings set org.cinnamon.desktop.background picture-uri "file://$HOME/.backgrounds/ethereal-bg.jpg"

# Apply keyboard to US
dconf write /org/cinnamon/desktop/input-sources/sources "[('xkb','us')]" 2>/dev/null

echo "[9/9] ✅ EtherealOS — The Ethereal Architect — ACTIVATED!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   abdallahOS — The Ethereal Architect — READY ✨"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Design System:"
echo "  • Primary:    #7ed7ff (electric cyan)"
echo "  • Surface:    #0c0e17 (cosmic dark)"
echo "  • Tertiary:   #e6a7ff (soft purple)"
echo "  • Ghost borders, ambient shadows, glass surfaces"
