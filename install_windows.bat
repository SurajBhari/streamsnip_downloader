@echo off
setlocal EnableDelayedExpansion
color 0A

echo ================================
echo   StreamSnip Downloader Setup
echo ================================

set "REPO_URL=https://github.com/surajbhari/streamsnip_downloader"
set "NEEDS_CHOCOLATEY=0"

REM --- Check if Python is installed ---
where python >nul 2>&1
if errorlevel 1 (
    echo [~] Python not found and will be installed.
    set "NEEDS_CHOCOLATEY=1"
) else (
    echo [OK] Python is installed.
)

REM --- Check if Git is installed ---
where git >nul 2>&1
if errorlevel 1 (
    echo [~] Git not found and will be installed.
    set "NEEDS_CHOCOLATEY=1"
) else (
    echo [OK] Git is installed.
)

REM --- Check if FFmpeg is installed ---
where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo [~] FFmpeg not found and will be installed.
    set "NEEDS_CHOCOLATEY=1"
) else (
    echo [OK] FFmpeg is installed.
)

REM --- Install Chocolatey and dependencies if needed ---
if "%NEEDS_CHOCOLATEY%"=="1" (
    where choco >nul 2>&1
    if errorlevel 1 (
        echo [!] Installing Chocolatey...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
        call refreshenv
    )
    echo [~] Installing missing tools...
    where python >nul 2>&1 || choco install python -y
    where git >nul 2>&1 || choco install git -y
    where ffmpeg >nul 2>&1 || choco install ffmpeg -y
)

REM --- Install Python packages ---
echo [~] Installing/updating Python packages...
pip install --upgrade yt-dlp requests colorama

REM --- Run StreamSnip CLI ---
echo ================================
echo     Starting StreamSnip CLI
echo ================================
python streamsnip_cli.py

echo.
echo All done! Press any key to close this window.
pause >nul