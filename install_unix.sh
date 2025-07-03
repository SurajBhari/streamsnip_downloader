#!/bin/bash

echo "================================="
echo " StreamSnip Downloader Setup"
echo "================================="

# Helper to check if command exists
check_command() {
  command -v "$1" &> /dev/null
}

install_if_missing() {
  NAME=$1
  CMD=$2
  PACKAGE=$3

  if ! check_command "$CMD"; then
    echo "[~] $NAME not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y "$PACKAGE"
  else
    echo "[OK] $NAME is installed."
  fi
}

# Ensure apt is available
if ! check_command apt-get; then
  echo "[!] This script only works on Debian/Ubuntu systems with apt."
  exit 1
fi

# Install core system dependencies
install_if_missing "Python 3" "python3" "python3"
install_if_missing "pip3" "pip3" "python3-pip"
install_if_missing "Git" "git" "git"
install_if_missing "FFmpeg" "ffmpeg" "ffmpeg"

# Python packages
echo "[~] Installing/updating Python packages..."
pip3 install --upgrade yt-dlp requests colorama

# Git repo setup
REPO_URL="https://github.com/surajbhari/streamsnip_downloader"
FOLDER_NAME="streamsnip_downloader"

if [ -d .git ]; then
  CURRENT_URL=$(git config --get remote.origin.url)
  if [ "$CURRENT_URL" = "$REPO_URL" ]; then
    echo "[OK] Git remote is correct. Pulling updates..."
    git fetch origin
    git reset --hard origin/main
  else
    echo "[~] Git remote is incorrect. Reconfiguring..."
    rm -rf .git
    git init
    git remote add origin "$REPO_URL"
    git fetch origin
    git reset --hard origin/main
  fi
elif [ -d "$FOLDER_NAME/.git" ]; then
  echo "[OK] Found $FOLDER_NAME folder with Git. Pulling updates..."
  cd "$FOLDER_NAME" || exit
  git fetch origin
  git reset --hard origin/main
else
  echo "[~] Cloning the StreamSnip repo..."
  git clone "$REPO_URL"
  cd "$FOLDER_NAME" || exit
fi

echo "================================="
echo " Launching StreamSnip CLI"
echo "================================="

python3 streamsnip_cli.py
