@echo off
setlocal EnableDelayedExpansion
color 0A

echo ================================
echo   StreamSnip Downloader Setup
echo ================================

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

REM --- Check if Chocolatey is installed ---
where choco >nul 2>&1
if errorlevel 1 (
    echo [!] Chocolatey is not installed. Installing now...
    powershell -NoProfile -Command ^
        "(New-Object Net.WebClient).DownloadFile('https://community.chocolatey.org/install.ps1','%TEMP%\choco.ps1')"
    powershell -NoProfile -ExecutionPolicy Bypass -File "%TEMP%\choco.ps1"
    echo [~] Chocolatey installed successfully.
    echo [>] Restarting script...
    start "" "%~f0"
    exit /b
)

REM --- Install missing tools via Chocolatey ---
if "!NEEDS_CHOCOLATEY!"=="1" (
    echo [~] Installing missing dependencies via Chocolatey...

    where python >nul 2>&1
    if errorlevel 1 (
        echo Installing Python...
        choco install python -y
    )

    where git >nul 2>&1
    if errorlevel 1 (
        echo Installing Git...
        choco install git -y
    )

    where ffmpeg >nul 2>&1
    if errorlevel 1 (
        echo Installing FFmpeg...
        choco install ffmpeg -y
    )
)

REM --- Install Python packages ---
echo [~] Installing/updating Python packages...
pip install --upgrade yt-dlp requests colorama

REM --- Git repo check ---
echo [~] Checking Git repository...
set "REPO_URL=https://github.com/surajbhari/streamsnip_downloader"

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo [~] Not a Git repository. Initializing fresh repo...
    git init
    git remote add origin %REPO_URL%
    git fetch origin
    git reset --hard origin/main
) else (
    for /f "delims=" %%i in ('git config --get remote.origin.url') do set REMOTE_URL=%%i
    if /i "!REMOTE_URL!"=="%REPO_URL%" (
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

echo ================================
echo     Starting StreamSnip CLI
echo ================================
python streamsnip_cli.py

:end
echo.
echo All done! Press any key to close this window.
pause >nul
