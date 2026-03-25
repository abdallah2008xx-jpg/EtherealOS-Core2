#!/bin/bash
# ==========================================================
# EtherealOS Modular Update Engine v5.0
# ==========================================================

cd "$(dirname "$0")"
REPO_DIR="$(pwd)"

# ─── FUNCTIONS ───

fix_browser() {
    echo "10"; echo "# 🦊 Configuring Firefox profile..."
    mkdir -p "$HOME/.mozilla/firefox/ethereal.default-release"
    if [ ! -f "$HOME/.mozilla/firefox/profiles.ini" ]; then
        cat > "$HOME/.mozilla/firefox/profiles.ini" << 'PROF'
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
}

check_internet() {
    echo "15"; echo "# 📶 Checking Internet Connection..."
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "Error: No internet connection. Update aborted." >&2
        return 1
    fi
}

verify_env() {
    echo "20"; echo "# ⚙️ Verifying System Environment..."
    if [ "$(id -u)" -eq 0 ]; then
        echo "Error: Please do not run this as root directly. Use regular user." >&2
        return 1
    fi
    if ! command -v git >/dev/null 2>&1; then
        echo "Error: Git is missing. Essential for updates." >&2
        return 1
    fi
}

pull_updates() {
    echo "30"; echo "# ⬇️ Downloading latest patches..."
    if ! git pull origin main 2>&1; then
        echo "Error: Failed to pull updates from GitHub." >&2
        return 1
    fi
}

install_scripts() {
    echo "45"; echo "# 🔧 Installing System Scripts to /usr/local/bin..."
    sudo cp "$REPO_DIR"/Ethereal-*.sh /usr/local/bin/ 2>/dev/null
    sudo cp "$REPO_DIR"/*.py /usr/local/bin/ 2>/dev/null
    sudo chmod +x /usr/local/bin/Ethereal-* 2>/dev/null
    sudo chmod +x /usr/local/bin/*.py 2>/dev/null
}

clean_desktop() {
    echo "55"; echo "# 🧹 Deep Cleaning Desktop Launchers..."
    for file in "$HOME/Desktop"/*.desktop; do
        if [ -f "$file" ]; then
            case "$(basename "$file")" in
                *Ethereal*|*Boost*|*Store*|*Snapshot*|*Update*|*GameMode*|*Repair*|*Optimizer*|*Hardware*)
                    rm -f "$file" 2>/dev/null
                    ;;
            esac
            if grep -q "Name=.*\(Ethereal\|Boost\|Store\)" "$file" 2>/dev/null; then
                rm -f "$file" 2>/dev/null
            fi
        fi
    done
}

deploy_desktop() {
    echo "65"; echo "# 📂 Deploying Desktop Icons..."
    mkdir -p "$HOME/Desktop"
    find "$REPO_DIR" -maxdepth 1 -name "*.desktop" ! -name "*-Autostart.desktop" -exec cp {} "$HOME/Desktop/" \;
    sed -i "s|/home/abdallah|$HOME|g" "$HOME/Desktop"/*.desktop 2>/dev/null
    chmod +x "$HOME/Desktop"/*.desktop 2>/dev/null
    
    echo "70"; echo "# 🔐 Marking launchers as trusted..."
    for file in "$HOME/Desktop"/*.desktop; do
        if [ -f "$file" ]; then
            gio set "$file" metadata::trusted true 2>/dev/null || true
            chmod +x "$file" 2>/dev/null || true
        fi
    done
}

update_icons_fonts() {
    echo "80"; echo "# 🎨 Updating Icons & Fonts..."
    mkdir -p "$HOME/.local/share/icons/ethereal"
    cp "$REPO_DIR"/icons/*.svg "$HOME/.local/share/icons/ethereal/" 2>/dev/null
    bash "$REPO_DIR"/install-papirus-icons.sh 2>/dev/null || true
    bash "$REPO_DIR"/fix-arabic.sh > /dev/null 2>&1
}

final_polish() {
    echo "90"; echo "# 🛡️ Finalizing System Polish..."
    bash "$REPO_DIR"/install-appimagelauncher.sh > /dev/null 2>&1
    bash "$REPO_DIR"/Ethereal-Final-Polish.sh > /dev/null 2>&1
    bash apply-theme.sh > /dev/null 2>&1
}

# ─── DISPATCHER ───

case "$1" in
    --browser) fix_browser ;;
    --network) check_internet ;;
    --env) verify_env ;;
    --pull) pull_updates ;;
    --scripts) install_scripts ;;
    --clean) clean_desktop ;;
    --deploy) deploy_desktop ;;
    --icons) update_icons_fonts ;;
    --polish) final_polish ;;
    --full)
        (
        fix_browser
        check_internet
        verify_env
        pull_updates
        install_scripts
        clean_desktop
        deploy_desktop
        update_icons_fonts
        final_polish
        echo "100"; echo "# ✨ Update Complete!"
        ) | zenity --progress --title="🪐 EtherealOS Update" --auto-close --auto-kill --width=400 2>/dev/null
        ;;
    *)
        echo "Usage: $0 [all|--browser|--network|--env|--pull|--scripts|--clean|--deploy|--icons|--polish|--full]"
        ;;
esac
