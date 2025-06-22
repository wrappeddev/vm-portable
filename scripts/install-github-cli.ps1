# ============================================================================
# GitHub CLI Installation Script
# ============================================================================
# This script installs GitHub CLI with proper configuration
# for development environment.
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$LogFile,
    
    [Parameter(Mandatory=$true)]
    [string]$InstallersDir,
    
    [Parameter(Mandatory=$true)]
    [string]$ConfigDir
)

# Import utility functions
. "$PSScriptRoot\utils.ps1"

Write-Log "Starting GitHub CLI installation..." $LogFile

# Function definitions (must be before main script logic)
function Install-GitHubCLI {
    # Install GitHub CLI silently
    $InstallArgs = @(
        "/i"
        "`"$($GhInstaller.FullName)`""
        "/quiet"
        "/norestart"
    )
    
    Write-Log "Running: msiexec $($InstallArgs -join ' ')" $LogFile
    
    $Process = Start-Process -FilePath "msiexec" -ArgumentList $InstallArgs -Wait -PassThru -NoNewWindow
    
    if ($Process.ExitCode -eq 0) {
        Write-Log "GitHub CLI installation completed successfully" $LogFile
        Write-Host "GitHub CLI installation completed successfully"
    } elseif ($Process.ExitCode -eq 3010) {
        Write-Log "GitHub CLI installation completed successfully (reboot required)" $LogFile
        Write-Host "GitHub CLI installation completed successfully (reboot may be required)"
    } else {
        Write-Log "GitHub CLI installation failed with exit code: $($Process.ExitCode)" $LogFile
        Write-Host "ERROR: GitHub CLI installation failed with exit code: $($Process.ExitCode)"
        Write-Host ""
        Write-Host "This often happens when the installer is corrupted or incompatible."
        Write-Host ""
        Write-Host "Recovery options:"
        Write-Host "1. Skip GitHub CLI installation and continue (Y)"
        Write-Host "2. Delete current installer and download latest version (d)"
        Write-Host "3. Exit installation (n)"
        Write-Host ""
        
        $Recovery = Read-Host "Choose option (Y/d/n)"
        if ($Recovery -match '^[Dd]') {
            Write-Log "User chose to re-download GitHub CLI installer" $LogFile
            Write-Host "Removing current installer and downloading latest version..."
            
            # Remove current installer
            if (Test-Path $GhInstaller.FullName) {
                Remove-Item $GhInstaller.FullName -Force
                Write-Log "Removed corrupted installer: $($GhInstaller.FullName)" $LogFile
            }
            
            # Download latest GitHub CLI
            try {
                Write-Host "Downloading latest GitHub CLI installer..."
                $LatestUrl = "https://github.com/cli/cli/releases/download/v2.62.0/gh_2.62.0_windows_amd64.msi"
                $NewInstallerPath = Join-Path $InstallersDir "gh_2.62.0_windows_amd64.msi"
                
                Invoke-WebRequest -Uri $LatestUrl -OutFile $NewInstallerPath -UserAgent "PowerShell/Portable-Dev-Setup"
                
                if (Test-Path $NewInstallerPath) {
                    Write-Log "Downloaded new installer: $NewInstallerPath" $LogFile
                    Write-Host "New installer downloaded successfully. Attempting installation..."
                    
                    # Update the installer reference and retry installation
                    $GhInstaller = Get-Item $NewInstallerPath
                    
                    # Retry installation with new installer
                    $RetryArgs = @(
                        "/i"
                        "`"$($GhInstaller.FullName)`""
                        "/quiet"
                        "/norestart"
                    )
                    
                    Write-Log "Retrying with new installer: msiexec $($RetryArgs -join ' ')" $LogFile
                    $RetryProcess = Start-Process -FilePath "msiexec" -ArgumentList $RetryArgs -Wait -PassThru -NoNewWindow
                    
                    if ($RetryProcess.ExitCode -eq 0 -or $RetryProcess.ExitCode -eq 3010) {
                        Write-Log "GitHub CLI installation completed successfully with new installer" $LogFile
                        Write-Host "GitHub CLI installation completed successfully with new installer"
                        # Continue to verification section
                    } else {
                        throw "GitHub CLI installation failed even with new installer (exit code: $($RetryProcess.ExitCode))"
                    }
                } else {
                    throw "Failed to download new installer"
                }
            } catch {
                Write-Log "Failed to download new installer: $($_.Exception.Message)" $LogFile
                Write-Host "ERROR: Failed to download new installer: $($_.Exception.Message)"
                Write-Host "Please download GitHub CLI manually from https://cli.github.com/"
                exit 1
            }
        } elseif ($Recovery -notmatch '^[Nn]') {
            Write-Log "User chose to skip GitHub CLI installation after error" $LogFile
            Write-Host "Skipping GitHub CLI installation - you can install it later"
            return
        } else {
            throw "GitHub CLI installation failed with exit code: $($Process.ExitCode)"
        }
    }
    
    # Refresh environment variables
    Write-Log "Refreshing environment variables..." $LogFile
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    # Wait a moment for installation to complete
    Start-Sleep -Seconds 3
    
    # Verify installation
    Write-Log "Verifying GitHub CLI installation..." $LogFile
    Write-Host "Verifying GitHub CLI installation..."
    
    $GhPath = Get-Command "gh" -ErrorAction SilentlyContinue
    if (-not $GhPath) {
        # Try common installation paths
        $CommonPaths = @(
            "${env:ProgramFiles}\GitHub CLI\gh.exe",
            "${env:ProgramFiles(x86)}\GitHub CLI\gh.exe"
        )
        
        foreach ($Path in $CommonPaths) {
            if (Test-Path $Path) {
                $GhPath = $Path
                break
            }
        }
    }
    
    if ($GhPath) {
        $GhVersion = & $GhPath --version 2>$null | Select-Object -First 1
        Write-Log "GitHub CLI version: $GhVersion" $LogFile
        Write-Host "OK GitHub CLI installed successfully: $GhVersion"
    } else {
        throw "GitHub CLI installation verification failed - gh command not found"
    }
}

function Configure-GitHubCLI {
    Write-Log "Configuring GitHub CLI..." $LogFile
    Write-Host "Configuring GitHub CLI..."
    
    # Configure Git to use GitHub CLI as credential helper
    try {
        & git config --global credential.helper ""
        & git config --global credential.https://github.com.helper ""
        & git config --global credential.https://github.com.helper "!gh auth git-credential"
        
        Write-Log "Configured Git to use GitHub CLI credential helper" $LogFile
        Write-Host "OK Configured Git to use GitHub CLI credential helper"
    } catch {
        Write-Log "Failed to configure Git credential helper: $($_.Exception.Message)" $LogFile
        Write-Host "WARNING Failed to configure Git credential helper"
    }
    
    # Set GitHub CLI preferences
    try {
        & gh config set git_protocol https
        & gh config set editor notepad
        & gh config set prompt enabled
        
        Write-Log "GitHub CLI preferences configured" $LogFile
        Write-Host "OK GitHub CLI preferences configured"
    } catch {
        Write-Log "Failed to set GitHub CLI preferences: $($_.Exception.Message)" $LogFile
        Write-Host "WARNING Failed to set GitHub CLI preferences"
    }
}

function Export-GitHubCredentials {
    try {
        $GhConfigDir = Join-Path $env:APPDATA "GitHub CLI"
        $HostsFile = Join-Path $GhConfigDir "hosts.yml"
        $BackupFile = Join-Path $ConfigDir "gh-hosts-backup.yml"
        
        if (Test-Path $HostsFile) {
            Copy-Item $HostsFile $BackupFile -Force
            Write-Log "GitHub credentials backed up to $BackupFile" $LogFile
            Write-Host "OK GitHub credentials backed up for portability"
        }
    } catch {
        Write-Log "Failed to backup GitHub credentials: $($_.Exception.Message)" $LogFile
        Write-Host "WARNING Failed to backup GitHub credentials"
    }
}

function Import-GitHubCredentials($BackupFile) {
    $GhConfigDir = Join-Path $env:APPDATA "GitHub CLI"
    $HostsFile = Join-Path $GhConfigDir "hosts.yml"
    
    # Create GitHub CLI config directory if it doesn't exist
    if (-not (Test-Path $GhConfigDir)) {
        New-Item -ItemType Directory -Path $GhConfigDir -Force | Out-Null
    }
    
    # Copy backup to hosts file
    Copy-Item $BackupFile $HostsFile -Force
    
    Write-Log "GitHub credentials imported from $BackupFile" $LogFile
    Write-Host "OK GitHub credentials imported successfully"

    # Verify authentication
    $AuthStatus = & gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK Authentication verified"
        Write-Host $AuthStatus
    } else {
        throw "Authentication verification failed after import"
    }
}

function Handle-GitHubAuth {
    Write-Log "Handling GitHub authentication..." $LogFile
    Write-Host ""
    Write-Host "GitHub Authentication"
    Write-Host "===================="

    # Check if already authenticated
    $AuthStatus = & gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Already authenticated with GitHub" $LogFile
        Write-Host "OK Already authenticated with GitHub"
        Write-Host $AuthStatus
        return
    }

    # Check for existing backup
    $BackupFile = Join-Path $ConfigDir "gh-hosts-backup.yml"
    if (Test-Path $BackupFile) {
        Write-Host "Found existing GitHub CLI credentials backup."
        $Response = Read-Host "Do you want to import existing credentials? (Y/n)"

        if ($Response -notmatch '^[Nn]') {
            try {
                Import-GitHubCredentials $BackupFile
                return
            } catch {
                Write-Log "Failed to import credentials: $($_.Exception.Message)" $LogFile
                Write-Host "WARNING Failed to import credentials, proceeding with new authentication"
            }
        }
    }

    # Perform new authentication
    Write-Host ""
    Write-Host "You need to authenticate with GitHub."
    Write-Host "This will open a web browser for authentication."
    Write-Host ""
    $Response = Read-Host "Do you want to authenticate now? (Y/n)"

    if ($Response -notmatch '^[Nn]') {
        try {
            Write-Host "Starting GitHub authentication..."
            & gh auth login --web --git-protocol https --hostname github.com

            if ($LASTEXITCODE -eq 0) {
                Write-Log "GitHub authentication completed successfully" $LogFile
                Write-Host "OK GitHub authentication completed successfully"

                # Create backup of credentials
                Export-GitHubCredentials
            } else {
                Write-Log "GitHub authentication failed" $LogFile
                Write-Host "WARNING GitHub authentication failed"
            }
        } catch {
            Write-Log "GitHub authentication error: $($_.Exception.Message)" $LogFile
            Write-Host "WARNING GitHub authentication error: $($_.Exception.Message)"
        }
    } else {
        Write-Log "GitHub authentication skipped by user" $LogFile
        Write-Host "GitHub authentication skipped. You can authenticate later using: gh auth login"
    }
}

# Main script logic
try {
    # Find GitHub CLI installer
    $GhInstaller = Get-ChildItem -Path $InstallersDir -Filter "gh_*_windows_amd64.msi" | Select-Object -First 1

    if (-not $GhInstaller) {
        throw "GitHub CLI installer not found in $InstallersDir"
    }

    Write-Log "Found GitHub CLI installer: $($GhInstaller.Name)" $LogFile
    Write-Host "Installing GitHub CLI from $($GhInstaller.Name)..."

    # Check if GitHub CLI is already installed
    $ExistingGh = Get-Command "gh" -ErrorAction SilentlyContinue
    if ($ExistingGh) {
        $ExistingVersion = & gh --version 2>$null | Select-Object -First 1
        Write-Log "GitHub CLI is already installed: $ExistingVersion" $LogFile
        Write-Host "GitHub CLI is already installed: $ExistingVersion"

        $Response = Read-Host "Do you want to reinstall GitHub CLI? (y/N)"
        if ($Response -notmatch '^[Yy]') {
            Write-Log "Skipping GitHub CLI installation, proceeding to authentication..." $LogFile
            Write-Host "Skipping GitHub CLI installation, proceeding to authentication..."
        } else {
            Install-GitHubCLI
        }
    } else {
        Install-GitHubCLI
    }

    # Configure GitHub CLI and Git integration
    Configure-GitHubCLI

    # Handle authentication
    Handle-GitHubAuth

    Write-Log "GitHub CLI installation and configuration completed successfully" $LogFile

} catch {
    $ErrorMessage = "GitHub CLI installation failed: $($_.Exception.Message)"
    Write-Log $ErrorMessage $LogFile
    Write-Error $ErrorMessage
    exit 1
}
