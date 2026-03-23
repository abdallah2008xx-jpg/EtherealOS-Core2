#!/bin/bash
# ==========================================================
# Ethereal Dock Fixer
# Removes shortcuts from the top panel, and forcefully pins
# Firefox, Nemo, and Terminal to the bottom dock.
# ==========================================================

# 1. Force top panel to strictly have only Menu and System Icons (remove panel-launchers forcefully)
gsettings set org.cinnamon enabled-applets "['panel1:left:0:menu@cinnamon.org:0', 'panel1:right:0:systray@cinnamon.org:1', 'panel1:right:1:xapp-status@cinnamon.org:2', 'panel1:right:2:keyboard@cinnamon.org:3', 'panel1:right:3:removable-drives@cinnamon.org:4', 'panel1:right:4:calendar@cinnamon.org:5', 'panel2:center:0:grouped-window-list@cinnamon.org:6', 'panel3:center:0:grouped-window-list@cinnamon.org:7']"

# 2. Modify the JSON config for the bottom dock (Instance 6)
CONFIG_DIR="$HOME/.cinnamon/configs/grouped-window-list@cinnamon.org"
mkdir -p "$CONFIG_DIR"
cat << 'EOF' > "$CONFIG_DIR/6.json"
{
    "pinned-apps": {
        "type": "generic",
        "value": [
            "nemo.desktop",
            "firefox-bin.desktop",
            "org.cinnamon.Terminal.desktop",
            "Welcome.desktop",
            "HardwareManager.desktop"
        ]
    }
}
EOF

# Restart cinnamon cleanly
nohup cinnamon --replace >/dev/null 2>&1 &
