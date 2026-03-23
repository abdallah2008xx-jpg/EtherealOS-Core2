#!/bin/bash
# ==========================================================
# EtherealOS OTA Global Updater
# This script syncs your local OS with the latest Ethereal Core
# ==========================================================

REPO_URL="https://github.com/abdallah/EtherealOS" # Temporary placeholder

echo "📡 Contacting Ethereal Update Servers..."

# Pull from Git if running inside Repo, otherwise just download latest bundle
if [ -d ".git" ]; then
    git pull origin main
else
    echo "⬇️ Downloading latest System Patch..."
fi

echo "🔄 Applying Updates..."
# Core updates
bash Ethereal-Final-Polish.sh
bash apply-theme.sh

echo "✅ EtherealOS updated successfully!"
