@echo off
REM ============================================================================
REM Portable Windows Dev Setup Installation (Skip Node.js)
REM ============================================================================
REM This script runs the installation but skips Node.js since you already
REM have a working version installed.
REM ============================================================================

setlocal enabledelayedexpansion

set "SCRIPT_DIR=%~dp0"
set "SCRIPTS_DIR=%SCRIPT_DIR%scripts"
set "INSTALLERS_DIR=%SCRIPT_DIR%installers"
set "CONFIG_DIR=%SCRIPT_DIR%config"
set "LOGS_DIR=%SCRIPT_DIR%logs"

echo ============================================================================
echo Portable Windows Dev Setup Installation (Skip Node.js)
echo ============================================================================
echo.
echo This script will install:
echo - Rust (with Cargo)
echo - Git
echo - GitHub CLI
echo - Windows Build Tools
echo.
echo Node.js will be SKIPPED since you already have v22.16.0 installed.
echo.

REM Set log file
set "timestamp=%RANDOM%_%RANDOM%"
set "LOG_FILE=%LOGS_DIR%\install_skip_nodejs_%timestamp%.log"

REM Ensure logs directory exists
if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%"

echo Log file: %LOG_FILE%
echo.

pause

REM Set PowerShell execution policy
echo Setting PowerShell execution policy...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force" 2>&1
echo PowerShell execution policy set.
echo.

REM Skip Node.js - show current version
echo ============================================================================
echo Skipping Node.js (already installed)
echo ============================================================================
node --version 2>nul && (
    echo Current Node.js version: 
    node --version
    echo Current npm version:
    npm --version
    echo [OK] Node.js is ready to use.
) || (
    echo WARNING: Node.js not found in PATH. You may need to restart your terminal.
)
echo.

REM Install Rust
echo ============================================================================
echo Installing Rust...
echo ============================================================================
powershell -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\install-rust.ps1" -LogFile "%LOG_FILE%" -InstallersDir "%INSTALLERS_DIR%"
if %errorLevel% neq 0 (
    echo ERROR: Rust installation failed. Check log file for details.
    echo Log file: %LOG_FILE%
    pause
    exit /b 1
)
echo [OK] Rust installation completed.
echo.

REM Install Git
echo ============================================================================
echo Installing Git...
echo ============================================================================
powershell -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\install-git.ps1" -LogFile "%LOG_FILE%" -InstallersDir "%INSTALLERS_DIR%" -ConfigDir "%CONFIG_DIR%"
if %errorLevel% neq 0 (
    echo ERROR: Git installation failed. Check log file for details.
    echo Log file: %LOG_FILE%
    pause
    exit /b 1
)
echo [OK] Git installation completed.
echo.

REM Install GitHub CLI
echo ============================================================================
echo Installing GitHub CLI...
echo ============================================================================
powershell -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\install-github-cli.ps1" -LogFile "%LOG_FILE%" -InstallersDir "%INSTALLERS_DIR%" -ConfigDir "%CONFIG_DIR%"
if %errorLevel% neq 0 (
    echo ERROR: GitHub CLI installation failed. Check log file for details.
    echo Log file: %LOG_FILE%
    pause
    exit /b 1
)
echo [OK] GitHub CLI installation completed.
echo.

REM Install Windows Build Tools
echo ============================================================================
echo Installing Windows Build Tools...
echo ============================================================================
powershell -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\install-build-tools.ps1" -LogFile "%LOG_FILE%"
if %errorLevel% neq 0 (
    echo ERROR: Build tools installation failed. Check log file for details.
    echo Log file: %LOG_FILE%
    pause
    exit /b 1
)
echo [OK] Windows Build Tools installation completed.
echo.

echo ============================================================================
echo Installation Complete!
echo ============================================================================
echo.
echo All development tools have been installed successfully.
echo.

REM Run verification
echo Running installation verification...
echo ============================================================================
powershell -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\verify-installation.ps1"
echo ============================================================================
echo.

echo Next steps:
echo 1. Restart your command prompt or PowerShell to refresh PATH
echo 2. Run verify.bat anytime to check all installations
echo 3. Start developing with your new tools!
echo.
echo Available commands:
echo    - node --version    (Node.js - already installed)
echo    - npm --version     (npm package manager - already installed)
echo    - rustc --version   (Rust compiler)
echo    - cargo --version   (Rust package manager)
echo    - git --version     (Git version control)
echo    - gh --version      (GitHub CLI)
echo.
echo Log file saved to: %LOG_FILE%
echo.

echo Press any key to exit...
pause >nul
