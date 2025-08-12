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
idf.py set-target esp32s3

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

# 设置必要的环境变量
export ESP32_IDF_PATH="/home/runner/esp/esp-idf"
export TARGET_BOARD="ESP32_S3"
export TARGET_SERIES="ESP32"
export RTOS="ESP32"
export ESP32_ETHERNET_SUPPORT="ON"
export ESP32_ETHERNET_PHY="W5500"
export ESP32_ETHERNET_SCLK_PIN="13"
export ESP32_ETHERNET_MISO_PIN="12"
export ESP32_ETHERNET_MOSI_PIN="11"
export ESP32_ETHERNET_CS_PIN="14"
export ESP32_ETHERNET_INT_PIN="10"
export ESP32_ETHERNET_RESET_PIN="9"

# 执行构建
echo "✓ 开始构建..."
idf.py build

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