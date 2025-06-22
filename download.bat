@echo off
REM ============================================================================
REM Automatic Installer Download Launcher
REM ============================================================================
REM This script launches the PowerShell download script to automatically
REM download all required installer files from official sources.
REM ============================================================================

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "SCRIPTS_DIR=%SCRIPT_DIR%scripts"
set "INSTALLERS_DIR=%SCRIPT_DIR%installers"
set "LOGS_DIR=%SCRIPT_DIR%logs"
set "DOWNLOAD_SCRIPT=%SCRIPTS_DIR%\download-installers.ps1"

echo ============================================================================
echo Portable Windows Dev Setup - Automatic Installer Download
echo ============================================================================
echo.
echo This script will automatically download the required installer files:
echo - Node.js LTS (MSI installer)
echo - Rust (rustup-init.exe)
echo - Git for Windows (64-bit installer)
echo - GitHub CLI (MSI installer)
echo - Visual Studio Code (User installer)
echo.
echo Total download size: ~200 MB
echo.

REM Create directories if they don't exist
if not exist "%SCRIPTS_DIR%" mkdir "%SCRIPTS_DIR%"
if not exist "%INSTALLERS_DIR%" mkdir "%INSTALLERS_DIR%"
if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%"

REM Check if download script exists
if not exist "%DOWNLOAD_SCRIPT%" (
    echo ERROR: Download script not found at: %DOWNLOAD_SCRIPT%
    echo Please ensure the scripts folder is present.
    pause
    exit /b 1
)

REM Set log file with timestamp (avoid colons in filename)
set "timestamp=%RANDOM%"
if not "%timestamp%"=="" (
    set "LOG_FILE=%LOGS_DIR%\download_%timestamp%.log"
) else (
    set "LOG_FILE=%LOGS_DIR%\download.log"
)

echo Log file: %LOG_FILE%
echo.

REM Check internet connectivity
echo Checking internet connectivity...
ping -n 1 8.8.8.8 >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: No internet connection detected.
    echo Please check your network connection and try again.
    echo.
    echo You can also download installers manually:
    echo See DOWNLOAD-LINKS.md for instructions.
    pause
    exit /b 1
)

echo ✓ Internet connection verified
echo.

REM Ask for confirmation
set /p "PROCEED=Do you want to download the installer files? (Y/n): "
if /i "%PROCEED%"=="n" (
    echo Download cancelled.
    pause
    exit /b 0
)

REM Ask about force re-download
set /p "FORCE=Re-download existing files? (y/N): "

REM Set PowerShell execution policy
echo Setting PowerShell execution policy...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force" 2>&1

REM Run download script
echo.
echo Starting download process...
echo ============================================================================

if /i "%FORCE%"=="y" (
    powershell -ExecutionPolicy Bypass -File "%DOWNLOAD_SCRIPT%" -LogFile "%LOG_FILE%" -InstallersDir "%INSTALLERS_DIR%" -Force
) else (
    powershell -ExecutionPolicy Bypass -File "%DOWNLOAD_SCRIPT%" -LogFile "%LOG_FILE%" -InstallersDir "%INSTALLERS_DIR%"
)

if %errorLevel% neq 0 (
    echo.
    echo ============================================================================
    echo ERROR: Download process failed. Check log file for details.
    echo Log file: %LOG_FILE%
    echo.
    echo Troubleshooting:
    echo 1. Check your internet connection
    echo 2. Try running as administrator
    echo 3. Check if antivirus is blocking downloads
    echo 4. Download installers manually (see DOWNLOAD-LINKS.md)
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================================
echo Download completed successfully!
echo.
echo Next steps:
echo 1. Run install.bat to begin the installation process
echo 2. Or run verify.bat after installation to check everything works
echo.
echo All installer files are now available in the installers\ folder.
echo ============================================================================
echo.
pause
