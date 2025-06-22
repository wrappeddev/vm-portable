@echo off
REM ============================================================================
REM Portable Windows Dev Setup - Main Installation Script
REM ============================================================================
REM This script orchestrates the installation of a complete development
REM environment including Node.js, Rust, Git, GitHub CLI, and build tools.
REM ============================================================================

setlocal enabledelayedexpansion

REM Set script directory and paths
set "SCRIPT_DIR=%~dp0"
set "SCRIPTS_DIR=%SCRIPT_DIR%scripts"
set "INSTALLERS_DIR=%SCRIPT_DIR%installers"
set "CONFIG_DIR=%SCRIPT_DIR%config"
set "LOGS_DIR=%SCRIPT_DIR%logs"

REM Create directories if they don't exist
if not exist "%SCRIPTS_DIR%" mkdir "%SCRIPTS_DIR%"
if not exist "%INSTALLERS_DIR%" mkdir "%INSTALLERS_DIR%"
if not exist "%CONFIG_DIR%" mkdir "%CONFIG_DIR%"
if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%"

REM Set log file with simple timestamp
set "timestamp=%RANDOM%_%RANDOM%"
set "LOG_FILE=%LOGS_DIR%\install_%timestamp%.log"

REM Ensure logs directory exists
if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%"

REM Test log file creation
echo Testing log file creation... > "%LOG_FILE%" 2>nul
if not exist "%LOG_FILE%" (
    echo WARNING: Cannot create log file. Logging will be disabled.
    set "LOG_FILE=nul"
)

echo ============================================================================
echo Portable Windows Dev Setup Installation
echo ============================================================================
echo.
echo This script will install:
echo - Node.js (with npm)
echo - Rust (with Cargo)
echo - Git
echo - GitHub CLI
echo - Visual Studio Code
echo - Windows Build Tools
echo.
echo Log file: %LOG_FILE%
echo.

REM Ask about uninstalling existing tools
echo Before proceeding, would you like to uninstall any existing development tools?
echo This can help avoid conflicts during installation.
echo.
echo Options:
echo 1. Continue with installation ^(keep existing tools^)
echo 2. Uninstall existing tools first ^(recommended for clean install^)
echo 3. Exit installation
echo.

set /p "UNINSTALL_CHOICE=Choose option (1/2/3): "

echo.
echo You selected: %UNINSTALL_CHOICE%
echo.

if "%UNINSTALL_CHOICE%"=="2" (
    echo ============================================================================
    echo Uninstalling Existing Development Tools
    echo ============================================================================
    powershell -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\uninstall-tools.ps1" -LogFile "%LOG_FILE%"

    if !errorLevel! neq 0 (
        echo WARNING: Some uninstallation steps may have failed.
        echo Check the log file for details: %LOG_FILE%
        echo.
        set /p "CONTINUE_AFTER_UNINSTALL=Continue with installation anyway? (Y/n): "
        if /i "!CONTINUE_AFTER_UNINSTALL!"=="n" (
            echo Installation cancelled.
            pause
            exit /b 1
        )
    )

    echo [OK] Uninstallation completed. Proceeding with fresh installation...
    echo.

) else if "%UNINSTALL_CHOICE%"=="3" (
    echo Installation cancelled by user.
    pause
    exit /b 0

) else (
    echo Proceeding with installation ^(keeping existing tools^)...
    echo.
)

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo WARNING: Not running as administrator. Some installations may fail.
    echo Press any key to continue anyway, or Ctrl+C to exit and run as admin.
    pause >nul
)

REM Start logging
echo Installation started at %date% %time% > "%LOG_FILE%"
echo ============================================================================ >> "%LOG_FILE%"

REM Check for required installer files
echo Checking for required installer files...
set "MISSING_FILES="

REM Check each file individually and show what we find
echo Checking Node.js installer...
if not exist "%INSTALLERS_DIR%\node-*.msi" (
    set "MISSING_FILES=!MISSING_FILES! Node.js-MSI"
    echo   - Node.js MSI: NOT FOUND
) else (
    echo   - Node.js MSI: FOUND
)

echo Checking Rust installer...
if not exist "%INSTALLERS_DIR%\rustup-init.exe" (
    set "MISSING_FILES=!MISSING_FILES! rustup-init.exe"
    echo   - Rust installer: NOT FOUND
) else (
    echo   - Rust installer: FOUND
)

echo Checking Git installer...
if not exist "%INSTALLERS_DIR%\Git-*.exe" (
    set "MISSING_FILES=!MISSING_FILES! Git-EXE"
    echo   - Git installer: NOT FOUND
) else (
    echo   - Git installer: FOUND
)

echo Checking GitHub CLI installer...
if not exist "%INSTALLERS_DIR%\gh_*_windows_amd64.msi" (
    set "MISSING_FILES=!MISSING_FILES! GitHub-CLI-MSI"
    echo   - GitHub CLI MSI: NOT FOUND
) else (
    echo   - GitHub CLI MSI: FOUND
)

echo Checking Visual Studio Code installer...
if not exist "%INSTALLERS_DIR%\VSCodeUserSetup-*.exe" (
    echo   - VSCode installer: NOT FOUND ^(will download if needed^)
) else (
    echo   - VSCode installer: FOUND
)

echo.

if not "!MISSING_FILES!"=="" (
    echo ============================================================================
    echo WARNING: Missing installer files detected!
    echo ============================================================================
    echo Missing files: !MISSING_FILES!
    echo.
    echo Missing files: !MISSING_FILES! >> "%LOG_FILE%"

    echo What would you like to do?
    echo.
    echo 1. Download automatically ^(requires internet connection^)
    echo 2. Download manually ^(see DOWNLOAD-LINKS.md^)
    echo 3. Exit and download later
    echo.
    echo Please choose an option and press Enter:

    set /p "DOWNLOAD_CHOICE=Enter your choice (1, 2, or 3): "

    echo.
    echo You selected: !DOWNLOAD_CHOICE!
    echo.

    if "!DOWNLOAD_CHOICE!"=="1" (
        echo.
        echo Attempting to download missing installers automatically...
        echo ============================================================================

        REM Check if download script exists
        if not exist "%SCRIPTS_DIR%\download-installers.ps1" (
            echo ERROR: Download script not found. Please download installers manually.
            echo See DOWNLOAD-LINKS.md for instructions.
            pause
            exit /b 1
        )

        REM Run download script
        powershell -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\download-installers.ps1" -LogFile "%LOG_FILE%" -InstallersDir "%INSTALLERS_DIR%"

        if !errorLevel! neq 0 (
            echo ERROR: Automatic download failed. Please download installers manually.
            echo See DOWNLOAD-LINKS.md for instructions.
            pause
            exit /b 1
        )

        echo.
        echo [OK] Download process completed. Continuing with installation...
        echo ============================================================================

    ) else if "!DOWNLOAD_CHOICE!"=="2" (
        echo.
        echo Please download the required installers manually:
        echo See DOWNLOAD-LINKS.md for download links and instructions.
        echo Place all installer files in the installers\ folder.
        echo Then run install.bat again.
        pause
        exit /b 1

    ) else (
        echo Installation cancelled.
        echo You can download installers using download.bat or manually.
        pause
        exit /b 1
    )
)

echo [OK] All required installer files found.
echo.
echo Installation will now begin. Each tool will check if it's already installed
echo and ask if you want to reinstall it.
echo.
echo Proceeding with installation...
echo.

REM Set PowerShell execution policy
echo Setting PowerShell execution policy...
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser -Force" 2>&1
echo PowerShell execution policy set.
echo.

REM Install Node.js
echo ============================================================================
echo Installing Node.js...
echo ============================================================================
powershell -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\install-nodejs.ps1" -LogFile "%LOG_FILE%" -InstallersDir "%INSTALLERS_DIR%"
if %errorLevel% neq 0 (
    echo ERROR: Node.js installation failed. Check log file for details.
    echo Log file: %LOG_FILE%
    pause
    exit /b 1
)
echo [OK] Node.js installation completed.
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

REM Install Visual Studio Code
echo ============================================================================
echo Installing Visual Studio Code...
echo ============================================================================
powershell -ExecutionPolicy Bypass -File "%SCRIPTS_DIR%\install-vscode.ps1" -LogFile "%LOG_FILE%" -InstallersDir "%INSTALLERS_DIR%"
if %errorLevel% neq 0 (
    echo ERROR: Visual Studio Code installation failed. Check log file for details.
    echo Log file: %LOG_FILE%
    pause
    exit /b 1
)
echo [OK] Visual Studio Code installation completed.
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
echo    - node --version    (Node.js)
echo    - npm --version     (npm package manager)
echo    - rustc --version   (Rust compiler)
echo    - cargo --version   (Rust package manager)
echo    - git --version     (Git version control)
echo    - gh --version      (GitHub CLI)
echo    - code --version    (Visual Studio Code)
echo.
echo Log file saved to: %LOG_FILE%
echo.
echo Installation completed at %date% %time% >> "%LOG_FILE%"
echo ============================================================================ >> "%LOG_FILE%"

echo.
echo Press any key to exit...
pause >nul
