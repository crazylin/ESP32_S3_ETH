# ESP32-S3 + W5500 nanoFramework Windows构建修复验证脚本
# 基于官方nanoFramework ESP32构建文档的完整验证

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("Release", "Debug")]
    [string]$BuildType = "Release",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipBuild = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestOnly = $false
)

# 设置错误处理
$ErrorActionPreference = "Stop"

# 颜色定义
$Colors = @{
    Green = "Green"
    Red = "Red"
    Yellow = "Yellow"
    Cyan = "Cyan"
    Magenta = "Magenta"
}

function Write-Colored {
    param(
        [string]$Message,
        [string]$Color = "Green",
        [switch]$NoNewline = $false
    )
    Write-Host $Message -ForegroundColor $Colors[$Color] -NoNewline:$NoNewline
}

function Write-Header {
    param([string]$Title)
    Write-Colored "`n=== $Title ===`n" "Cyan"
}

function Write-Step {
    param([int]$Step, [string]$Description)
    Write-Colored "$Step. $Description...`n" "Yellow"
}

function Write-Result {
    param([string]$Message, [bool]$Success)
    $symbol = if ($Success) { "✅" } else { "❌" }
    $color = if ($Success) { "Green" } else { "Red" }
    Write-Colored "$symbol $Message`n" $color
}

# 主验证函数
function Test-WindowsBuildFix {
    Write-Header "ESP32-S3 + W5500 nanoFramework Windows构建修复验证"
    Write-Colored "构建类型: $BuildType`n"
    Write-Colored "测试模式: $TestOnly`n"
    Write-Colored "详细输出: $Verbose`n"
    
    $results = @()
    $step = 1
    
    # 1. 检查项目根目录
    Write-Step $step "检查项目根目录"
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $requiredFiles = @(
        "CMakePresets-W5500.json",
        "CMakeLists-patch-updated.txt",
        "BUILD_STATUS.md",
        "BUILD_WINDOWS.md",
        "BUILD_FIXES.md"
    )
    
    $allFilesExist = $true
    foreach ($file in $requiredFiles) {
        $fullPath = Join-Path $projectRoot $file
        if (Test-Path $fullPath) {
            Write-Colored "   ✅ $file 存在`n" "Green"
        } else {
            Write-Colored "   ❌ $file 缺失`n" "Red"
            $allFilesExist = $false
        }
    }
    $results += @{ Step = $step; Description = "项目文件完整性"; Success = $allFilesExist }
    $step++
    
    # 2. 检查Windows工作流文件
    Write-Step $step "检查Windows工作流"
    $workflowPath = Join-Path $projectRoot ".github\workflows\build-esp32s3-w5500-windows.yml"
    if (Test-Path $workflowPath) {
        $content = Get-Content $workflowPath -Raw
        $hasWindowsRunner = $content -match "windows-latest"
        $hasESP32Steps = $content -match "ESP32_S3_W5500"
        $success = $hasWindowsRunner -and $hasESP32Steps
        Write-Result "Windows工作流配置" $success
    } else {
        Write-Result "Windows工作流文件" $false
    }
    $results += @{ Step = $step; Description = "Windows工作流"; Success = $success }
    $step++
    
    # 3. 验证JSON语法
    Write-Step $step "验证JSON配置"
    $jsonPath = Join-Path $projectRoot "CMakePresets-W5500.json"
    try {
        $jsonContent = Get-Content $jsonPath -Raw | ConvertFrom-Json
        $jsonValid = $true
        Write-Result "JSON语法验证" $true
        
        # 检查必需预设
        $releasePreset = $jsonContent.configurePresets | Where-Object { $_.name -eq "ESP32_S3_W5500_Release" }
        $debugPreset = $jsonContent.configurePresets | Where-Object { $_.name -eq "ESP32_S3_W5500_Debug" }
        
        $presetsValid = $releasePreset -and $debugPreset
        Write-Result "构建预设存在" $presetsValid
    } catch {
        $jsonValid = $false
        Write-Result "JSON语法验证" $false
    }
    $results += @{ Step = $step; Description = "JSON配置"; Success = $jsonValid }
    $step++
    
    # 4. 验证CMake补丁
    Write-Step $step "验证CMake补丁"
    $patchPath = Join-Path $projectRoot "CMakeLists-patch-updated.txt"
    if (Test-Path $patchPath) {
        $content = Get-Content $patchPath -Raw
        $hasNFDebugger = $content -match "NF_Debugger"
        $hasReleaseCondition = $content -match "CMAKE_BUILD_TYPE STREQUAL Release"
        $success = $hasNFDebugger -and $hasReleaseCondition
        Write-Result "CMake补丁内容" $success
    } else {
        Write-Result "CMake补丁文件" $false
    }
    $results += @{ Step = $step; Description = "CMake补丁"; Success = $success }
    $step++
    
    # 5. 检查Windows环境变量
    Write-Step $step "检查Windows环境"
    $envChecks = @{
        "IDF_PATH" = "C:\esp\esp-idf"
        "IDF_TOOLS_PATH" = "C:\Espressif"
    }
    
    $envValid = $true
    foreach ($envVar in $envChecks.Keys) {
        $actualPath = [Environment]::GetEnvironmentVariable($envVar, "User")
        if (-not $actualPath) {
            $actualPath = [Environment]::GetEnvironmentVariable($envVar, "Machine")
        }
        
        if ($actualPath) {
            Write-Colored "   ✅ $envVar: $actualPath`n" "Green"
        } else {
            Write-Colored "   ⚠️  $envVar: 未设置 (将使用默认值)`n" "Yellow"
        }
    }
    
    # 检查必需工具
    $tools = @("python", "cmake", "ninja")
    foreach ($tool in $tools) {
        try {
            $version = & $tool --version 2>$null | Select-Object -First 1
            Write-Colored "   ✅ $tool: $version`n" "Green"
        } catch {
            Write-Colored "   ❌ $tool: 未找到`n" "Red"
            $envValid = $false
        }
    }
    $results += @{ Step = $step; Description = "Windows环境"; Success = $envValid }
    $step++
    
    # 6. 验证ESP-IDF安装
    Write-Step $step "验证ESP-IDF"
    $idfPath = "C:\esp\esp-idf"
    $idfValid = Test-Path $idfPath
    
    if ($idfValid) {
        try {
            $idfVersion = python "$idfPath\tools\idf.py" --version 2>$null
            Write-Result "ESP-IDF安装" $true
            Write-Colored "   版本: $idfVersion`n" "Green"
        } catch {
            Write-Result "ESP-IDF验证" $false
        }
    } else {
        Write-Result "ESP-IDF目录" $false
    }
    $results += @{ Step = $step; Description = "ESP-IDF"; Success = $idfValid }
    $step++
    
    # 7. 验证工具链
    Write-Step $step "验证工具链"
    $toolchainPaths = @(
        "C:\Espressif\tools\xtensa-esp32s3-elf\*\xtensa-esp32s3-elf\bin\xtensa-esp32s3-elf-gcc.exe",
        "C:\Espressif\tools\xtensa-esp-elf\*\xtensa-esp-elf\bin\xtensa-esp-elf-gcc.exe"
    )
    
    $toolchainValid = $false
    foreach ($pattern in $toolchainPaths) {
        $gccPath = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($gccPath) {
            try {
                $gccVersion = & $gccPath.FullName --version | Select-Object -First 1
                Write-Result "ESP32-S3工具链" $true
                Write-Colored "   路径: $($gccPath.FullName)`n" "Green"
                Write-Colored "   版本: $gccVersion`n" "Green"
                $toolchainValid = $true
                break
            } catch {
                continue
            }
        }
    }
    
    if (-not $toolchainValid) {
        Write-Result "ESP32-S3工具链" $false
    }
    $results += @{ Step = $step; Description = "工具链"; Success = $toolchainValid }
    $step++
    
    # 8. 检查nanoFramework目录
    Write-Step $step "检查nanoFramework"
    $nfPath = "C:\nanoFramework\nf-interpreter"
    $nfValid = Test-Path $nfPath
    
    if ($nfValid) {
        Write-Result "nanoFramework目录" $true
        Write-Colored "   路径: $nfPath`n" "Green"
    } else {
        Write-Result "nanoFramework目录" $false
    }
    $results += @{ Step = $step; Description = "nanoFramework"; Success = $nfValid }
    $step++
    
    # 9. 测试构建配置（可选）
    if (-not $SkipBuild -and -not $TestOnly) {
        Write-Step $step "测试构建配置"
        try {
            Set-Location $nfPath
            
            # 清理构建目录
            if (Test-Path "build") {
                Remove-Item -Recurse -Force "build"
            }
            
            # 复制配置文件
            $presetSource = Join-Path $projectRoot "CMakePresets-W5500.json"
            Copy-Item -Path $presetSource -Destination "CMakePresets.json" -Force
            
            # 应用补丁
            $patchDir = "targets\ESP32\_IDF"
            if (-not (Test-Path $patchDir)) {
                New-Item -ItemType Directory -Path $patchDir -Force
            }
            
            $patchSource = Join-Path $projectRoot "CMakeLists-patch-updated.txt"
            Copy-Item -Path $patchSource -Destination "$patchDir\CMakeLists-patch.cmake" -Force
            
            # 测试CMake配置
            $preset = if ($BuildType -eq "Release") { "ESP32_S3_W5500_Release" } else { "ESP32_S3_W5500_Debug" }
            cmake --preset $preset
            
            $configSuccess = $LASTEXITCODE -eq 0
            Write-Result "CMake配置测试" $configSuccess
            
            if ($configSuccess -and $Verbose) {
                Write-Colored "`n构建文件验证:`n" "Cyan"
                $buildFiles = @("build.ninja", "CMakeCache.txt")
                foreach ($file in $buildFiles) {
                    $filePath = Join-Path "build" $file
                    if (Test-Path $filePath) {
                        Write-Colored "   ✅ $file 已创建`n" "Green"
                    } else {
                        Write-Colored "   ❌ $file 缺失`n" "Red"
                    }
                }
            }
            
            $results += @{ Step = $step; Description = "构建配置"; Success = $configSuccess }
        } catch {
            Write-Result "构建配置测试" $false
            Write-Colored "   错误: $($_.Exception.Message)`n" "Red"
            $results += @{ Step = $step; Description = "构建配置"; Success = $false }
        }
    } else {
        Write-Colored "跳过构建测试 (--SkipBuild 或 --TestOnly)`n" "Yellow"
    }
    
    # 生成验证报告
    Write-Header "验证结果汇总"
    
    $totalSteps = $results.Count
    $passedSteps = ($results | Where-Object { $_.Success }).Count
    $successRate = [math]::Round(($passedSteps / $totalSteps) * 100, 1)
    
    Write-Colored "总检查步骤: $totalSteps`n" "Cyan"
    Write-Colored "通过步骤: $passedSteps`n" "Green"
    Write-Colored "成功率: $successRate%`n" $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })
    
    Write-Colored "详细结果:`n" "Cyan"
    foreach ($result in $results) {
        $symbol = if ($result.Success) { "✅" } else { "❌" }
        $color = if ($result.Success) { "Green" } else { "Red" }
        Write-Colored "   $symbol 步骤 $($result.Step): $($result.Description)`n" $color
    }
    
    # 提供下一步建议
    Write-Header "下一步操作"
    
    if ($successRate -ge 80) {
        Write-Colored "🎉 环境验证成功！可以开始构建：`n" "Green"
        Write-Colored "   1. 运行: cmake --build build`n" "Cyan"
        Write-Colored "   2. 使用: nanoff --platform esp32 --serialport COM3 --deploy`n" "Cyan"
        Write-Colored "   3. 测试: W5500以太网连接`n" "Cyan"
    } else {
        Write-Colored "⚠️  环境验证发现问题，请检查：`n" "Yellow"
        
        $failedSteps = $results | Where-Object { -not $_.Success }
        foreach ($step in $failedSteps) {
            Write-Colored "   ❌ 步骤 $($step.Step): $($step.Description) 需要修复`n" "Red"
        }
        
        Write-Colored "`n建议操作:`n" "Cyan"
        Write-Colored "   1. 检查BUILD_WINDOWS.md获取完整指南`n" "Cyan"
        Write-Colored "   2. 运行ESP-IDF安装器修复工具链`n" "Cyan"
        Write-Colored "   3. 验证环境变量设置`n" "Cyan"
    }
    
    return $successRate -ge 80
}

# 运行验证
$result = Test-WindowsBuildFix

if ($result) {
    Write-Header "验证完成 ✅"
    exit 0
} else {
    Write-Header "验证失败 ❌"
    exit 1
}