param(
    [Parameter(Mandatory=$true)]
    [string]$LogFile,
    
    [Parameter(Mandatory=$true)]
    [string]$InstallersDir
)

# Import utility functions
$UtilsPath = Join-Path $PSScriptRoot "utils.ps1"
if (Test-Path $UtilsPath) {
    . $UtilsPath
} else {
    Write-Error "Utils script not found at: $UtilsPath"
    exit 1
}

Write-Log "Starting Visual Studio Code installation..." $LogFile
Write-Host "Installing Visual Studio Code..."

try {
    # Check if VSCode is already installed
    $VSCodePaths = @(
        "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\Code.exe",
        "${env:ProgramFiles}\Microsoft VS Code\Code.exe",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\Code.exe"
    )
    
    $ExistingVSCode = $null
    foreach ($Path in $VSCodePaths) {
        if (Test-Path $Path) {
            $ExistingVSCode = $Path
            break
        }
    }
    
    if ($ExistingVSCode) {
        try {
            $VSCodeVersion = & $ExistingVSCode --version 2>$null | Select-Object -First 1
            Write-Log "Visual Studio Code already installed: $VSCodeVersion at $ExistingVSCode" $LogFile
            Write-Host "Visual Studio Code is already installed: $VSCodeVersion"
            Write-Host "Location: $ExistingVSCode"
            Write-Host ""
            
            Write-Host "Options:"
            Write-Host "1. Keep existing installation (recommended)"
            Write-Host "2. Reinstall VSCode (remove current and install fresh)"
            Write-Host "3. Skip VSCode installation"
            Write-Host ""
            
            $Choice = Read-Host "Choose option (1/2/3)"
            
            if ($Choice -eq "2") {
                Write-Log "User chose to reinstall VSCode" $LogFile
                Write-Host "Uninstalling existing VSCode installation..."
                
                # Try to find and run VSCode uninstaller
                $UninstallerPaths = @(
                    "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\unins000.exe",
                    "${env:ProgramFiles}\Microsoft VS Code\unins000.exe",
                    "${env:ProgramFiles(x86)}\Microsoft VS Code\unins000.exe"
                )
                
                $Uninstaller = $null
                foreach ($Path in $UninstallerPaths) {
                    if (Test-Path $Path) {
                        $Uninstaller = $Path
                        break
                    }
                }
                
                if ($Uninstaller) {
                    Write-Log "Running uninstaller: $Uninstaller" $LogFile
                    $UninstallProcess = Start-Process -FilePath $Uninstaller -ArgumentList "/VERYSILENT", "/NORESTART" -Wait -PassThru -NoNewWindow
                    
                    if ($UninstallProcess.ExitCode -eq 0) {
                        Write-Log "VSCode uninstalled successfully" $LogFile
                        Write-Host "VSCode uninstalled successfully"
                        Start-Sleep -Seconds 3
                    } else {
                        Write-Log "VSCode uninstall failed with exit code: $($UninstallProcess.ExitCode)" $LogFile
                        Write-Host "Warning: VSCode uninstall may have failed. Continuing with installation..."
                    }
                } else {
                    Write-Log "VSCode uninstaller not found, attempting manual cleanup" $LogFile
                    Write-Host "Uninstaller not found, attempting manual cleanup..."
                    
                    # Manual cleanup of VSCode directories
                    $VSCodeDirs = @(
                        "${env:LOCALAPPDATA}\Programs\Microsoft VS Code",
                        "${env:ProgramFiles}\Microsoft VS Code",
                        "${env:ProgramFiles(x86)}\Microsoft VS Code"
                    )
                    
                    foreach ($Dir in $VSCodeDirs) {
                        if (Test-Path $Dir) {
                            try {
                                Remove-Item $Dir -Recurse -Force
                                Write-Log "Removed directory: $Dir" $LogFile
                                Write-Host "Removed: $Dir"
                            } catch {
                                Write-Log "Failed to remove directory: $Dir - $($_.Exception.Message)" $LogFile
                                Write-Host "Warning: Could not remove $Dir"
                            }
                        }
                    }
                }
            } elseif ($Choice -eq "3") {
                Write-Log "User chose to skip VSCode installation" $LogFile
                Write-Host "Skipping VSCode installation."
                return
            } else {
                Write-Log "User chose to keep existing VSCode installation" $LogFile
                Write-Host "Keeping existing VSCode installation."
                return
            }
        } catch {
            Write-Log "Error checking existing VSCode: $($_.Exception.Message)" $LogFile
            Write-Host "Warning: Could not verify existing VSCode installation"
        }
    }
    
    # Look for VSCode installer
    $VSCodeInstallers = Get-ChildItem -Path $InstallersDir -Filter "VSCodeUserSetup-*.exe" -ErrorAction SilentlyContinue
    
    if (-not $VSCodeInstallers -or $VSCodeInstallers.Count -eq 0) {
        Write-Log "VSCode installer not found in $InstallersDir" $LogFile
        Write-Host "VSCode installer not found in installers folder."
        Write-Host ""
        Write-Host "Options:"
        Write-Host "1. Download VSCode installer automatically"
        Write-Host "2. Skip VSCode installation"
        Write-Host ""
        
        $DownloadChoice = Read-Host "Choose option (1/2)"
        
        if ($DownloadChoice -eq "1") {
            Write-Log "User chose to download VSCode installer" $LogFile
            Write-Host "Downloading Visual Studio Code installer..."
            
            try {
                $VSCodeUrl = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
                $VSCodeFileName = "VSCodeUserSetup-x64-latest.exe"
                $VSCodePath = Join-Path $InstallersDir $VSCodeFileName
                
                Write-Host "Downloading from: $VSCodeUrl"
                Write-Host "Saving to: $VSCodePath"
                
                Invoke-WebRequest -Uri $VSCodeUrl -OutFile $VSCodePath -UserAgent "PowerShell/Portable-Dev-Setup"
                
                if (Test-Path $VSCodePath) {
                    $FileInfo = Get-Item $VSCodePath
                    $FileSize = [math]::Round($FileInfo.Length / 1MB, 2)
                    Write-Log "Downloaded VSCode installer: $VSCodePath ($FileSize MB)" $LogFile
                    Write-Host "Downloaded successfully: $FileSize MB"
                    
                    $VSCodeInstallers = @($FileInfo)
                } else {
                    throw "Downloaded file not found"
                }
            } catch {
                Write-Log "Failed to download VSCode installer: $($_.Exception.Message)" $LogFile
                Write-Host "Error: Failed to download VSCode installer"
                Write-Host "You can manually download it from: https://code.visualstudio.com/"
                Write-Host "Place the installer in the installers\ folder and run this script again."
                return
            }
        } else {
            Write-Log "User chose to skip VSCode installation" $LogFile
            Write-Host "Skipping VSCode installation."
            return
        }
    }
    
    # Use the first (or only) installer found
    $VSCodeInstaller = $VSCodeInstallers[0]
    Write-Log "Using VSCode installer: $($VSCodeInstaller.FullName)" $LogFile
    Write-Host "Using installer: $($VSCodeInstaller.Name)"
    
    # Install VSCode silently
    $InstallArgs = @(
        "/VERYSILENT"
        "/NORESTART"
        "/MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"
    )
    
    Write-Log "Running: $($VSCodeInstaller.FullName) $($InstallArgs -join ' ')" $LogFile
    Write-Host "Installing Visual Studio Code..."
    
    $Process = Start-Process -FilePath $VSCodeInstaller.FullName -ArgumentList $InstallArgs -Wait -PassThru -NoNewWindow
    
    if ($Process.ExitCode -eq 0) {
        Write-Log "VSCode installation completed successfully" $LogFile
        Write-Host "VSCode installation completed successfully"
    } else {
        Write-Log "VSCode installation failed with exit code: $($Process.ExitCode)" $LogFile
        
        # Offer recovery options
        Write-Host "VSCode installation failed (exit code: $($Process.ExitCode))"
        Write-Host ""
        Write-Host "Recovery options:"
        Write-Host "1. Retry installation with current installer"
        Write-Host "2. Delete current installer and download fresh copy"
        Write-Host "3. Skip VSCode installation"
        Write-Host ""
        
        $Recovery = Read-Host "Choose option (1/2/3)"
        
        if ($Recovery -eq "1") {
            Write-Log "User chose to retry VSCode installation" $LogFile
            Write-Host "Retrying VSCode installation..."
            
            $RetryProcess = Start-Process -FilePath $VSCodeInstaller.FullName -ArgumentList $InstallArgs -Wait -PassThru -NoNewWindow
            
            if ($RetryProcess.ExitCode -eq 0) {
                Write-Log "VSCode installation retry succeeded" $LogFile
                Write-Host "VSCode installation completed successfully on retry"
            } else {
                throw "VSCode installation failed again with exit code: $($RetryProcess.ExitCode)"
            }
        } elseif ($Recovery -eq "2") {
            Write-Log "User chose to re-download VSCode installer" $LogFile
            Write-Host "Removing current installer and downloading fresh copy..."
            
            # Remove current installer
            if (Test-Path $VSCodeInstaller.FullName) {
                Remove-Item $VSCodeInstaller.FullName -Force
                Write-Log "Removed installer: $($VSCodeInstaller.FullName)" $LogFile
            }
            
            # Download fresh copy
            try {
                Write-Host "Downloading latest VSCode installer..."
                $VSCodeUrl = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
                $NewInstallerPath = Join-Path $InstallersDir "VSCodeUserSetup-x64-latest-retry.exe"
                
                Invoke-WebRequest -Uri $VSCodeUrl -OutFile $NewInstallerPath -UserAgent "PowerShell/Portable-Dev-Setup"
                
                if (Test-Path $NewInstallerPath) {
                    Write-Log "Downloaded new installer: $NewInstallerPath" $LogFile
                    Write-Host "New installer downloaded successfully. Attempting installation..."
                    
                    # Retry installation with new installer
                    $RetryProcess = Start-Process -FilePath $NewInstallerPath -ArgumentList $InstallArgs -Wait -PassThru -NoNewWindow
                    
                    if ($RetryProcess.ExitCode -eq 0) {
                        Write-Log "VSCode installation with new installer succeeded" $LogFile
                        Write-Host "VSCode installation completed successfully with new installer"
                    } else {
                        throw "VSCode installation failed with new installer (exit code: $($RetryProcess.ExitCode))"
                    }
                } else {
                    throw "New installer download failed"
                }
            } catch {
                Write-Log "Failed to download new VSCode installer: $($_.Exception.Message)" $LogFile
                throw "Failed to download and install new VSCode installer: $($_.Exception.Message)"
            }
        } else {
            Write-Log "User chose to skip VSCode installation after failure" $LogFile
            Write-Host "Skipping VSCode installation."
            return
        }
    }
    
    # Refresh environment variables
    Write-Log "Refreshing environment variables..." $LogFile
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    # Wait a moment for installation to complete
    Start-Sleep -Seconds 3
    
    # Verify installation
    Write-Log "Verifying VSCode installation..." $LogFile
    Write-Host "Verifying VSCode installation..."
    
    $VSCodePath = $null
    foreach ($Path in $VSCodePaths) {
        if (Test-Path $Path) {
            $VSCodePath = $Path
            break
        }
    }
    
    if ($VSCodePath) {
        try {
            $VSCodeVersion = & $VSCodePath --version 2>$null | Select-Object -First 1
            Write-Log "VSCode version: $VSCodeVersion" $LogFile
            Write-Host "Visual Studio Code installed successfully: $VSCodeVersion"
            Write-Host "Location: $VSCodePath"
        } catch {
            Write-Log "VSCode installed but version check failed: $($_.Exception.Message)" $LogFile
            Write-Host "Visual Studio Code appears to be installed but version check failed"
            Write-Host "Location: $VSCodePath"
        }
    } else {
        throw "VSCode installation verification failed - code command not found"
    }
    
    Write-Log "VSCode installation completed successfully" $LogFile
    
} catch {
    $ErrorMessage = "VSCode installation failed: $($_.Exception.Message)"
    Write-Log $ErrorMessage $LogFile
    Write-Error $ErrorMessage
    exit 1
}
