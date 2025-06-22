# ============================================================================
# Windows Build Tools Installation Script
# ============================================================================
# This script installs Windows Build Tools (Visual Studio Build Tools + Python)
# required for compiling native Node.js modules.
# ============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$LogFile
)

# Import utility functions
. "$PSScriptRoot\utils.ps1"

Write-Log "Starting Windows Build Tools installation..." $LogFile

# Function definitions (must be before main script logic)
function Install-AlternativeBuildTools {
    Write-Log "Installing alternative build tools..." $LogFile
    Write-Host "Installing alternative build tools..."
    
    # Install node-gyp globally
    try {
        Write-Host "Installing node-gyp..."
        $Process = Start-Process -FilePath "npm" -ArgumentList @("install", "-g", "node-gyp") -Wait -PassThru -NoNewWindow
        
        if ($Process.ExitCode -eq 0) {
            Write-Log "node-gyp installed successfully" $LogFile
            Write-Host "OK node-gyp installed successfully"
        } else {
            Write-Log "node-gyp installation failed" $LogFile
            Write-Host "WARNING node-gyp installation failed"
        }
    } catch {
        Write-Log "node-gyp installation error: $($_.Exception.Message)" $LogFile
        Write-Host "WARNING node-gyp installation error"
    }
    
    # Provide manual installation instructions
    Write-Host ""
    Write-Host "Manual Build Tools Installation Required"
    Write-Host "======================================="
    Write-Host "Please manually install the following:"
    Write-Host ""
    Write-Host "1. Visual Studio Build Tools 2019 or later:"
    Write-Host "   https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2019"
    Write-Host "   - Select 'C++ build tools' workload"
    Write-Host "   - Include Windows 10 SDK"
    Write-Host ""
    Write-Host "2. Python 3.x:"
    Write-Host "   https://www.python.org/downloads/"
    Write-Host "   - Make sure to check 'Add Python to PATH'"
    Write-Host ""
    Write-Host "After manual installation, you can test with:"
    Write-Host "   npm install -g node-sass"
    Write-Host ""
    
    Write-Log "Provided manual installation instructions" $LogFile
}

function Test-BuildTools {
    Write-Log "Testing build tools with a simple compilation..." $LogFile
    Write-Host "Testing build tools with a simple compilation..."
    
    try {
        # Create a temporary directory for testing
        $TestDir = Join-Path $env:TEMP "build-tools-test"
        if (Test-Path $TestDir) {
            Remove-Item $TestDir -Recurse -Force
        }
        New-Item -ItemType Directory -Path $TestDir -Force | Out-Null
        
        # Create a simple package.json for testing
        $PackageJson = @{
            name = "build-tools-test"
            version = "1.0.0"
            dependencies = @{
                "node-sass" = "latest"
            }
        } | ConvertTo-Json
        
        $PackageJsonPath = Join-Path $TestDir "package.json"
        $PackageJson | Out-File -FilePath $PackageJsonPath -Encoding UTF8
        
        # Try to install a native module
        Push-Location $TestDir
        
        # Use separate files for stdout and stderr
        $StdOutFile = Join-Path $TestDir "test-output.log"
        $StdErrFile = Join-Path $TestDir "test-error.log"
        
        $TestProcess = Start-Process -FilePath "npm" -ArgumentList @("install", "--no-save") -Wait -PassThru -NoNewWindow -RedirectStandardOutput $StdOutFile -RedirectStandardError $StdErrFile
        
        Pop-Location
        
        if ($TestProcess.ExitCode -eq 0) {
            Write-Log "Build tools test successful" $LogFile
            Write-Host "OK Build tools test successful - native modules can be compiled"
        } else {
            $ErrorOutput = ""
            if (Test-Path $StdErrFile) {
                $ErrorOutput = Get-Content $StdErrFile -Raw
            }
            Write-Log "Build tools test failed: $ErrorOutput" $LogFile
            Write-Host "WARNING Build tools test failed - native module compilation may not work"
        }
        
        # Clean up test directory
        if (Test-Path $TestDir) {
            Remove-Item $TestDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        
    } catch {
        Write-Log "Build tools test error: $($_.Exception.Message)" $LogFile
        Write-Host "WARNING Build tools test error: $($_.Exception.Message)"
    }
}

# Main script logic
try {
    Write-Host "Installing Windows Build Tools..."
    Write-Host "This may take a while and requires an internet connection."
    Write-Host ""
    
    # Check if Node.js and npm are available
    $NodePath = Get-Command "node" -ErrorAction SilentlyContinue
    $NpmPath = Get-Command "npm" -ErrorAction SilentlyContinue
    
    if (-not $NodePath -or -not $NpmPath) {
        throw "Node.js and npm are required but not found in PATH. Please install Node.js first."
    }
    
    $NodeVersion = & node --version 2>$null
    $NpmVersion = & npm --version 2>$null
    
    Write-Log "Node.js version: $NodeVersion" $LogFile
    Write-Log "npm version: $NpmVersion" $LogFile
    Write-Host "OK Node.js found: $NodeVersion"
    Write-Host "OK npm found: $NpmVersion"
    
    # Check if Visual Studio Build Tools are already installed
    $VsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $VsWhere) {
        try {
            $VsInstallations = & $VsWhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -format json | ConvertFrom-Json
            if ($VsInstallations -and $VsInstallations.Count -gt 0) {
                Write-Log "Visual Studio Build Tools already installed" $LogFile
                Write-Host "OK Visual Studio Build Tools already installed"
            }
        } catch {
            # Continue with installation if vswhere fails
        }
    }
    
    # Check if Python is already installed
    $PythonPath = Get-Command "python" -ErrorAction SilentlyContinue
    if ($PythonPath) {
        try {
            $PythonVersion = & python --version 2>$null
            Write-Log "Python already installed: $PythonVersion" $LogFile
            Write-Host "OK Python already installed: $PythonVersion"
        } catch {
            # Continue with installation if python version check fails
        }
    }
    
    # Install windows-build-tools via npm
    Write-Log "Installing windows-build-tools via npm..." $LogFile
    Write-Host "Installing windows-build-tools via npm..."
    Write-Host "Note: This will install Visual Studio Build Tools and Python 3.x"
    Write-Host ""
    
    try {
        # Create log file for npm output
        $NpmLogDir = Split-Path $LogFile -Parent
        $NpmStdOutFile = Join-Path $NpmLogDir "npm-stdout.log"
        $NpmStdErrFile = Join-Path $NpmLogDir "npm-stderr.log"
        
        $InstallArgs = @(
            "install"
            "-g"
            "windows-build-tools"
            "--vs2015"
            "--verbose"
        )
        
        Write-Log "Running: npm $($InstallArgs -join ' ')" $LogFile
        
        # Use separate files for stdout and stderr to avoid PowerShell error
        $Process = Start-Process -FilePath "npm" -ArgumentList $InstallArgs -Wait -PassThru -NoNewWindow -RedirectStandardOutput $NpmStdOutFile -RedirectStandardError $NpmStdErrFile
        
        # Read and log npm output
        if (Test-Path $NpmStdOutFile) {
            $NpmOutput = Get-Content $NpmStdOutFile -Raw
            Write-Log "npm install stdout: $NpmOutput" $LogFile
        }
        if (Test-Path $NpmStdErrFile) {
            $NpmError = Get-Content $NpmStdErrFile -Raw
            Write-Log "npm install stderr: $NpmError" $LogFile
        }
        
        if ($Process.ExitCode -eq 0) {
            Write-Log "windows-build-tools installation completed successfully" $LogFile
            Write-Host "OK windows-build-tools installation completed successfully"
        } else {
            # Try alternative approach with individual tools
            Write-Log "windows-build-tools installation failed, trying alternative approach..." $LogFile
            Write-Host "WARNING windows-build-tools installation failed, trying alternative approach..."
            Install-AlternativeBuildTools
        }
        
    } catch {
        Write-Log "windows-build-tools installation error: $($_.Exception.Message)" $LogFile
        Write-Host "WARNING windows-build-tools installation error, trying alternative approach..."
        Install-AlternativeBuildTools
    }
    
    # Verify installation
    Write-Log "Verifying build tools installation..." $LogFile
    Write-Host "Verifying build tools installation..."
    
    # Test with a simple native module compilation
    Test-BuildTools
    
    Write-Log "Windows Build Tools installation completed" $LogFile
    
} catch {
    $ErrorMessage = "Windows Build Tools installation failed: $($_.Exception.Message)"
    Write-Log $ErrorMessage $LogFile
    Write-Error $ErrorMessage
    exit 1
}
