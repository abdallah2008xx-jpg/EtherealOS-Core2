#!/bin/bash
# ==========================================================
# EtherealOS - Silent GUI Auto-Update v4
# No terminal needed - Pure GUI experience
# ==========================================================

UPDATE_DIR="$HOME/ethereal-update"
REPO_URL="https://github.com/abdallah2008xx-jpg/EtherealOS-Core2.git"
LAUNCHER_URL="https://raw.githubusercontent.com/abdallah2008xx-jpg/EtherealOS-Core2/main/Ethereal-Update-Launcher.sh"
MANAGER_URL="https://raw.githubusercontent.com/abdallah2008xx-jpg/EtherealOS-Core2/main/Ethereal-Update-Manager.py"

# Show startup notification
if command -v notify-send >/dev/null 2>&1; then
    notify-send "🪐 EtherealOS" "Checking for updates..." -i software-update-available 2>/dev/null &
fi

# Function to show error dialog
show_error() {
    zenity --error --title="EtherealOS Update" --text="$1" --width=400 2>/dev/null
    exit 1
}

# Function to show progress
show_progress() {
    (
        echo "10"; sleep 0.5
        echo "# $1"; sleep 0.5
        echo "50"; sleep 0.5
        echo "# $2"; sleep 0.5
        echo "100"
    ) | zenity --progress --title="EtherealOS Update" --text="Starting..." --percentage=0 --auto-close --width=350 --no-cancel 2>/dev/null
}

# Function to download files directly
download_file() {
    local url="$1"
    local output="$2"
    
    if command -v wget >/dev/null 2>&1; then
        wget -q "$url" -O "$output" 2>/dev/null
    elif command -v curl >/dev/null 2>&1; then
        curl -sL "$url" -o "$output" 2>/dev/null
    else
        return 1
    fi
    [ -f "$output" ]
}

# STEP 1: Prepare directory
mkdir -p "$UPDATE_DIR"
cd "$UPDATE_DIR" || show_error "Cannot access update directory"

# STEP 2: Check internet silently
if ! ping -c 1 -W 3 github.com >/dev/null 2>&1; then
    show_error "❌ No internet connection!\n\nPlease connect to the internet and try again."
fi

# STEP 3: Get files (silent background process)
(
    # Try git first
    GIT_WORKS=0
    if command -v git >/dev/null 2>&1; then
        if [ -d ".git" ]; then
            git status >/dev/null 2>&1 && GIT_WORKS=1
        fi
        
        if [ $GIT_WORKS -eq 0 ]; then
            rm -rf .git ./* 2>/dev/null
            git clone --depth 1 "$REPO_URL" . 2>/dev/null && GIT_WORKS=1
        else
            git pull origin main 2>/dev/null || git reset --hard origin/main 2>/dev/null
        fi
    fi
    
    # Fallback to direct download
    if [ $GIT_WORKS -eq 0 ]; then
        rm -rf ./* 2>/dev/null
        download_file "$LAUNCHER_URL" "Ethereal-Update-Launcher.sh"
        download_file "$MANAGER_URL" "Ethereal-Update-Manager.py"
    fi
    
    # Make executable
    chmod +x *.sh 2>/dev/null
) &

# Show progress while downloading
zenity --progress --title="EtherealOS Update" --text="📦 Downloading latest updates..." --pulsate --auto-close --width=350 --no-cancel 2>/dev/null
wait

# STEP 4: Verify files
if [ ! -f "Ethereal-Update-Manager.py" ]; then
    # Last resort - direct download
    download_file "$MANAGER_URL" "Ethereal-Update-Manager.py" || \
    show_error "❌ Failed to download Update Manager!\n\nPlease check your internet connection."
fi

if [ ! -f "Ethereal-Update-Launcher.sh" ]; then
    download_file "$LAUNCHER_URL" "Ethereal-Update-Launcher.sh"
fi

chmod +x *.sh 2>/dev/null

# STEP 5: Launch Update Manager (GUI mode)
if command -v notify-send >/dev/null 2>&1; then
    notify-send "🪐 EtherealOS" "Launching Update Center..." -i system-software-update 2>/dev/null &
fi

# Run the GUI
exec python3 Ethereal-Update-Manager.py
