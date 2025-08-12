# ESP32-S3 Toolchain Installation and Verification Script for Windows
# This script ensures ESP-IDF tools including xtensa-esp32s3-elf-gcc are properly installed

param(
    [switch]$Verbose,
    [switch]$ForceInstall
)

# Set error handling
$ErrorActionPreference = "Stop"

Write-Host "=== ESP32-S3 Toolchain Installation and Verification ===" -ForegroundColor Green

# Define paths
$espToolsPath = "C:\Espressif"
$idfPath = "C:\esp\esp-idf"

function Test-EspToolchain {
    Write-Host "Checking ESP32-S3 toolchain installation..." -ForegroundColor Yellow
    
    # Check if ESP-IDF is installed
    if (-not (Test-Path $idfPath)) {
        Write-Host "❌ ESP-IDF not found at $idfPath" -ForegroundColor Red
        return $false
    }
    
    # Check if tools are installed
    if (-not (Test-Path $espToolsPath)) {
        Write-Host "❌ ESP-IDF tools not found at $espToolsPath" -ForegroundColor Red
        return $false
    }
    
    # Look for xtensa-esp32s3-elf-gcc
    $possiblePaths = @(
        "$espToolsPath\tools\xtensa-esp32s3-elf\*\xtensa-esp32s3-elf\bin\xtensa-esp32s3-elf-gcc.exe",
        "$espToolsPath\tools\xtensa-esp32s3-elf\esp-2023r1\8.1.0\xtensa-esp32s3-elf\bin\xtensa-esp32s3-elf-gcc.exe",
        "$espToolsPath\tools\xtensa-esp32s3-elf\esp-2023r1\xtensa-esp32s3-elf\bin\xtensa-esp32s3-elf-gcc.exe"
    )
    
    $gccFound = $false
    foreach ($path in $possiblePaths) {
        $gccPath = Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($gccPath) {
            Write-Host "✅ xtensa-esp32s3-elf-gcc found: $($gccPath.FullName)" -ForegroundColor Green
            $gccFound = $true
            
            # Test the compiler
            try {
                $version = & $gccPath.FullName --version 2>$null
                Write-Host "Compiler version: $($version[0])" -ForegroundColor Cyan
            } catch {
                Write-Host "❌ Compiler test failed: $_" -ForegroundColor Red
                return $false
            }
            break
        }
    }
    
    if (-not $gccFound) {
        Write-Host "❌ xtensa-esp32s3-elf-gcc not found" -ForegroundColor Red
        return $false
    }
    
    return $true
}

function Install-EspTools {
    Write-Host "Installing ESP-IDF tools..." -ForegroundColor Yellow
    
    if (-not (Test-Path $idfPath)) {
        Write-Host "❌ ESP-IDF directory not found: $idfPath" -ForegroundColor Red
        Write-Host "Please install ESP-IDF first" -ForegroundColor Red
        return $false
    }
    
    try {
        # Change to ESP-IDF directory
        Push-Location $idfPath
        
        # Install tools using ESP-IDF's install script
        Write-Host "Running ESP-IDF tools installation..." -ForegroundColor Yellow
        
        # Use PowerShell to run the install script
        $installScript = ".\install.bat"
        if (Test-Path $installScript) {
            Write-Host "Using install.bat..." -ForegroundColor Cyan
            & cmd.exe /c $installScript esp32s3
        } else {
            Write-Host "Using install.ps1..." -ForegroundColor Cyan
            & .\install.ps1 esp32s3
        }
        
        Pop-Location
        
        Write-Host "✅ ESP-IDF tools installation completed" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "❌ ESP-IDF tools installation failed: $_" -ForegroundColor Red
        Pop-Location -ErrorAction SilentlyContinue
        return $false
    }
}

function Show-ToolPaths {
    Write-Host "=== Available ESP-IDF Tools ===" -ForegroundColor Yellow
    
    if (Test-Path "$espToolsPath\tools") {
        Write-Host "Tools directory contents:" -ForegroundColor Cyan
        Get-ChildItem -Path "$espToolsPath\tools" -Directory | ForEach-Object {
            Write-Host "  📁 $($_.Name)" -ForegroundColor White
        }
    } else {
        Write-Host "❌ Tools directory not found: $espToolsPath\tools" -ForegroundColor Red
    }
    
    # Show specific toolchain directories
    $xtensaDir = "$espToolsPath\tools\xtensa-esp32s3-elf"
    if (Test-Path $xtensaDir) {
        Write-Host "ESP32-S3 toolchain directory:" -ForegroundColor Cyan
        Get-ChildItem -Path $xtensaDir -Directory | ForEach-Object {
            Write-Host "  📁 $($_.Name)" -ForegroundColor White
        }
    }
}

# Main execution
Write-Host "ESP-IDF Path: $idfPath" -ForegroundColor Cyan
Write-Host "ESP-IDF Tools Path: $espToolsPath" -ForegroundColor Cyan

# Check current toolchain
$toolchainOk = Test-EspToolchain

if (-not $toolchainOk -or $ForceInstall) {
    Write-Host "Toolchain not found or forced install requested" -ForegroundColor Yellow
    
    $installSuccess = Install-EspTools
    if ($installSuccess) {
        Write-Host "🔄 Re-checking toolchain after installation..." -ForegroundColor Yellow
        $toolchainOk = Test-EspToolchain
    }
}

# Show available tools
if ($Verbose) {
    Show-ToolPaths
}

# Final status
if ($toolchainOk) {
    Write-Host "✅ ESP32-S3 toolchain is ready for use!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "❌ ESP32-S3 toolchain installation incomplete" -ForegroundColor Red
    Write-Host "Please check ESP-IDF installation and run this script again" -ForegroundColor Yellow
    exit 1
}