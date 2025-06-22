# ============================================================================
# Git Installation Script
# ============================================================================
# This script installs Git for Windows with proper configuration
# for development environment.
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$LogFile,

    [Parameter(Mandatory=$true)]
    [string]$InstallersDir,

    [Parameter(Mandatory=$false)]
    [string]$ConfigDir
)

# Import utility functions
. "$PSScriptRoot\utils.ps1"

Write-Log "Starting Git installation..." $LogFile

# Function definitions (must be before main script logic)
function Install-Git {
    # Install Git silently with custom configuration
    $InstallArgs = @(
        "/VERYSILENT"
        "/NORESTART"
        "/NOCANCEL"
        "/SP-"
        "/CLOSEAPPLICATIONS"
        "/RESTARTAPPLICATIONS"
        "/COMPONENTS=ext,ext\shellhere,ext\guihere,gitlfs,assoc,assoc_sh"
        "/TASKS=desktopicon,quicklaunchicon,addcontextmenufiles,addcontextmenufolders,addtopath"
    )
    
    Write-Log "Running: $($GitInstaller.FullName) $($InstallArgs -join ' ')" $LogFile
    
    $Process = Start-Process -FilePath $GitInstaller.FullName -ArgumentList $InstallArgs -Wait -PassThru -NoNewWindow
    
    if ($Process.ExitCode -eq 0) {
        Write-Log "Git installation completed successfully" $LogFile
        Write-Host "Git installation completed successfully"
    } else {
        Write-Log "Git installation failed with exit code: $($Process.ExitCode)" $LogFile
        Write-Host "ERROR: Git installation failed with exit code: $($Process.ExitCode)"
        Write-Host ""
        Write-Host "This often happens when the installer is corrupted or incompatible."
        Write-Host ""
        Write-Host "Recovery options:"
        Write-Host "1. Skip Git installation and continue (Y)"
        Write-Host "2. Delete current installer and download latest version (d)"
        Write-Host "3. Exit installation (n)"
        Write-Host ""

        $Recovery = Read-Host "Choose option (Y/d/n)"
        if ($Recovery -match '^[Dd]') {
            Write-Log "User chose to re-download Git installer" $LogFile
            Write-Host "Removing current installer and downloading latest version..."

            # Remove current installer
            if (Test-Path $GitInstaller.FullName) {
                Remove-Item $GitInstaller.FullName -Force
                Write-Log "Removed corrupted installer: $($GitInstaller.FullName)" $LogFile
            }

            # Download latest Git for Windows
            try {
                Write-Host "Downloading latest Git for Windows installer..."
                $LatestUrl = "https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.1/Git-2.47.1-64-bit.exe"
                $NewInstallerPath = Join-Path $InstallersDir "Git-2.47.1-64-bit.exe"

                Invoke-WebRequest -Uri $LatestUrl -OutFile $NewInstallerPath -UserAgent "PowerShell/Portable-Dev-Setup"

                if (Test-Path $NewInstallerPath) {
                    Write-Log "Downloaded new installer: $NewInstallerPath" $LogFile
                    Write-Host "New installer downloaded successfully. Attempting installation..."

                    # Update the installer reference and retry installation
                    $GitInstaller = Get-Item $NewInstallerPath

                    # Retry installation with new installer
                    $RetryArgs = @(
                        "/VERYSILENT"
                        "/NORESTART"
                        "/NOCANCEL"
                        "/SP-"
                        "/CLOSEAPPLICATIONS"
                        "/RESTARTAPPLICATIONS"
                        "/COMPONENTS=ext,ext\shellhere,ext\guihere,gitlfs,assoc,assoc_sh"
                        "/TASKS=desktopicon,quicklaunchicon,addcontextmenufiles,addcontextmenufolders,addtopath"
                    )

                    Write-Log "Retrying with new installer: $($GitInstaller.FullName) $($RetryArgs -join ' ')" $LogFile
                    $RetryProcess = Start-Process -FilePath $GitInstaller.FullName -ArgumentList $RetryArgs -Wait -PassThru -NoNewWindow

                    if ($RetryProcess.ExitCode -eq 0) {
                        Write-Log "Git installation completed successfully with new installer" $LogFile
                        Write-Host "Git installation completed successfully with new installer"
                        # Continue to verification section
                    } else {
                        throw "Git installation failed even with new installer (exit code: $($RetryProcess.ExitCode))"
                    }
                } else {
                    throw "Failed to download new installer"
                }
            } catch {
                Write-Log "Failed to download new installer: $($_.Exception.Message)" $LogFile
                Write-Host "ERROR: Failed to download new installer: $($_.Exception.Message)"
                Write-Host "Please download Git manually from https://git-scm.com/download/win"
                exit 1
            }
        } elseif ($Recovery -notmatch '^[Nn]') {
            Write-Log "User chose to skip Git installation after error" $LogFile
            Write-Host "Skipping Git installation - using existing version if available"
            return
        } else {
            throw "Git installation failed with exit code: $($Process.ExitCode)"
        }
    }
    
    # Refresh environment variables
    Write-Log "Refreshing environment variables..." $LogFile
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    # Wait a moment for installation to complete
    Start-Sleep -Seconds 3
    
    # Verify installation
    Write-Log "Verifying Git installation..." $LogFile
    Write-Host "Verifying Git installation..."
    
    $GitPath = Get-Command "git" -ErrorAction SilentlyContinue
    if (-not $GitPath) {
        # Try common installation paths
        $CommonPaths = @(
            "${env:ProgramFiles}\Git\bin\git.exe",
            "${env:ProgramFiles(x86)}\Git\bin\git.exe"
        )
        
        foreach ($Path in $CommonPaths) {
            if (Test-Path $Path) {
                $GitPath = $Path
                break
            }
        }
    }
    
    if ($GitPath) {
        $GitVersion = & $GitPath --version 2>$null
        Write-Log "Git version: $GitVersion" $LogFile
        Write-Host "OK Git installed successfully: $GitVersion"
    } else {
        throw "Git installation verification failed - git command not found"
    }
}

function Set-GitUserConfig {
    # Get user input for Git configuration
    Write-Host ""
    Write-Host "Git User Configuration"
    Write-Host "====================="
    
    do {
        $GitUserName = Read-Host "Enter your Git username (e.g., 'John Doe')"
    } while ([string]::IsNullOrWhiteSpace($GitUserName))
    
    do {
        $GitUserEmail = Read-Host "Enter your Git email (e.g., 'john.doe@example.com')"
    } while ([string]::IsNullOrWhiteSpace($GitUserEmail))
    
    # Set Git user configuration
    try {
        & git config --global user.name $GitUserName
        & git config --global user.email $GitUserEmail
        
        Write-Log "Git user configured - Name: $GitUserName, Email: $GitUserEmail" $LogFile
        Write-Host "OK Git user configured successfully"
        
        # Save configuration to file for future reference
        $ConfigDirPath = if ($ConfigDir) { $ConfigDir } else { Join-Path $env:USERPROFILE ".portable-dev-setup" }
        if (-not (Test-Path $ConfigDirPath)) {
            New-Item -ItemType Directory -Path $ConfigDirPath -Force | Out-Null
        }
        
        $ConfigFile = Join-Path $ConfigDirPath "git-config.txt"
        $ConfigContent = @"
Git Configuration
================
User Name: $GitUserName
User Email: $GitUserEmail
Configured on: $(Get-Date)
"@
        $ConfigContent | Out-File -FilePath $ConfigFile -Encoding UTF8
        Write-Log "Git configuration saved to $ConfigFile" $LogFile
        
    } catch {
        Write-Log "Failed to configure Git user: $($_.Exception.Message)" $LogFile
        throw "Failed to configure Git user settings"
    }
}

function Configure-Git {
    Write-Log "Configuring Git..." $LogFile
    Write-Host "Configuring Git..."
    
    # Check for existing Git configuration
    $ExistingUser = & git config --global user.name 2>$null
    $ExistingEmail = & git config --global user.email 2>$null
    
    if ($ExistingUser -and $ExistingEmail) {
        Write-Log "Existing Git configuration found - User: $ExistingUser, Email: $ExistingEmail" $LogFile
        Write-Host "Existing Git configuration found:"
        Write-Host "  User: $ExistingUser"
        Write-Host "  Email: $ExistingEmail"
        
        $Response = Read-Host "Do you want to reconfigure Git user settings? (y/N)"
        if ($Response -notmatch '^[Yy]') {
            Write-Log "Keeping existing Git configuration" $LogFile
            Write-Host "Keeping existing Git configuration"
        } else {
            Set-GitUserConfig
        }
    } else {
        Set-GitUserConfig
    }
    
    # Configure Git settings for better Windows experience
    Write-Log "Applying Git configuration for Windows..." $LogFile
    Write-Host "Applying Git configuration for Windows..."
    
    $GitConfigs = @{
        "core.autocrlf" = "true"
        "core.filemode" = "false"
        "core.longpaths" = "true"
        "pull.rebase" = "false"
        "init.defaultBranch" = "main"
        "credential.helper" = "manager"
        "core.editor" = "notepad"
    }
    
    foreach ($Config in $GitConfigs.GetEnumerator()) {
        try {
            & git config --global $Config.Key $Config.Value
            Write-Log "Set $($Config.Key) = $($Config.Value)" $LogFile
        } catch {
            Write-Log "Failed to set $($Config.Key): $($_.Exception.Message)" $LogFile
        }
    }
    
    Write-Host "OK Git configuration applied"
}

# Main script logic
try {
    # Find Git installer
    $GitInstaller = Get-ChildItem -Path $InstallersDir -Filter "Git-*.exe" | Select-Object -First 1
    
    if (-not $GitInstaller) {
        throw "Git installer not found in $InstallersDir"
    }
    
    Write-Log "Found Git installer: $($GitInstaller.Name)" $LogFile
    Write-Host "Installing Git from $($GitInstaller.Name)..."
    
    # Check if Git is already installed
    $ExistingGit = Get-Command "git" -ErrorAction SilentlyContinue
    if ($ExistingGit) {
        $ExistingVersion = & git --version 2>$null
        Write-Log "Git is already installed: $ExistingVersion" $LogFile
        Write-Host "Git is already installed: $ExistingVersion"
        
        $Response = Read-Host "Do you want to reinstall Git? (y/N)"
        if ($Response -notmatch '^[Yy]') {
            Write-Log "Skipping Git installation, proceeding to configuration..." $LogFile
            Write-Host "Skipping Git installation, proceeding to configuration..."
        } else {
            # Proceed with installation
            Install-Git
        }
    } else {
        Install-Git
    }
    
    # Configure Git
    Configure-Git
    
    Write-Log "Git installation and configuration completed successfully" $LogFile
    
} catch {
    $ErrorMessage = "Git installation failed: $($_.Exception.Message)"
    Write-Log $ErrorMessage $LogFile
    Write-Error $ErrorMessage
    exit 1
}
