# ============================================================================
# Node.js Installation Script
# ============================================================================
# This script installs Node.js silently from a bundled MSI installer
# and verifies the installation was successful.
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$LogFile,
    
    [Parameter(Mandatory=$true)]
    [string]$InstallersDir
)

# Import utility functions
. "$PSScriptRoot\utils.ps1"

Write-Log "Starting Node.js installation..." $LogFile

try {
    # Find Node.js MSI installer
    $NodeInstaller = Get-ChildItem -Path $InstallersDir -Filter "node-*.msi" | Select-Object -First 1
    
    if (-not $NodeInstaller) {
        throw "Node.js MSI installer not found in $InstallersDir"
    }
    
    Write-Log "Found Node.js installer: $($NodeInstaller.Name)" $LogFile
    Write-Host "Installing Node.js from $($NodeInstaller.Name)..."
    
    # Check if Node.js is already installed
    $ExistingNode = Get-Command "node" -ErrorAction SilentlyContinue
    if ($ExistingNode) {
        $ExistingVersion = & node --version 2>$null
        Write-Log "Node.js is already installed: $ExistingVersion" $LogFile
        Write-Host "Node.js is already installed: $ExistingVersion"
        
        Write-Host ""
        Write-Host "Options:"
        Write-Host "1. Skip Node.js installation (recommended - use existing version)"
        Write-Host "2. Reinstall Node.js (may cause issues with version conflicts)"
        Write-Host "3. Exit installation"
        Write-Host ""
        
        $Response = Read-Host "Choose option (1/2/3)"
        
        if ($Response -eq "1" -or $Response -eq "") {
            Write-Log "User chose to skip Node.js installation" $LogFile
            Write-Host "Skipping Node.js installation - using existing version"
            Write-Host "Node.js is ready to use: $ExistingVersion"
            exit 0
        } elseif ($Response -eq "3") {
            Write-Log "User chose to exit installation" $LogFile
            Write-Host "Installation cancelled by user"
            exit 1
        } elseif ($Response -eq "2") {
            Write-Log "User chose to reinstall Node.js" $LogFile
            Write-Host "Proceeding with Node.js reinstallation..."
            Write-Host "WARNING: This may cause version conflicts!"
            Write-Host ""
        } else {
            Write-Log "Invalid response, skipping Node.js installation" $LogFile
            Write-Host "Invalid response. Skipping Node.js installation."
            exit 0
        }
    }
    
    # Install Node.js silently
    $InstallArgs = @(
        "/i"
        "`"$($NodeInstaller.FullName)`""
        "/quiet"
        "/norestart"
        "ADDLOCAL=ALL"
    )
    
    Write-Log "Running: msiexec $($InstallArgs -join ' ')" $LogFile
    
    $Process = Start-Process -FilePath "msiexec" -ArgumentList $InstallArgs -Wait -PassThru -NoNewWindow
    
    if ($Process.ExitCode -eq 0) {
        Write-Log "Node.js installation completed successfully" $LogFile
        Write-Host "Node.js installation completed successfully"
    } elseif ($Process.ExitCode -eq 3010) {
        Write-Log "Node.js installation completed successfully (reboot required)" $LogFile
        Write-Host "Node.js installation completed successfully (reboot may be required)"
    } elseif ($Process.ExitCode -eq 1620) {
        Write-Log "Node.js installation failed: MSI package could not be opened (exit code 1620)" $LogFile
        Write-Host "ERROR: The Node.js installer package appears to be corrupted or incompatible."
        Write-Host ""
        Write-Host "This often happens when trying to downgrade from a newer version."
        Write-Host ""
        Write-Host "Recovery options:"
        Write-Host "1. Skip Node.js installation and continue (Y)"
        Write-Host "2. Delete current installer and download latest version (d)"
        Write-Host "3. Exit installation (n)"
        Write-Host ""

        $Recovery = Read-Host "Choose option (Y/d/n)"
        if ($Recovery -match '^[Dd]') {
            Write-Log "User chose to re-download Node.js installer" $LogFile
            Write-Host "Removing current installer and downloading latest version..."

            # Remove current installer
            if (Test-Path $NodeInstaller.FullName) {
                Remove-Item $NodeInstaller.FullName -Force
                Write-Log "Removed corrupted installer: $($NodeInstaller.FullName)" $LogFile
            }

            # Download latest Node.js LTS
            try {
                Write-Host "Downloading latest Node.js LTS installer..."
                $LatestUrl = "https://nodejs.org/dist/latest-v20.x/node-v20.18.0-x64.msi"
                $NewInstallerPath = Join-Path $InstallersDir "node-v20.18.0-x64.msi"

                Invoke-WebRequest -Uri $LatestUrl -OutFile $NewInstallerPath -UserAgent "PowerShell/Portable-Dev-Setup"

                if (Test-Path $NewInstallerPath) {
                    Write-Log "Downloaded new installer: $NewInstallerPath" $LogFile
                    Write-Host "New installer downloaded successfully. Attempting installation..."

                    # Update the installer reference and retry installation
                    $NodeInstaller = Get-Item $NewInstallerPath

                    # Retry installation with new installer
                    $InstallArgs = @(
                        "/i"
                        "`"$($NodeInstaller.FullName)`""
                        "/quiet"
                        "/norestart"
                        "ADDLOCAL=ALL"
                    )

                    Write-Log "Retrying with new installer: msiexec $($InstallArgs -join ' ')" $LogFile
                    $RetryProcess = Start-Process -FilePath "msiexec" -ArgumentList $InstallArgs -Wait -PassThru -NoNewWindow

                    if ($RetryProcess.ExitCode -eq 0 -or $RetryProcess.ExitCode -eq 3010) {
                        Write-Log "Node.js installation completed successfully with new installer" $LogFile
                        Write-Host "Node.js installation completed successfully with new installer"
                        # Continue to verification section
                    } else {
                        throw "Node.js installation failed even with new installer (exit code: $($RetryProcess.ExitCode))"
                    }
                } else {
                    throw "Failed to download new installer"
                }
            } catch {
                Write-Log "Failed to download new installer: $($_.Exception.Message)" $LogFile
                Write-Host "ERROR: Failed to download new installer: $($_.Exception.Message)"
                Write-Host "Please download Node.js manually from https://nodejs.org/"
                exit 1
            }
        } elseif ($Recovery -notmatch '^[Nn]') {
            Write-Log "User chose to skip Node.js installation after error" $LogFile
            Write-Host "Skipping Node.js installation - using existing version"
            exit 0
        } else {
            throw "Node.js installation failed: MSI package could not be opened (exit code 1620)"
        }
    } elseif ($Process.ExitCode -eq 1603) {
        Write-Log "Node.js installation failed: Fatal error during installation (exit code 1603)" $LogFile
        Write-Host "ERROR: A fatal error occurred during Node.js installation."
        Write-Host "This usually means another version is already installed or there's a permission issue."
        Write-Host ""
        Write-Host "Recovery options:"
        Write-Host "1. Skip Node.js installation and continue (Y)"
        Write-Host "2. Delete current installer and download latest version (d)"
        Write-Host "3. Exit installation (n)"
        Write-Host ""

        $Recovery = Read-Host "Choose option (Y/d/n)"
        if ($Recovery -match '^[Dd]') {
            Write-Log "User chose to re-download Node.js installer" $LogFile
            Write-Host "Removing current installer and downloading latest version..."

            # Remove current installer
            if (Test-Path $NodeInstaller.FullName) {
                Remove-Item $NodeInstaller.FullName -Force
                Write-Log "Removed installer: $($NodeInstaller.FullName)" $LogFile
            }

            # Download latest Node.js LTS
            try {
                Write-Host "Downloading latest Node.js LTS installer..."
                $LatestUrl = "https://nodejs.org/dist/latest-v20.x/node-v20.18.0-x64.msi"
                $NewInstallerPath = Join-Path $InstallersDir "node-v20.18.0-x64.msi"

                Invoke-WebRequest -Uri $LatestUrl -OutFile $NewInstallerPath -UserAgent "PowerShell/Portable-Dev-Setup"

                if (Test-Path $NewInstallerPath) {
                    Write-Log "Downloaded new installer: $NewInstallerPath" $LogFile
                    Write-Host "New installer downloaded successfully. Attempting installation..."

                    # Update the installer reference and retry installation
                    $NodeInstaller = Get-Item $NewInstallerPath

                    # Retry installation with new installer
                    $InstallArgs = @(
                        "/i"
                        "`"$($NodeInstaller.FullName)`""
                        "/quiet"
                        "/norestart"
                        "ADDLOCAL=ALL"
                    )

                    Write-Log "Retrying with new installer: msiexec $($InstallArgs -join ' ')" $LogFile
                    $RetryProcess = Start-Process -FilePath "msiexec" -ArgumentList $InstallArgs -Wait -PassThru -NoNewWindow

                    if ($RetryProcess.ExitCode -eq 0 -or $RetryProcess.ExitCode -eq 3010) {
                        Write-Log "Node.js installation completed successfully with new installer" $LogFile
                        Write-Host "Node.js installation completed successfully with new installer"
                        # Continue to verification section
                    } else {
                        throw "Node.js installation failed even with new installer (exit code: $($RetryProcess.ExitCode))"
                    }
                } else {
                    throw "Failed to download new installer"
                }
            } catch {
                Write-Log "Failed to download new installer: $($_.Exception.Message)" $LogFile
                Write-Host "ERROR: Failed to download new installer: $($_.Exception.Message)"
                Write-Host "Please download Node.js manually from https://nodejs.org/"
                exit 1
            }
        } elseif ($Recovery -notmatch '^[Nn]') {
            Write-Log "User chose to skip Node.js installation after error" $LogFile
            Write-Host "Skipping Node.js installation - using existing version"
            exit 0
        } else {
            throw "Node.js installation failed: Fatal error during installation (exit code 1603)"
        }
    } else {
        $ErrorMsg = "Node.js installation failed with exit code: $($Process.ExitCode)"
        Write-Log $ErrorMsg $LogFile
        Write-Host "ERROR: $ErrorMsg"
        throw $ErrorMsg
    }
    
    # Refresh environment variables
    Write-Log "Refreshing environment variables..." $LogFile
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    # Wait a moment for installation to complete
    Start-Sleep -Seconds 3
    
    # Verify installation
    Write-Log "Verifying Node.js installation..." $LogFile
    Write-Host "Verifying Node.js installation..."
    
    $NodePath = Get-Command "node" -ErrorAction SilentlyContinue
    if (-not $NodePath) {
        # Try common installation paths
        $CommonPaths = @(
            "${env:ProgramFiles}\nodejs\node.exe",
            "${env:ProgramFiles(x86)}\nodejs\node.exe"
        )
        
        foreach ($Path in $CommonPaths) {
            if (Test-Path $Path) {
                $NodePath = $Path
                break
            }
        }
    }
    
    if ($NodePath) {
        $NodeVersion = & $NodePath --version 2>$null
        $NpmVersion = & "${env:ProgramFiles}\nodejs\npm.cmd" --version 2>$null
        
        if (-not $NpmVersion) {
            $NpmVersion = & "${env:ProgramFiles(x86)}\nodejs\npm.cmd" --version 2>$null
        }
        
        Write-Log "Node.js version: $NodeVersion" $LogFile
        Write-Log "npm version: $NpmVersion" $LogFile
        Write-Host "Node.js installed successfully: $NodeVersion"
        Write-Host "npm installed successfully: $NpmVersion"
        
    } else {
        throw "Node.js installation verification failed - node command not found"
    }
    
    Write-Log "Node.js installation completed successfully" $LogFile
    
} catch {
    $ErrorMessage = "Node.js installation failed: $($_.Exception.Message)"
    Write-Log $ErrorMessage $LogFile
    Write-Error $ErrorMessage
    exit 1
}
