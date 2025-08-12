#!/usr/bin/env pwsh
# Windows构建环境测试脚本
# 验证ESP32-S3 + W5500 Windows构建环境配置

param(
    [switch]$Debug = $false
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "ESP32-S3 + W5500 Windows构建环境测试" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 1. 检查ESP-IDF路径
Write-Host "`n1. 检查ESP-IDF路径..." -ForegroundColor Yellow
$espIdfPaths = @(
    "C:\esp\esp-idf",
    "C:\Espressif\frameworks\esp-idf-v5.1.2",
    "C:\Espressif\frameworks\esp-idf"
)

$espIdfPath = $null
foreach ($path in $espIdfPaths) {
    if (Test-Path $path) {
        $espIdfPath = $path
        Write-Host "   ✅ 找到ESP-IDF: $path" -ForegroundColor Green
        break
    }
}

if (-not $espIdfPath) {
    Write-Host "   ❌ 未找到ESP-IDF" -ForegroundColor Red
    exit 1
}

# 2. 检查工具链文件
Write-Host "`n2. 检查CMake工具链文件..." -ForegroundColor Yellow
$toolchainFile = Join-Path $espIdfPath "tools\cmake\toolchain-esp32s3.cmake"
if (Test-Path $toolchainFile) {
    Write-Host "   ✅ 找到工具链文件: $toolchainFile" -ForegroundColor Green
} else {
    Write-Host "   ❌ 未找到工具链文件: $toolchainFile" -ForegroundColor Red
    exit 1
}

# 3. 检查编译器
Write-Host "`n3. 检查ESP32-S3编译器..." -ForegroundColor Yellow
$compiler = Get-Command "xtensa-esp32s3-elf-gcc" -ErrorAction SilentlyContinue
if ($compiler) {
    Write-Host "   ✅ 找到编译器: $($compiler.Source)" -ForegroundColor Green
    & $compiler.Source --version | Select-Object -First 1 | ForEach-Object { Write-Host "      $_" -ForegroundColor Gray }
} else {
    Write-Host "   ❌ 未找到xtensa-esp32s3-elf-gcc编译器" -ForegroundColor Red
    exit 1
}

# 4. 检查Ninja
Write-Host "`n4. 检查Ninja构建工具..." -ForegroundColor Yellow
$ninja = Get-Command "ninja" -ErrorAction SilentlyContinue
if ($ninja) {
    Write-Host "   ✅ 找到Ninja: $($ninja.Source)" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  未找到Ninja，尝试安装..." -ForegroundColor Yellow
    try {
        choco install ninja -y
        $ninja = Get-Command "ninja" -ErrorAction SilentlyContinue
        if ($ninja) {
            Write-Host "   ✅ Ninja安装成功" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Ninja安装失败" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "   ❌ Ninja安装错误: $_" -ForegroundColor Red
        exit 1
    }
}

# 5. 检查CMake预设
Write-Host "`n5. 检查CMake预设文件..." -ForegroundColor Yellow
$presetsFile = "CMakePresets-W5500-Windows.json"
if (Test-Path $presetsFile) {
    Write-Host "   ✅ 找到Windows CMake预设: $presetsFile" -ForegroundColor Green
} else {
    Write-Host "   ❌ 未找到Windows CMake预设文件" -ForegroundColor Red
    exit 1
}

# 6. 验证环境变量
Write-Host "`n6. 验证环境变量..." -ForegroundColor Yellow
$envVars = @{
    "IDF_PATH" = $espIdfPath
    "IDF_TOOLS_PATH" = "C:\Espressif"
}

foreach ($var in $envVars.GetEnumerator()) {
    [Environment]::SetEnvironmentVariable($var.Key, $var.Value, "Process")
    Write-Host "   ✅ 设置 $($var.Key) = $($var.Value)" -ForegroundColor Green
}

# 7. 测试CMake配置
Write-Host "`n7. 测试CMake配置..." -ForegroundColor Yellow
$buildDir = "build-test"
if (Test-Path $buildDir) {
    Remove-Item -Recurse -Force $buildDir
}

New-Item -ItemType Directory -Path $buildDir | Out-Null
Push-Location $buildDir

try {
    $cmakeArgs = @(
        "--preset", "ESP32_S3_W5500_Release"
    )
    
    if ($Debug) {
        Write-Host "   运行: cmake $cmakeArgs" -ForegroundColor Gray
    }
    
    $process = Start-Process -FilePath "cmake" -ArgumentList $cmakeArgs -NoNewWindow -PassThru -Wait -RedirectStandardOutput "cmake-output.log" -RedirectStandardError "cmake-error.log"
    
    if ($process.ExitCode -eq 0) {
        Write-Host "   ✅ CMake配置成功" -ForegroundColor Green
    } else {
        Write-Host "   ❌ CMake配置失败 (退出码: $($process.ExitCode))" -ForegroundColor Red
        if (Test-Path "cmake-error.log") {
            Write-Host "   错误日志:" -ForegroundColor Red
            Get-Content "cmake-error.log" | ForEach-Object { Write-Host "      $_" -ForegroundColor Red }
        }
        exit 1
    }
} finally {
    Pop-Location
    if (Test-Path $buildDir) {
        Remove-Item -Recurse -Force $buildDir
    }
}

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "所有测试通过！Windows构建环境配置正确" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan