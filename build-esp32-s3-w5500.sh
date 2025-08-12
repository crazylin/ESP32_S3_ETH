#!/bin/bash

# ESP32-S3 + W5500 nanoFramework 构建脚本
# 解决ESP-IDF工具链配置问题

set -e

echo "=== ESP32-S3 + W5500 nanoFramework 构建 ==="

# 确保在nf-interpreter目录
if [ ! -f "CMakeLists.txt" ]; then
    echo "错误：必须在nf-interpreter目录中运行"
    exit 1
fi

# 构建类型，默认为Release
BUILD_TYPE=${1:-Release}
echo "构建类型: $BUILD_TYPE"

# 清除可能的环境变量冲突
unset IDF_PATH
unset ESP_IDF_PATH

echo "✓ 已清除环境变量冲突"

# 验证ESP-IDF安装
if [ ! -d "$HOME/esp/esp-idf" ]; then
    echo "错误：ESP-IDF未在 $HOME/esp/esp-idf 中找到"
    exit 1
fi

# 加载ESP-IDF环境
echo "✓ 加载ESP-IDF环境..."
source "$HOME/esp/esp-idf/export.sh"

# 验证ESP-IDF版本
echo "ESP-IDF版本："
idf.py --version

# 验证工具链
echo "验证工具链："
which xtensa-esp32s3-elf-gcc
xtensa-esp32s3-elf-gcc --version | head -n 1

# 设置目标芯片
echo "✓ 设置目标芯片为esp32s3..."
export IDF_TARGET="esp32s3"

# 根据构建类型设置参数
echo "✓ 配置构建参数..."
if [ "$BUILD_TYPE" = "Debug" ]; then
    export CMAKE_BUILD_TYPE="Debug"
    export NF_FEATURE_DEBUGGER="ON"
    export NF_BUILD_RTM="OFF"
    echo "  Debug模式启用"
else
    export CMAKE_BUILD_TYPE="MinSizeRel"
    export NF_FEATURE_DEBUGGER="OFF"
    export NF_BUILD_RTM="ON"
    echo "  Release模式启用"
fi

# 配置nanoFramework构建参数
# 这些变量现在由CMakePresets-W5500.json中的预设配置
# 我们只需要确保ESP32_IDF_PATH正确设置
export ESP32_IDF_PATH="/home/runner/esp/esp-idf"

# 创建构建目录
if [ ! -d "build" ]; then
    echo "✓ 创建构建目录..."
    mkdir -p build
fi

# 复制CMake预设文件
echo "✓ 复制CMake预设文件..."
if [ -f "../nanobuild-scripts/CMakePresets-W5500.json" ]; then
    cp ../nanobuild-scripts/CMakePresets-W5500.json CMakePresets.json
    echo "  已复制 CMakePresets-W5500.json -> CMakePresets.json"
else
    echo "  警告: 未找到 CMakePresets-W5500.json"
fi

# 验证构建配置
echo "✓ 验证构建配置..."
echo "  构建类型: $BUILD_TYPE"
echo "  ESP32_IDF_PATH: $ESP32_IDF_PATH"
echo "  工作目录: $(pwd)"

# 设置ESP-IDF环境变量
echo "✓ 设置ESP-IDF环境变量..."
export IDF_PATH="$HOME/esp/esp-idf"
export IDF_TOOLS_PATH="$HOME/.espressif"

# 使用CMake预设配置构建
echo "✓ 使用CMake预设配置构建..."
if [ "$BUILD_TYPE" = "Debug" ]; then
    cmake --preset ESP32_S3_W5500_Debug
else
    cmake --preset ESP32_S3_W5500_Release
fi

# 执行构建
echo "✓ 开始构建..."
if [ "$BUILD_TYPE" = "Debug" ]; then
    cmake --build --preset ESP32_S3_W5500_Debug --target nanoCLR
else
    cmake --build --preset ESP32_S3_W5500_Release --target nanoCLR
fi

# 验证构建结果
echo "=== 构建完成 ==="
echo "固件文件位置："
echo "  nanoCLR.bin: build/nanoCLR.bin"
echo "  bootloader.bin: build/bootloader/bootloader.bin"
echo "  partitions.bin: build/partitions.bin"

# 检查文件是否存在
if [ -f "build/nanoCLR.bin" ]; then
    echo "✅ nanoCLR.bin 构建成功"
    ls -la build/nanoCLR.bin
else
    echo "❌ nanoCLR.bin 未找到"
    exit 1
fi