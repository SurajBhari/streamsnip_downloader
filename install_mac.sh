#!/bin/bash
# ----------------------------------------
# Bootstrapper for macOS
# Ensures Python3, pip, ffmpeg, and yt-dlp are installed
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

# Upgrade pip and install required packages
info "Installing/Upgrading yt-dlp, requests, colorama..."
pip3 install --upgrade pip
pip3 install --upgrade yt-dlp requests colorama

# Download latest CLI script
CLI_FILE="$(dirname "$0")/streamsnip_cli.py"
info "Downloading latest streamsnip_cli.py from GitHub..."
curl -sSfL "https://raw.githubusercontent.com/surajbhari/streamsnip_downloader/main/streamsnip_cli.py" -o "$CLI_FILE"

# Run CLI
info "Launching StreamSnip CLI..."
python3 "$CLI_FILE"
