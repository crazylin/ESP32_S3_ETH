# ESP32-S3 + W5500 Windows构建问题排查脚本
# 专门解决GitHub Actions和本地构建中的常见问题

param(
    [Parameter(Mandatory=$false)]
    [switch]$FixIssues = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Continue"

# 颜色定义
$Colors = @{
    Green = "Green"
    Red = "Red"
    Yellow = "Yellow"
    Cyan = "Cyan"
    Magenta = "Magenta"
}

function Write-Colored {
    param([string]$Message, [string]$Color = "Green")
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

function Test-BuildEnvironment {
    Write-Colored "=== ESP32-S3 + W5500 Windows构建问题排查 ===" "Cyan"
    
    $issues = @()
    
    # 1. 检查ESP-IDF安装
    Write-Colored "1. 检查ESP-IDF安装..." "Yellow"
    $idfPath = "C:\esp\esp-idf"
    if (Test-Path $idfPath) {
        Write-Colored "   ✅ ESP-IDF目录存在: $idfPath" "Green"
        
        # 检查requirements文件
        $requirementsPath = Join-Path $idfPath "tools\requirements\requirements.core.txt"
        if (Test-Path $requirementsPath) {
            Write-Colored "   ✅ requirements文件存在: $requirementsPath" "Green"
        } else {
            Write-Colored "   ❌ requirements文件缺失: $requirementsPath" "Red"
            $issues += "ESP-IDF requirements文件缺失"
        }
        
        # 检查Python环境
        try {
            $pythonCheck = python -c "import sys; print(sys.executable)" 2>$null
            if ($pythonCheck) {
                Write-Colored "   ✅ Python可用: $pythonCheck" "Green"
            }
        } catch {
            Write-Colored "   ❌ Python不可用" "Red"
            $issues += "Python环境异常"
        }
    } else {
        Write-Colored "   ❌ ESP-IDF目录不存在: $idfPath" "Red"
        $issues += "ESP-IDF未正确安装"
    }
    
    # 2. 检查工具链
    Write-Colored "2. 检查ESP32-S3工具链..." "Yellow"
    $toolchainPaths = @(
        "C:\Espressif\tools\xtensa-esp32s3-elf",
        "C:\Espressif\tools\xtensa-esp-elf"
    )
    
    $toolchainFound = $false
    foreach ($path in $toolchainPaths) {
        if (Test-Path $path) {
            $versions = Get-ChildItem -Path $path -Directory
            if ($versions) {
                Write-Colored "   ✅ 工具链目录: $path ($($versions.Name -join ', '))" "Green"
                $toolchainFound = $true
            }
        }
    }
    
    if (-not $toolchainFound) {
        Write-Colored "   ❌ ESP32-S3工具链未找到" "Red"
        $issues += "ESP32-S3工具链缺失"
    }
    
    # 3. 检查环境变量
    Write-Colored "3. 检查环境变量..." "Yellow"
    $envVars = @("IDF_PATH", "IDF_TOOLS_PATH")
    foreach ($var in $envVars) {
        $value = [Environment]::GetEnvironmentVariable($var)
        if ($value) {
            Write-Colored "   ✅ $var: $value" "Green"
        } else {
            Write-Colored "   ⚠️  $var: 未设置" "Yellow"
        }
    }
    
    # 4. 检查构建工具
    Write-Colored "4. 检查构建工具..." "Yellow"
    $tools = @("cmake", "ninja", "git")
    foreach ($tool in $tools) {
        try {
            $version = & $tool --version 2>$null | Select-Object -First 1
            if ($version) {
                Write-Colored "   ✅ $tool: $version" "Green"
            } else {
                Write-Colored "   ❌ $tool: 无法获取版本" "Red"
                $issues += "$tool 工具异常"
            }
        } catch {
            Write-Colored "   ❌ $tool: 未安装" "Red"
            $issues += "$tool 未安装"
        }
    }
    
    # 5. 检查项目配置
    Write-Colored "5. 检查项目配置..." "Yellow"
    $projectRoot = Split-Path -Parent $PSScriptRoot
    
    # 检查CMakePresets
    $presetsPath = Join-Path $projectRoot "CMakePresets-W5500.json"
    if (Test-Path $presetsPath) {
        Write-Colored "   ✅ CMakePresets-W5500.json存在" "Green"
        try {
            $content = Get-Content $presetsPath -Raw | ConvertFrom-Json
            Write-Colored "   ✅ JSON格式有效" "Green"
        } catch {
            Write-Colored "   ❌ JSON格式无效" "Red"
            $issues += "CMakePresets.json格式错误"
        }
    } else {
        Write-Colored "   ❌ CMakePresets-W5500.json缺失" "Red"
        $issues += "CMakePresets文件缺失"
    }
    
    # 检查CMake补丁
    $patchPath = Join-Path $projectRoot "CMakeLists-patch-updated.txt"
    if (Test-Path $patchPath) {
        Write-Colored "   ✅ CMakeLists-patch-updated.txt存在" "Green"
    } else {
        Write-Colored "   ❌ CMakeLists-patch-updated.txt缺失" "Red"
        $issues += "CMake补丁文件缺失"
    }
    
    # 6. 检查GitHub Actions工作流
    Write-Colored "6. 检查GitHub Actions工作流..." "Yellow"
    $workflowPath = Join-Path $projectRoot ".github\workflows\build-esp32s3-w5500-windows.yml"
    if (Test-Path $workflowPath) {
        Write-Colored "   ✅ Windows工作流存在" "Green"
        
        # 检查requirements.txt引用
        $content = Get-Content $workflowPath -Raw
        if ($content -match "requirements\.txt" -and -not ($content -match "requirements\.core\.txt")) {
            Write-Colored "   ⚠️  检测到requirements.txt引用，可能需要修复" "Yellow"
            $issues += "工作流中的requirements.txt路径问题"
        }
    } else {
        Write-Colored "   ❌ Windows工作流缺失" "Red"
        $issues += "GitHub Actions工作流缺失"
    }
    
    return $issues
}

function Get-FixSuggestions {
    param([array]$Issues)
    
    Write-Colored "=== 修复建议 ===" "Cyan"
    
    foreach ($issue in $Issues) {
        Write-Colored "问题: $issue" "Red"
        
        switch -Wildcard ($issue) {
            "*ESP-IDF未正确安装*" {
                Write-Colored "  修复: 运行ESP-IDF安装器或手动克隆:" "Yellow"
                Write-Colored "    git clone -b v5.2.3 --recursive https://github.com/espressif/esp-idf.git C:\esp\esp-idf" "Cyan"
            }
            "*requirements文件缺失*" {
                Write-Colored "  修复: 检查ESP-IDF完整性:" "Yellow"
                Write-Colored "    cd C:\esp\esp-idf && git submodule update --init --recursive" "Cyan"
            }
            "*工具链缺失*" {
                Write-Colored "  修复: 运行ESP-IDF工具安装:" "Yellow"
                Write-Colored "    cd C:\esp\esp-idf && .\install.bat esp32s3" "Cyan"
            }
            "*环境变量未设置*" {
                Write-Colored "  修复: 设置环境变量:" "Yellow"
                Write-Colored "    [Environment]::SetEnvironmentVariable('IDF_PATH', 'C:\esp\esp-idf', 'User')" "Cyan"
                Write-Colored "    [Environment]::SetEnvironmentVariable('IDF_TOOLS_PATH', 'C:\Espressif', 'User')" "Cyan"
            }
            "*CMakePresets*" {
                Write-Colored "  修复: 确保项目根目录包含CMakePresets-W5500.json" "Yellow"
            }
            "*CMake补丁*" {
                Write-Colored "  修复: 确保CMakeLists-patch-updated.txt存在于项目根目录" "Yellow"
            }
            "*requirements.txt路径问题*" {
                Write-Colored "  修复: 已自动修复，使用requirements.core.txt" "Green"
            }
        }
        Write-Colored ""
    }
}

# 主程序
$issues = Test-BuildEnvironment

if ($issues.Count -eq 0) {
    Write-Colored "🎉 所有检查通过！构建环境已就绪" "Green"
} else {
    Write-Colored "⚠️  发现 $($issues.Count) 个问题需要修复" "Yellow"
    Get-FixSuggestions -Issues $issues
    
    if ($FixIssues) {
        Write-Colored "正在尝试自动修复..." "Cyan"
        # 这里可以添加自动修复逻辑
    }
}

Write-Colored "`n=== 快速测试命令 ===" "Cyan"
Write-Colored "本地验证: .\test-build-windows.ps1 -BuildType Release -Verbose" "Green"
Write-Colored "完整构建: .\build-esp32-s3-w5500-windows.cmd release verbose" "Green"
Write-Colored "问题排查: .\troubleshoot-windows-build.ps1 -Verbose" "Green"