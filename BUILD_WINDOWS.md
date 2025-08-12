# ESP32-S3 + W5500 nanoFramework Windows构建指南

基于官方nanoFramework文档的Windows构建配置

## 概述

本指南提供在Windows主机上构建ESP32-S3 + W5500 nanoFramework固件的完整步骤，遵循官方nanoFramework文档的最佳实践。

## 系统要求

### 必需软件
- **Windows 10/11** (64位)
- **Visual Studio 2022** (包含C++开发工具)
- **Python 3.12** 或更高版本
- **Git for Windows**
- **CMake 3.21+**
- **Ninja Build**

### 可选但推荐
- **Visual Studio Code** (带C/C++和CMake扩展)
- **ESP-IDF Tools Installer** (官方安装器)

## 安装步骤

### 1. 安装ESP-IDF

#### 方法A: 使用官方安装器 (推荐)
1. 下载ESP-IDF Tools Installer: https://dl.espressif.com/dl/esp-idf/
2. 运行安装器，选择ESP-IDF v5.2.3
3. 选择安装路径: `C:\esp\esp-idf`
4. 选择工具链: ESP32-S3
5. 完成安装

#### 方法B: 手动安装
```powershell
# 创建目录
mkdir C:\esp
cd C:\esp

# 克隆ESP-IDF
git clone -b v5.2.3 --recursive https://github.com/espressif/esp-idf.git

# 安装工具
C:\esp\esp-idf\install.bat esp32s3

# 导出环境变量
C:\esp\esp-idf\export.bat
```

### 2. 安装构建工具

#### 使用Chocolatey (推荐)
```powershell
# 安装Chocolatey (如果未安装)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# 安装必需工具
choco install cmake --installargs 'ADD_CMAKE_TO_PATH=System' -y
choco install ninja git python -y
```

#### 手动安装
1. **CMake**: https://cmake.org/download/
2. **Ninja**: https://github.com/ninja-build/ninja/releases
3. **Python**: https://www.python.org/downloads/

### 3. 配置环境变量

#### 系统环境变量
```
IDF_PATH = C:\esp\esp-idf
IDF_TOOLS_PATH = C:\Espressif
PATH 添加: C:\esp\esp-idf\tools
PATH 添加: C:\Espressif\tools\xtensa-esp32s3-elf\[版本]\xtensa-esp32s3-elf\bin
```

#### PowerShell环境设置
```powershell
# 创建profile.ps1
$profilePath = $PROFILE.CurrentUserAllHosts
if (!(Test-Path $profilePath)) {
    New-Item -ItemType File -Path $profilePath -Force
}

# 添加ESP-IDF环境
Add-Content $profilePath @"
# ESP-IDF Environment
`$env:IDF_PATH = "C:\esp\esp-idf"
`$env:IDF_TOOLS_PATH = "C:\Espressif"
& "C:\esp\esp-idf\export.ps1"
"@
```

## 项目设置

### 1. 克隆项目
```powershell
# 创建项目目录
mkdir C:\nanoFramework
cd C:\nanoFramework

# 克隆nf-interpreter
git clone --recursive https://github.com/nanoframework/nf-interpreter.git

# 克隆构建脚本
git clone https://github.com/[你的仓库]/ESP32_S3_ETH.git nanobuild-scripts
```

### 2. 配置构建
```powershell
cd C:\nanoFramework\nf-interpreter

# 复制Windows专用配置
Copy-Item -Path "..\nanobuild-scripts\CMakePresets-W5500.json" -Destination "CMakePresets.json" -Force

# 应用CMake补丁
New-Item -ItemType Directory -Force -Path "targets\ESP32\_IDF"
Copy-Item -Path "..\nanobuild-scripts\CMakeLists-patch-updated.txt" -Destination "targets\ESP32\_IDF\CMakeLists-patch.cmake" -Force
```

### 3. 验证环境
```powershell
# 验证工具
python --version
cmake --version
ninja --version
xtensa-esp32s3-elf-gcc --version

# 验证ESP-IDF
idf.py --version
```

## 构建命令

### 本地构建
```powershell
# 配置构建
cmake --preset ESP32_S3_W5500_Release

# 构建固件
cmake --build build --config MinSizeRel

# 或完整命令
cmake --build --preset ESP32_S3_W5500_Release
```

### 调试构建
```powershell
# 调试配置
cmake --preset ESP32_S3_W5500_Debug

# 调试构建
cmake --build build --config Debug
```

## GitHub Actions Windows构建

已创建专用Windows工作流: `.github/workflows/build-esp32s3-w5500-windows.yml`

### 触发方式
1. **自动触发**: 推送到main分支
2. **手动触发**: GitHub Actions页面 → 选择工作流 → Run workflow

### 构建参数
- **Build type**: Release/Debug
- **Upload artifacts**: 是否上传构建产物

## 硬件连接

### W5500 SPI引脚配置
```
ESP32-S3    W5500
--------    -----
GPIO11  →  MOSI
GPIO12  →  MISO
GPIO13  →  SCLK
GPIO14  →  CS
GPIO10  →  INT
GPIO9   →  RST
```

### 验证连接
```csharp
// 测试代码
using System.Device.Spi;
using System.Device.Gpio;

var spi = SpiDevice.Create(new SpiConnectionSettings(1, 14)
{
    ClockFrequency = 1000000,
    Mode = SpiMode.Mode0
});

// 检查W5500芯片ID
var buffer = new byte[4];
spi.WriteRead(new byte[] { 0x00, 0x39 }, buffer);
Console.WriteLine($"W5500 Version: {buffer[3]:X2}");
```

## 故障排除

### 常见错误及解决方案

#### 1. "xtensa-esp32s3-elf-gcc not found"
```powershell
# 检查工具链路径
Get-ChildItem -Path "C:\Espressif\tools\xtensa-esp32s3-elf" -Recurse -Name "gcc.exe"

# 添加到PATH
$env:PATH += ";C:\Espressif\tools\xtensa-esp32s3-elf\esp-13.2.0_20230928\xtensa-esp32s3-elf\bin"
```

#### 2. CMake找不到编译器
```powershell
# 手动指定编译器
cmake --preset ESP32_S3_W5500_Release `
  -DCMAKE_C_COMPILER=C:/Espressif/tools/xtensa-esp32s3-elf/esp-13.2.0_20230928/xtensa-esp32s3-elf/bin/xtensa-esp32s3-elf-gcc.exe `
  -DCMAKE_CXX_COMPILER=C:/Espressif/tools/xtensa-esp32s3-elf/esp-13.2.0_20230928/xtensa-esp32s3-elf/bin/xtensa-esp32s3-elf-g++.exe
```

#### 3. Python环境错误
```powershell
# 重新安装ESP-IDF Python依赖
python -m pip install --upgrade pip
python -m pip install -r C:\esp\esp-idf\requirements.txt
```

### 验证步骤

#### 1. 环境验证脚本
```powershell
# 运行验证脚本
.\test-build-fix.ps1
```

#### 2. 手动验证
```powershell
# 检查所有必需工具
Write-Host "=== Environment Check ==="
Write-Host "ESP-IDF: $(Test-Path $env:IDF_PATH)"
Write-Host "CMake: $(Get-Command cmake -ErrorAction SilentlyContinue)"
Write-Host "Ninja: $(Get-Command ninja -ErrorAction SilentlyContinue)"
Write-Host "Python: $(python --version)"
Write-Host "Xtensa GCC: $(Get-Command xtensa-esp32s3-elf-gcc -ErrorAction SilentlyContinue)"
```

## 构建产物

### 输出文件
- `nanoCLR.bin` - 主要固件文件
- `nanoCLR.elf` - 调试符号文件
- `bootloader.bin` - 引导加载器
- `partition-table.bin` - 分区表

### 文件位置
```
C:\nanoFramework\nf-interpreter\build\
├── nanoCLR.bin
├── nanoCLR.elf
├── bootloader\
│   └── bootloader.bin
└── partition_table\
    └── partition-table.bin
```

## 后续步骤

### 1. 刷写固件
```powershell
# 使用nanoff工具
nanoff --platform esp32 --serialport COM3 --update --binaries C:\nanoFramework\nf-interpreter\build\nanoCLR.bin
```

### 2. 开发环境设置
- 安装Visual Studio 2022
- 安装nanoFramework VS扩展
- 配置项目模板

### 3. 测试连接
```csharp
// 测试以太网连接
using System.Net.NetworkInformation;
using System.Net;

var network = new NetworkInterface("ETH");
if (network.IPv4Address != IPAddress.Any)
{
    Console.WriteLine($"Connected: {network.IPv4Address}");
}
```

## 支持

- **官方文档**: https://docs.nanoframework.net/content/building/build-esp32.html
- **GitHub Issues**: https://github.com/nanoframework/nf-interpreter/issues
- **Discord社区**: https://discord.gg/nanoframework