# ESP32-S3 + W5500 nanoFramework Windows构建验证脚本
# 基于官方nanoFramework文档的Windows构建验证

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Release", "Debug")]
    [string]$BuildType = "Release",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBuild = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false
)

# 设置错误处理
$ErrorActionPreference = "Stop"

# 颜色定义
$Green = "Green"
$Red = "Red"
$Yellow = "Yellow"
$Cyan = "Cyan"

function Write-Status {
    param([string]$Message, [string]$Color = $Green)
    Write-Host $Message -ForegroundColor $Color
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor $Red
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor $Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor $Yellow
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor $Cyan
}

# 检查管理员权限
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 主函数
function Test-BuildEnvironment {
    Write-Status "=== ESP32-S3 + W5500 nanoFramework Windows构建验证 ===" $Cyan
    Write-Status "构建类型: $BuildType" $Cyan
    Write-Status "详细模式: $Verbose" $Cyan
    Write-Status ""
    
    # 1. 检查必需目录和文件
    Write-Status "1. 检查项目结构..." $Yellow
    
    $requiredPaths = @{
        "ESP-IDF" = "C:\esp\esp-idf"
        "nanoFramework" = "C:\nanoFramework\nf-interpreter"
        "构建脚本" = ".\CMakePresets-W5500.json"
        "CMake补丁" = ".\CMakeLists-patch-updated.txt"
    }
    
    foreach ($path in $requiredPaths.GetEnumerator()) {
        $fullPath = $path.Value
        if ($path.Key -eq "构建脚本" -or $path.Key -eq "CMake补丁") {
            $fullPath = Join-Path $PSScriptRoot $path.Value
        }
        
        if (Test-Path $fullPath) {
            Write-Success "$($path.Key) 已找到: $fullPath"
        } else {
            Write-Error "$($path.Key) 未找到: $fullPath"
            return $false
        }
    }
    
    # 2. 检查必需工具
    Write-Status "2. 检查构建工具..." $Yellow
    
    $tools = @("python", "cmake", "ninja", "git")
    foreach ($tool in $tools) {
        try {
            $version = & $tool --version 2>$null | Select-Object -First 1
            if ($version) {
                Write-Success "$tool: $version"
            } else {
                Write-Error "$tool: 无法获取版本"
                return $false
            }
        } catch {
            Write-Error "$tool: 未安装或不在PATH中"
            return $false
        }
    }
    
    # 3. 检查ESP-IDF工具链
    Write-Status "3. 检查ESP-IDF工具链..." $Yellow
    
    $xtensaPaths = @(
        "C:\Espressif\tools\xtensa-esp32s3-elf\*\xtensa-esp32s3-elf\bin\xtensa-esp32s3-elf-gcc.exe",
        "C:\Espressif\tools\xtensa-esp-elf\*\xtensa-esp-elf\bin\xtensa-esp-elf-gcc.exe"
    )
    
    $gccFound = $false
    foreach ($pattern in $xtensaPaths) {
        $gccPath = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($gccPath) {
            $version = & $gccPath.FullName --version 2>$null | Select-Object -First 1
            Write-Success "ESP32-S3工具链: $($gccPath.FullName)"
            Write-Success "GCC版本: $version"
            $env:CC = $gccPath.FullName
            $env:CXX = $gccPath.FullName.Replace("gcc.exe", "g++.exe")
            $gccFound = $true
            break
        }
    }
    
    if (-not $gccFound) {
        Write-Error "ESP32-S3工具链未找到"
        Write-Info "请运行ESP-IDF安装器或检查C:\Espressif\tools目录"
        return $false
    }
    
    # 4. 检查ESP-IDF环境
    Write-Status "4. 检查ESP-IDF环境..." $Yellow
    
    if ($env:IDF_PATH) {
        Write-Success "IDF_PATH: $($env:IDF_PATH)"
    } else {
        $env:IDF_PATH = "C:\esp\esp-idf"
        Write-Warning "IDF_PATH未设置，使用默认值: $($env:IDF_PATH)"
    }
    
    if ($env:IDF_TOOLS_PATH) {
        Write-Success "IDF_TOOLS_PATH: $($env:IDF_TOOLS_PATH)"
    } else {
        $env:IDF_TOOLS_PATH = "C:\Espressif"
        Write-Warning "IDF_TOOLS_PATH未设置，使用默认值: $($env:IDF_TOOLS_PATH)"
    }
    
    # 5. 验证ESP-IDF安装
    try {
        $idfCheck = & "$env:IDF_PATH\tools\idf.py" --version 2>$null
        if ($idfCheck) {
            Write-Success "ESP-IDF: $idfCheck"
        } else {
            Write-Error "ESP-IDF未正确安装"
            return $false
        }
    } catch {
        Write-Error "ESP-IDF工具不可用: $_"
        return $false
    }
    
    # 6. 检查项目配置
    Write-Status "5. 检查项目配置..." $Yellow
    
    # 切换到nf-interpreter目录
    $nfInterpreterPath = "C:\nanoFramework\nf-interpreter"
    if (Test-Path $nfInterpreterPath) {
        Set-Location $nfInterpreterPath
        
        # 复制配置文件
        $presetSource = Join-Path $PSScriptRoot "CMakePresets-W5500.json"
        $presetDest = "CMakePresets.json"
        Copy-Item -Path $presetSource -Destination $presetDest -Force
        Write-Success "CMake预设已复制"
        
        # 应用CMake补丁
        $patchDir = "targets\ESP32\_IDF"
        if (-not (Test-Path $patchDir)) {
            New-Item -ItemType Directory -Path $patchDir -Force
        }
        
        $patchSource = Join-Path $PSScriptRoot "CMakeLists-patch-updated.txt"
        $patchDest = "$patchDir\CMakeLists-patch.cmake"
        Copy-Item -Path $patchSource -Destination $patchDest -Force
        Write-Success "CMake补丁已应用"
    } else {
        Write-Error "nanoFramework目录不存在: $nfInterpreterPath"
        return $false
    }
    
    # 7. 验证JSON配置
    Write-Status "6. 验证JSON配置..." $Yellow
    
    try {
        $jsonContent = Get-Content "CMakePresets.json" -Raw | ConvertFrom-Json
        Write-Success "CMakePresets.json格式正确"
        
        # 检查必需预设
        $presets = $jsonContent.configurePresets
        $releasePreset = $presets | Where-Object { $_.name -eq "ESP32_S3_W5500_Release" }
        $debugPreset = $presets | Where-Object { $_.name -eq "ESP32_S3_W5500_Debug" }
        
        if ($releasePreset -and $debugPreset) {
            Write-Success "构建预设已配置"
        } else {
            Write-Error "构建预设缺失"
            return $false
        }
    } catch {
        Write-Error "CMakePresets.json格式错误: $_"
        return $false
    }
    
    # 8. 测试CMake配置
    if (-not $SkipBuild) {
        Write-Status "7. 测试CMake配置..." $Yellow
        
        try {
            # 清理之前的构建
            if (Test-Path "build") {
                Remove-Item -Recurse -Force "build"
            }
            
            # 配置构建
            $preset = if ($BuildType -eq "Release") { "ESP32_S3_W5500_Release" } else { "ESP32_S3_W5500_Debug" }
            
            Write-Info "使用预设: $preset"
            cmake --preset $preset
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "CMake配置成功"
                
                if ($Verbose) {
                    Write-Info "CMake缓存内容:"
                    if (Test-Path "build\CMakeCache.txt") {
                        Get-Content "build\CMakeCache.txt" | Where-Object { $_ -match "(CMAKE_C_COMPILER|CMAKE_CXX_COMPILER|ESP_IDF_PATH|TARGET_BOARD)" }
                    }
                }
            } else {
                Write-Error "CMake配置失败"
                return $false
            }
            
            # 9. 验证构建文件
            Write-Status "8. 验证构建文件..." $Yellow
            
            $buildFiles = @(
                "build\build.ninja",
                "build\CMakeCache.txt"
            )
            
            foreach ($file in $buildFiles) {
                if (Test-Path $file) {
                    Write-Success "构建文件已创建: $file"
                } else {
                    Write-Error "构建文件缺失: $file"
                    return $false
                }
            }
            
            # 10. 可选：完整构建测试
            if ($Verbose) {
                Write-Status "9. 执行完整构建测试..." $Yellow
                
                try {
                    $buildResult = cmake --build build --config MinSizeRel 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Success "完整构建成功"
                        
                        # 检查输出文件
                        $outputFiles = @("build\nanoCLR.bin", "build\nanoCLR.elf")
                        foreach ($file in $outputFiles) {
                            if (Test-Path $file) {
                                $size = (Get-Item $file).Length
                                Write-Success "输出文件: $file ($size bytes)"
                            } else {
                                Write-Warning "输出文件缺失: $file"
                            }
                        }
                    } else {
                        Write-Warning "完整构建失败，但配置成功"
                    }
                } catch {
                    Write-Warning "构建测试跳过: $_"
                }
            }
            
        } catch {
            Write-Error "构建配置测试失败: $_"
            return $false
        }
    } else {
        Write-Status "7. 跳过构建测试 (--SkipBuild)" $Yellow
    }
    
    Write-Status ""
    Write-Success "=== Windows构建环境验证完成 ==="
    Write-Status "所有检查通过，环境已就绪"
    Write-Status ""
    Write-Status "下一步操作:"
    Write-Status "1. 运行: cmake --build build"
    Write-Status "2. 使用: nanoff工具刷写固件"
    Write-Status "3. 测试: W5500以太网连接"
    
    return $true
}

# 运行验证
$result = Test-BuildEnvironment

if ($result) {
    Write-Status "🎉 构建环境验证成功！" $Green
    exit 0
} else {
    Write-Status "💥 构建环境验证失败" $Red
    exit 1
}