#!/bin/bash

echo "================================="
echo " StreamSnip Downloader Setup"
echo "================================="

MISSING_DEPS=0

# Function to check for command existence
check_command() {
  if ! command -v "$1" &> /dev/null; then
    return 1
  fi
  return 0
}

# --- Check Homebrew ---
if ! check_command brew; then
  echo "[~] Homebrew not found. Installing..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"  # For Apple Silicon
fi

# --- Check Python3 ---
if ! check_command python3; then
  echo "[~] Python3 not found. Installing with Homebrew..."
  brew install python
else
  echo "[OK] Python3 is installed."
fi

# --- Check Git ---
if ! check_command git; then
  echo "[~] Git not found. Installing with Homebrew..."
  brew install git
else
  echo "[OK] Git is installed."
fi

# --- Check FFmpeg ---
if ! check_command ffmpeg; then
  echo "[~] FFmpeg not found. Installing with Homebrew..."
  brew install ffmpeg
else
  echo "[OK] FFmpeg is installed."
fi

# --- Upgrade Python packages ---
echo "[~] Installing/updating Python packages..."
pip3 install --upgrade yt-dlp requests colorama

# --- Git repo check ---
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
