# ============================================================================
# Installation Verification Script
# ============================================================================
# This script verifies that all development tools are properly installed
# and configured for the portable dev setup.
# ============================================================================

param(
    [switch]$Detailed
)

# Import utility functions
$UtilsPath = Join-Path $PSScriptRoot "utils.ps1"
if (Test-Path $UtilsPath) {
    . $UtilsPath
}

Write-Host "============================================================================"
Write-Host "Portable Dev Setup - Installation Verification"
Write-Host "============================================================================"
Write-Host ""

$AllPassed = $true
$Results = @()

# Function to test a command and record results
function Test-Tool {
    param(
        [string]$Name,
        [string]$Command,
        [string]$VersionArg = "--version",
        [string]$ExpectedPattern = ".*"
    )
    
    Write-Host "Testing $Name..." -NoNewline
    
    try {
        $CommandPath = Get-Command $Command -ErrorAction SilentlyContinue
        if (-not $CommandPath) {
            Write-Host " ERROR NOT FOUND" -ForegroundColor Red
            return @{
                Tool = $Name
                Status = "NOT FOUND"
                Version = "N/A"
                Path = "N/A"
                Passed = $false
            }
        }
        
        $VersionOutput = & $Command $VersionArg 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host " ERROR" -ForegroundColor Red
            return @{
                Tool = $Name
                Status = "ERROR"
                Version = "Command failed"
                Path = $CommandPath.Source
                Passed = $false
            }
        }
        
        $Version = ($VersionOutput | Select-Object -First 1) -replace $ExpectedPattern, '$1'
        Write-Host " OK" -ForegroundColor Green
        
        return @{
            Tool = $Name
            Status = "OK"
            Version = $Version.Trim()
            Path = $CommandPath.Source
            Passed = $true
        }
        
    } catch {
        Write-Host " ERROR" -ForegroundColor Red
        return @{
            Tool = $Name
            Status = "ERROR"
            Version = $_.Exception.Message
            Path = "N/A"
            Passed = $false
        }
    }
}

# Test all development tools
Write-Host "Checking Development Tools:"
Write-Host "----------------------------"

$Results += Test-Tool "Node.js" "node" "--version" "v(.*)"
$Results += Test-Tool "npm" "npm" "--version" "(.*)"
$Results += Test-Tool "Rust Compiler" "rustc" "--version" "rustc ([\d\.]+)"
$Results += Test-Tool "Cargo" "cargo" "--version" "cargo ([\d\.]+)"
$Results += Test-Tool "Git" "git" "--version" "git version ([\d\.]+)"
$Results += Test-Tool "GitHub CLI" "gh" "--version" "gh version ([\d\.]+)"

Write-Host ""
Write-Host "Checking Additional Tools:"
Write-Host "--------------------------"

# Test for optional tools
$Results += Test-Tool "rustup" "rustup" "--version" "rustup ([\d\.]+)"
$Results += Test-Tool "node-gyp" "node-gyp" "--version" "(.*)"

Write-Host ""

# Check for failed installations
$FailedTools = $Results | Where-Object { -not $_.Passed }
if ($FailedTools.Count -gt 0) {
    $AllPassed = $false
    Write-Host "ERROR Some tools failed verification:" -ForegroundColor Red
    foreach ($Tool in $FailedTools) {
        Write-Host "   - $($Tool.Tool): $($Tool.Status)" -ForegroundColor Red
    }
} else {
    Write-Host "OK All tools verified successfully!" -ForegroundColor Green
}

Write-Host ""

# Test Git configuration
Write-Host "Checking Git Configuration:"
Write-Host "---------------------------"

try {
    $GitUser = & git config --global user.name 2>$null
    $GitEmail = & git config --global user.email 2>$null
    $GitCredHelper = & git config --global credential.helper 2>$null
    
    if ($GitUser -and $GitEmail) {
        Write-Host "OK Git user configured: $GitUser <$GitEmail>" -ForegroundColor Green
    } else {
        Write-Host "ERROR Git user not configured" -ForegroundColor Red
        $AllPassed = $false
    }
    
    if ($GitCredHelper) {
        Write-Host "OK Git credential helper: $GitCredHelper" -ForegroundColor Green
    } else {
        Write-Host "WARNING Git credential helper not configured" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR Error checking Git configuration: $($_.Exception.Message)" -ForegroundColor Red
    $AllPassed = $false
}

Write-Host ""

# Test GitHub CLI authentication
Write-Host "Checking GitHub CLI Authentication:"
Write-Host "-----------------------------------"

try {
    $AuthStatus = & gh auth status 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK GitHub CLI authenticated" -ForegroundColor Green
        if ($Detailed) {
            Write-Host $AuthStatus
        }
    } else {
        Write-Host "WARNING GitHub CLI not authenticated" -ForegroundColor Yellow
        Write-Host "   Run 'gh auth login' to authenticate"
    }
} catch {
    Write-Host "ERROR Error checking GitHub CLI authentication: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test build tools
Write-Host "Checking Build Tools:"
Write-Host "--------------------"

# Check for Visual Studio Build Tools
$VSWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $VSWhere) {
    try {
        $VSInstallations = & $VSWhere -products * -requires Microsoft.VisualStudio.Workload.VCTools -format json 2>$null | ConvertFrom-Json
        if ($VSInstallations -and $VSInstallations.Count -gt 0) {
            Write-Host "OK Visual Studio Build Tools found" -ForegroundColor Green
        } else {
            Write-Host "WARNING Visual Studio Build Tools not found" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "WARNING Could not check Visual Studio Build Tools" -ForegroundColor Yellow
    }
} else {
    Write-Host "WARNING Visual Studio Build Tools not detected" -ForegroundColor Yellow
}

# Check for Python
$PythonPath = Get-Command "python" -ErrorAction SilentlyContinue
if ($PythonPath) {
    try {
        $PythonVersion = & python --version 2>$null
        Write-Host "OK Python found: $PythonVersion" -ForegroundColor Green
    } catch {
        Write-Host "WARNING Python found but version check failed" -ForegroundColor Yellow
    }
} else {
    Write-Host "WARNING Python not found in PATH" -ForegroundColor Yellow
}

Write-Host ""

# Display detailed results if requested
if ($Detailed) {
    Write-Host "Detailed Results:"
    Write-Host "=================="
    $Results | Format-Table -Property Tool, Status, Version, Path -AutoSize
    Write-Host ""
}

# System information
if ($Detailed) {
    Write-Host "System Information:"
    Write-Host "==================="
    
    if (Get-Command "Get-SystemInfo" -ErrorAction SilentlyContinue) {
        $SysInfo = Get-SystemInfo
        Write-Host "OS: $($SysInfo.OSName) $($SysInfo.OSVersion)"
        Write-Host "Architecture: $($SysInfo.OSArchitecture)"
        Write-Host "CPU: $($SysInfo.CPUName)"
        Write-Host "Memory: $($SysInfo.TotalMemoryGB) GB"
        Write-Host "PowerShell: $($SysInfo.PowerShellVersion)"
    } else {
        $OS = Get-CimInstance -ClassName Win32_OperatingSystem
        Write-Host "OS: $($OS.Caption) $($OS.Version)"
        Write-Host "Architecture: $($OS.OSArchitecture)"
        Write-Host "PowerShell: $($PSVersionTable.PSVersion)"
    }
    Write-Host ""
}

# Final summary
Write-Host "============================================================================"
if ($AllPassed) {
    Write-Host "Installation verification PASSED! Your dev environment is ready." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "- Start coding with your favorite editor"
    Write-Host "- Clone repositories with: git clone <url>"
    Write-Host "- Install npm packages with: npm install"
    Write-Host "- Create Rust projects with: cargo new <project>"
} else {
    Write-Host "WARNING Installation verification found issues. Check the details above." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Troubleshooting:"
    Write-Host "- See TROUBLESHOOTING.md for common solutions"
    Write-Host "- Check installation logs in the logs/ folder"
    Write-Host "- Try running install.bat again"
}
Write-Host "============================================================================"
