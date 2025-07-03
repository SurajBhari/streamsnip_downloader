@echo off
REM ----------------------------------------
REM Bootstrapper for Windows (Batch)
REM Ensures Python3, pip, ffmpeg, yt-dlp, Git, and runs CLI from current folder
REM ----------------------------------------

SETLOCAL ENABLEDELAYEDEXPANSION
SET SCRIPT_DIR=%~dp0
SET REPO_TEMP=%SCRIPT_DIR%streamsnip_downloader_tmp

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

:: Check for Git
where git >nul 2>&1
IF ERRORLEVEL 1 (
    echo [INFO] Git not found. Installing via Chocolatey...
    choco install git -y
    refreshenv
) ELSE (
    echo [INFO] Git found.
)

:: Upgrade pip and install yt-dlp, requests, colorama
echo [INFO] Installing/Upgrading yt-dlp, requests, colorama...
python -m pip install --upgrade pip
python -m pip install --upgrade yt-dlp requests colorama

:: Clone fresh repo into temporary folder
if exist "%REPO_TEMP%" (
    echo [INFO] Removing previous temp folder...
    rmdir /s /q "%REPO_TEMP%"
)
echo [INFO] Cloning latest streamsnip_downloader into temp folder...
git clone https://github.com/surajbhari/streamsnip_downloader.git "%REPO_TEMP%"

:: Copy contents to script directory
echo [INFO] Copying files to current directory...
echo %REPO_TEMP%

:: move %REPO_TEMP%\install_windows.bat %SCRIPT_DIR%\install_windows.bat.backup
xcopy /s /y "%REPO_TEMP%\*" "%SCRIPT_DIR%"
:: move everything else too
xcopy "%REPO_TEMP%\*" "%SCRIPT_DIR%" /E /H /Y /Q
rmdir /s /q "%REPO_TEMP%"

:: Launch CLI from current folder
echo [INFO] Launching StreamSnip CLI...
python "%SCRIPT_DIR%streamsnip_cli.py"

:: replace install_windows.bat with install_windows.bat.backup
if exist "%SCRIPT_DIR%\install_windows.bat.backup" (
    echo [INFO] Restoring original install_windows.bat...
    move /Y "%SCRIPT_DIR%\install_windows.bat.backup" "%SCRIPT_DIR%\install_windows.bat"
) else (
    echo [WARNING] Backup of install_windows.bat not found.
)


