@echo off
REM ============================================================================
REM GitHub CLI Credentials Import Script
REM ============================================================================
REM This script imports GitHub CLI authentication credentials from a backup
REM to restore authentication on a new Windows VM.
REM ============================================================================

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "CONFIG_DIR=%SCRIPT_DIR%..\config"

echo ============================================================================
echo GitHub CLI Credentials Import
echo ============================================================================
echo.
echo This script will import GitHub CLI authentication credentials
echo from a previous export to restore your authentication.
echo.

REM Check if GitHub CLI is installed
where gh >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: GitHub CLI (gh) is not installed or not in PATH.
    echo Please install GitHub CLI first using the main install script.
    pause
    exit /b 1
)

REM Check for backup file
set "BACKUP_FILE=%CONFIG_DIR%\gh-hosts-backup.yml"
if not exist "%BACKUP_FILE%" (
    echo ERROR: GitHub CLI credentials backup not found.
    echo Expected location: %BACKUP_FILE%
    echo.
    echo Make sure you have:
    echo 1. Exported credentials from another VM using export-gh-auth.bat
    echo 2. Copied the entire portable-dev-setup folder to this VM
    echo.
    pause
    exit /b 1
)

echo Found credentials backup: %BACKUP_FILE%
echo.

REM Check current authentication status
gh auth status >nul 2>&1
if %errorLevel% equ 0 (
    echo Current GitHub CLI authentication status:
    gh auth status
    echo.
    set /p "OVERWRITE=You are already authenticated. Overwrite existing credentials? (y/N): "
    if /i not "!OVERWRITE!"=="y" (
        echo Import cancelled.
        pause
        exit /b 0
    )
)

REM Create GitHub CLI config directory if it doesn't exist
set "GH_CONFIG_DIR=%APPDATA%\GitHub CLI"
if not exist "%GH_CONFIG_DIR%" mkdir "%GH_CONFIG_DIR%"

REM Import credentials
set "HOSTS_FILE=%GH_CONFIG_DIR%\hosts.yml"

echo Importing GitHub CLI credentials...
copy "%BACKUP_FILE%" "%HOSTS_FILE%" >nul
if %errorLevel% equ 0 (
    echo ✓ GitHub CLI credentials imported successfully.
    echo.
    
    REM Verify authentication
    echo Verifying authentication...
    gh auth status >nul 2>&1
    if %errorLevel% equ 0 (
        echo ✓ Authentication verified successfully!
        echo.
        echo Current authentication status:
        gh auth status
        echo.
        echo You can now use GitHub CLI and Git with GitHub repositories.
        echo.
    ) else (
        echo ⚠ Authentication import completed but verification failed.
        echo You may need to refresh your token or re-authenticate.
        echo Try running: gh auth refresh
        echo.
    )
) else (
    echo ERROR: Failed to import GitHub CLI credentials.
    echo Make sure the backup file is valid and accessible.
    pause
    exit /b 1
)

echo Import completed successfully!
echo.
pause
