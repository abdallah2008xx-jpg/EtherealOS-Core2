#!/bin/bash
# ==========================================================
# EtherealOS - Smart Browser Launcher
# Ensures the profile exists before launching Firefox
# ==========================================================

PROFILE_DIR="/home/abdallah/.mozilla/firefox/ethereal.default-release"
PROFILES_INI="/home/abdallah/.mozilla/firefox/profiles.ini"
INSTALLS_INI="/home/abdallah/.mozilla/firefox/installs.ini"

# Ensure directories exist
mkdir -p "$PROFILE_DIR"

# Ensure profiles.ini is correct
if [ ! -f "$PROFILES_INI" ]; then
    cat > "$PROFILES_INI" << 'PROF'
[Install4F96D1932A9F858E]
Default=ethereal.default-release
Locked=1

[General]
StartWithLastProfile=1
Version=2

[Profile0]
Name=default-release
IsRelative=1
Path=ethereal.default-release
Default=1
PROF
fi

# Ensure installs.ini is correct
if [ ! -f "$INSTALLS_INI" ]; then
    cat > "$INSTALLS_INI" << 'INST'
[4F96D1932A9F858E]
Default=ethereal.default-release
Locked=1
INST
fi

# Fix permissions silently
chown -R abdallah:abdallah /home/abdallah/.mozilla 2>/dev/null

# Launch Firefox (try firefox-bin first, then firefox)
if command -v firefox-bin >/dev/null 2>&1; then
    exec firefox-bin "$@"
elif command -v firefox >/dev/null 2>&1; then
    exec firefox "$@"
else
    # Fallback if somehow not in PATH
    if [ -x "/usr/bin/firefox-bin" ]; then
        exec /usr/bin/firefox-bin "$@"
    elif [ -x "/usr/bin/firefox" ]; then
        exec /usr/bin/firefox "$@"
    else
        zenity --error --text="Firefox could not be found on your system.\nPlease run Ultimate Repair." --title="Error" 2>/dev/null
    fi
fi
