@echo off
setlocal
color 0A

:: ==================================
::   StreamSnip Downloader Setup
:: ==================================
echo ==================================
echo   StreamSnip Downloader Setup
echo ==================================

:: --- Check dependencies ---
set NEEDS_CHOCOLATEY=0

where python >nul 2>&1
if errorlevel 1 (
    echo [~] Python not found and will be installed.
    set NEEDS_CHOCOLATEY=1
) else (
    echo [OK] Python is installed.
)

where git >nul 2>&1
if errorlevel 1 (
    echo [~] Git not found and will be installed.
    set NEEDS_CHOCOLATEY=1
) else (
    echo [OK] Git is installed.
)

where ffmpeg >nul 2>&1
if errorlevel 1 (
    echo [~] FFmpeg not found and will be installed.
    set NEEDS_CHOCOLATEY=1
) else (
    echo [OK] FFmpeg is installed.
)

:: --- Install Chocolatey if needed ---
if "%NEEDS_CHOCOLATEY%"=="1" (
    where choco >nul 2>&1
    if errorlevel 1 (
        echo.
        echo [!] Some required tools are missing.
        echo [~] Installing Chocolatey...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest https://community.chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression"
        echo [>] Chocolatey installed. Please close and reopen this script to refresh PATH.
        pause
        exit /b
    )
)

:: --- Install missing tools ---
if "%NEEDS_CHOCOLATEY%"=="1" (
    echo [~] Installing missing dependencies via Chocolatey...
    where python >nul 2>&1 || choco install python -y
    where git >nul 2>&1 || choco install git -y
    where ffmpeg >nul 2>&1 || choco install ffmpeg -y
)

:: --- Install Python packages ---
echo [~] Installing/updating Python packages...
pip install --upgrade yt-dlp requests colorama

:: --- Setup Git repository ---
echo [~] Checking Git repository...
set REPO_URL=https://github.com/surajbhari/streamsnip_downloader

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo [~] Not a Git repository. Initializing fresh repo...
    git init
    git remote add origin %REPO_URL%
    git fetch origin
    git reset --hard origin/main
) else (
    for /f "delims=" %%i in ('git config --get remote.origin.url') do set REMOTE_URL=%%i
    if /i "%REMOTE_URL%"=="%REPO_URL%" (
        echo [OK] Git remote is correct. Pulling updates...
        git fetch origin
        git reset --hard origin/main
    ) else (
        echo [~] Fixing incorrect Git remote...
        git remote remove origin
        git remote add origin %REPO_URL%
        git fetch origin
        git reset --hard origin/main
    )
)

:: --- Start StreamSnip CLI ---
echo ==================================
echo     Starting StreamSnip CLI
echo ==================================
python streamsnip_cli.py

echo.
echo All done! Press any key to close this window.
pause >nul