#!/bin/bash
# ----------------------------------------
# Bootstrapper for macOS
# Ensures Python3, pip, ffmpeg, yt-dlp, and Git repo are ready
# Then runs the Python CLI
# ----------------------------------------

set -e

info() {
  echo -e "\033[1;34m[INFO]\033[0m $1"
}

error() {
  echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
}

# Check for Homebrew
if ! command -v brew >/dev/null 2>&1; then
  info "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  info "Homebrew found."
fi

# Ensure Python3
if ! command -v python3 >/dev/null 2>&1; then
  info "Installing Python3..."
  brew install python
else
  info "Python3 found."
fi

# Ensure ffmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
  info "Installing ffmpeg..."
  brew install ffmpeg
else
  info "ffmpeg found."
fi

# Ensure Git
if ! command -v git >/dev/null 2>&1; then
  info "Installing Git..."
  brew install git
else
  info "Git found."
fi

# Upgrade pip and install required packages
info "Installing/Upgrading yt-dlp, requests, colorama..."
pip3 install --upgrade pip
pip3 install --upgrade yt-dlp requests colorama

# Setup streamsnip_downloader repo
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

REPO_DIR="$SCRIPT_DIR/streamsnip_downloader"
if [ ! -d "$REPO_DIR/.git" ]; then
  if [ -d "$REPO_DIR" ]; then
    info "Cleaning up existing non-git directory..."
    rm -rf "$REPO_DIR"
  fi
  info "Cloning streamsnip_downloader into $REPO_DIR..."
  git clone https://github.com/surajbhari/streamsnip_downloader.git "$REPO_DIR"
else
  info "Git repo found. Pulling latest changes..."
  cd "$REPO_DIR"
  git reset --hard
  git pull origin main
fi

# Run CLI
info "Launching StreamSnip CLI..."
python3 "$REPO_DIR/streamsnip_cli.py"