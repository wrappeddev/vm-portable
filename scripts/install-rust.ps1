# ============================================================================
# Rust Installation Script
# ============================================================================
# This script installs Rust using rustup-init.exe with proper configuration
# for Windows development environment.
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$LogFile,
    
    [Parameter(Mandatory=$true)]
    [string]$InstallersDir
)

# Import utility functions
. "$PSScriptRoot\utils.ps1"

Write-Log "Starting Rust installation..." $LogFile

try {
    # Find rustup-init.exe
    $RustupInstaller = Join-Path $InstallersDir "rustup-init.exe"
    
    if (-not (Test-Path $RustupInstaller)) {
        throw "rustup-init.exe not found in $InstallersDir"
    }
    
    Write-Log "Found Rust installer: $RustupInstaller" $LogFile
    Write-Host "Installing Rust from rustup-init.exe..."
    
    # Check if Rust is already installed
    $ExistingRustc = Get-Command "rustc" -ErrorAction SilentlyContinue
    if ($ExistingRustc) {
        $ExistingVersion = & rustc --version 2>$null
        Write-Log "Rust is already installed: $ExistingVersion" $LogFile
        Write-Host "Rust is already installed: $ExistingVersion"
        
        $Response = Read-Host "Do you want to reinstall Rust? (y/N)"
        if ($Response -notmatch '^[Yy]') {
            Write-Log "Skipping Rust installation" $LogFile
            Write-Host "Skipping Rust installation"
            return
        }
    }
    
    # Set environment variables for silent installation
    $env:RUSTUP_INIT_SKIP_PATH_WARNING = "yes"
    
    # Install Rust silently with default stable toolchain
    $InstallArgs = @(
        "--default-toolchain", "stable"
        "--default-host", "x86_64-pc-windows-msvc"
        "--profile", "default"
        "-y"  # Accept defaults without prompting
    )
    
    Write-Log "Running: $RustupInstaller $($InstallArgs -join ' ')" $LogFile
    
    $Process = Start-Process -FilePath $RustupInstaller -ArgumentList $InstallArgs -Wait -PassThru -NoNewWindow
    
    if ($Process.ExitCode -eq 0) {
        Write-Log "Rust installation completed successfully" $LogFile
        Write-Host "Rust installation completed successfully"
    } else {
        Write-Log "Rust installation failed with exit code: $($Process.ExitCode)" $LogFile
        Write-Host "ERROR: Rust installation failed with exit code: $($Process.ExitCode)"
        Write-Host ""
        Write-Host "This often happens when the installer is corrupted or incompatible."
        Write-Host ""
        Write-Host "Recovery options:"
        Write-Host "1. Skip Rust installation and continue (Y)"
        Write-Host "2. Delete current installer and download latest version (d)"
        Write-Host "3. Exit installation (n)"
        Write-Host ""

        $Recovery = Read-Host "Choose option (Y/d/n)"
        if ($Recovery -match '^[Dd]') {
            Write-Log "User chose to re-download Rust installer" $LogFile
            Write-Host "Removing current installer and downloading latest version..."

            # Remove current installer
            if (Test-Path $RustupInstaller) {
                Remove-Item $RustupInstaller -Force
                Write-Log "Removed corrupted installer: $RustupInstaller" $LogFile
            }

            # Download latest rustup-init
            try {
                Write-Host "Downloading latest rustup-init installer..."
                $LatestUrl = "https://win.rustup.rs/x86_64"
                $NewInstallerPath = Join-Path $InstallersDir "rustup-init.exe"

                Invoke-WebRequest -Uri $LatestUrl -OutFile $NewInstallerPath -UserAgent "PowerShell/Portable-Dev-Setup"

                if (Test-Path $NewInstallerPath) {
                    Write-Log "Downloaded new installer: $NewInstallerPath" $LogFile
                    Write-Host "New installer downloaded successfully. Attempting installation..."

                    # Update the installer reference and retry installation
                    $RustupInstaller = $NewInstallerPath

                    # Retry installation with new installer
                    $RetryArgs = @(
                        "--default-toolchain", "stable"
                        "--default-host", "x86_64-pc-windows-msvc"
                        "--profile", "default"
                        "-y"  # Accept defaults without prompting
                    )

                    Write-Log "Retrying with new installer: $RustupInstaller $($RetryArgs -join ' ')" $LogFile
                    $RetryProcess = Start-Process -FilePath $RustupInstaller -ArgumentList $RetryArgs -Wait -PassThru -NoNewWindow

                    if ($RetryProcess.ExitCode -eq 0) {
                        Write-Log "Rust installation completed successfully with new installer" $LogFile
                        Write-Host "Rust installation completed successfully with new installer"
                        # Continue to verification section
                    } else {
                        throw "Rust installation failed even with new installer (exit code: $($RetryProcess.ExitCode))"
                    }
                } else {
                    throw "Failed to download new installer"
                }
            } catch {
                Write-Log "Failed to download new installer: $($_.Exception.Message)" $LogFile
                Write-Host "ERROR: Failed to download new installer: $($_.Exception.Message)"
                Write-Host "Please download Rust manually from https://rustup.rs/"
                exit 1
            }
        } elseif ($Recovery -notmatch '^[Nn]') {
            Write-Log "User chose to skip Rust installation after error" $LogFile
            Write-Host "Skipping Rust installation - you can install it later"
            return
        } else {
            throw "Rust installation failed with exit code: $($Process.ExitCode)"
        }
    }
    
    # Refresh environment variables to include Cargo bin directory
    Write-Log "Refreshing environment variables..." $LogFile
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    # Add Cargo bin to current session PATH if not already there
    $CargoPath = Join-Path $env:USERPROFILE ".cargo\bin"
    if ((Test-Path $CargoPath) -and ($env:Path -notlike "*$CargoPath*")) {
        $env:Path = "$CargoPath;$env:Path"
        Write-Log "Added $CargoPath to current session PATH" $LogFile
    }
    
    # Wait a moment for installation to complete
    Start-Sleep -Seconds 3
    
    # Verify installation
    Write-Log "Verifying Rust installation..." $LogFile
    Write-Host "Verifying Rust installation..."
    
    # Check for rustc
    $RustcPath = Get-Command "rustc" -ErrorAction SilentlyContinue
    if (-not $RustcPath) {
        # Try the default Cargo bin path
        $DefaultRustc = Join-Path $env:USERPROFILE ".cargo\bin\rustc.exe"
        if (Test-Path $DefaultRustc) {
            $RustcPath = $DefaultRustc
        }
    }
    
    # Check for cargo
    $CargoCmd = Get-Command "cargo" -ErrorAction SilentlyContinue
    if (-not $CargoCmd) {
        # Try the default Cargo bin path
        $DefaultCargo = Join-Path $env:USERPROFILE ".cargo\bin\cargo.exe"
        if (Test-Path $DefaultCargo) {
            $CargoCmd = $DefaultCargo
        }
    }
    
    if ($RustcPath -and $CargoCmd) {
        $RustcVersion = & $RustcPath --version 2>$null
        $CargoVersion = & $CargoCmd --version 2>$null
        $RustupVersion = & rustup --version 2>$null
        
        Write-Log "rustc version: $RustcVersion" $LogFile
        Write-Log "cargo version: $CargoVersion" $LogFile
        Write-Log "rustup version: $RustupVersion" $LogFile
        
        Write-Host "OK rustc installed successfully: $RustcVersion"
        Write-Host "OK cargo installed successfully: $CargoVersion"
        Write-Host "OK rustup installed successfully: $RustupVersion"
        
        # Install common Rust tools
        Write-Log "Installing common Rust tools..." $LogFile
        Write-Host "Installing common Rust tools..."
        
        $CommonTools = @(
            "clippy",      # Rust linter
            "rustfmt",     # Code formatter
            "rust-src",    # Source code for standard library
            "rust-docs"    # Offline documentation
        )
        
        foreach ($Tool in $CommonTools) {
            try {
                Write-Host "Installing $Tool..."
                $ToolProcess = Start-Process -FilePath "rustup" -ArgumentList @("component", "add", $Tool) -Wait -PassThru -NoNewWindow
                
                if ($ToolProcess.ExitCode -eq 0) {
                    Write-Log "Successfully installed $Tool" $LogFile
                    Write-Host "OK $Tool installed successfully"
                } else {
                    Write-Log "Failed to install $Tool (exit code: $($ToolProcess.ExitCode))" $LogFile
                    Write-Host "WARNING Failed to install $Tool"
                }
            } catch {
                Write-Log "Error installing ${Tool}: $($_.Exception.Message)" $LogFile
                Write-Host "WARNING Error installing $Tool"
            }
        }
        
        # Set up Cargo configuration for Windows
        $CargoConfigDir = Join-Path $env:USERPROFILE ".cargo"
        $CargoConfigFile = Join-Path $CargoConfigDir "config.toml"
        
        if (-not (Test-Path $CargoConfigFile)) {
            Write-Log "Creating Cargo configuration file..." $LogFile
            Write-Host "Creating Cargo configuration file..."
            
            $CargoConfig = @"
# Cargo configuration for Windows development
[build]
# Use the MSVC linker for better Windows compatibility
target = "x86_64-pc-windows-msvc"

[target.x86_64-pc-windows-msvc]
# Use the Microsoft C++ Build Tools linker
linker = "link.exe"

[net]
# Use Git CLI for private repositories
git-fetch-with-cli = true
"@
            
            try {
                $CargoConfig | Out-File -FilePath $CargoConfigFile -Encoding UTF8
                Write-Log "Cargo configuration created at $CargoConfigFile" $LogFile
                Write-Host "OK Cargo configuration created"
            } catch {
                Write-Log "Failed to create Cargo configuration: $($_.Exception.Message)" $LogFile
                Write-Host "WARNING Failed to create Cargo configuration"
            }
        }
        
    } else {
        throw "Rust installation verification failed - rustc or cargo command not found"
    }
    
    Write-Log "Rust installation completed successfully" $LogFile
    
} catch {
    $ErrorMessage = "Rust installation failed: $($_.Exception.Message)"
    Write-Log $ErrorMessage $LogFile
    Write-Error $ErrorMessage
    exit 1
}
