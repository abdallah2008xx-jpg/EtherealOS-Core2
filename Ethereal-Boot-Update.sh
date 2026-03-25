#!/bin/bash
# ==========================================================
# EtherealOS - Self-Healing Update System v5
# Boots automatically, no terminal, no typing needed
# ==========================================================

UPDATE_DIR="$HOME/ethereal-update"
REPO_URL="https://github.com/abdallah2008xx-jpg/EtherealOS-Core2.git"
LOG_FILE="$UPDATE_DIR/update.log"

# Create update directory if missing
mkdir -p "$UPDATE_DIR"

# Log function
log_msg() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log_msg "Starting EtherealOS Self-Healing Update"

# Check if zenity is available for GUI
if ! command -v zenity >/dev/null 2>&1; then
    log_msg "ERROR: zenity not found"
    exit 1
fi

# Function to show progress dialog
show_progress() {
    (
        echo "10"; sleep 0.3
        echo "# Checking system..."; sleep 0.5
        echo "30"; sleep 0.3
        echo "# $1"; sleep 0.5
        echo "60"; sleep 0.3
        echo "# $2"; sleep 0.5
        echo "100"
    ) | zenity --progress --title="EtherealOS Update" --text="Initializing..." --percentage=0 --auto-close --width=300 --no-cancel 2>/dev/null
}

# Function to show error
show_error() {
    zenity --error --title="EtherealOS Update" --text="$1" --width=400 2>/dev/null
    log_msg "ERROR: $1"
}

# Function to show success
show_success() {
    zenity --info --title="EtherealOS Update" --text="$1" --width=350 2>/dev/null
    log_msg "SUCCESS: $1"
}

# STEP 1: Check internet
cd "$UPDATE_DIR" || exit 1

if ! ping -c 1 -W 3 github.com >/dev/null 2>&1; then
    show_error "❌ No internet connection!\n\nPlease connect to internet and try again."
    exit 1
fi

log_msg "Internet connection OK"

# STEP 2: Get latest files (background with progress)
(
    # Clean old corrupted files
    if [ -d ".git" ]; then
        if ! git status >/dev/null 2>&1; then
            log_msg "Cleaning corrupted git repo"
            rm -rf .git ./* 2>/dev/null
        fi
    fi
    
    # Clone fresh if needed
    if [ ! -d ".git" ]; then
        log_msg "Cloning fresh repository"
        rm -rf ./* 2>/dev/null
        git clone --depth 1 "$REPO_URL" . 2>/dev/null
    else
        log_msg "Pulling latest updates"
        git pull origin main 2>/dev/null || git reset --hard origin/main 2>/dev/null
    fi
) &

# Show progress while downloading
show_progress "Downloading updates..." "Almost done..."
wait

log_msg "Download complete"

# STEP 3: Verify Update Manager exists
if [ ! -f "Ethereal-Update-Manager.py" ]; then
    log_msg "CRITICAL: Update Manager not found after download"
    show_error "❌ Update failed!\n\nCould not download Update Manager.\nPlease check your connection."
    exit 1
fi

# STEP 4: Make everything executable
chmod +x *.sh 2>/dev/null
chmod +x *.py 2>/dev/null

log_msg "All files ready"

# STEP 5: Launch Update Manager silently
log_msg "Launching Update Manager"
notify-send "🪐 EtherealOS" "Update system ready!" -i system-software-update 2>/dev/null &

# Run the actual update manager
exec python3 Ethereal-Update-Manager.py
