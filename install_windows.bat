:: install.bat
@echo off
REM ----------------------------------------
REM Bootstrapper for Windows (Batch)
REM Ensures Python3, pip, ffmpeg, and yt-dlp are installed
REM Then runs the Python CLI
REM ----------------------------------------

:: Check for Python
where python >nul 2>&1
IF ERRORLEVEL 1 (
    echo [INFO] Python not found. Installing via Chocolatey...
    where choco >nul 2>&1 || (
        echo [INFO] Chocolatey not found. Installing Chocolatey...
        @powershell -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
    )
    choco install python -y
    refreshenv
) ELSE (
    echo [INFO] Python found.
)

:: Check for ffmpeg
where ffmpeg >nul 2>&1
IF ERRORLEVEL 1 (
    echo [INFO] ffmpeg not found. Installing via Chocolatey...
    choco install ffmpeg -y
    refreshenv
) ELSE (
    echo [INFO] ffmpeg found.
)

:: Upgrade pip and install yt-dlp, requests, colorama
echo [INFO] Installing/Upgrading yt-dlp, requests, colorama...
python -m pip install --upgrade pip
python -m pip install --upgrade yt-dlp requests colorama

:: Download latest streamsnip_cli.py from GitHub
powershell -Command "Invoke-WebRequest -Uri https://raw.githubusercontent.com/surajbhari/streamsnip_downloader/main/streamsnip_cli.py -OutFile '%~dp0streamsnip_cli.py'"

:: Launch CLI
echo [INFO] Launching StreamSnip Downloader CLI...
python "%~dp0streamsnip_cli.py"

pause