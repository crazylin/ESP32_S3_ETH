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

# 配置nanoFramework构建参数
echo "✓ 配置nanoFramework构建参数..."

# 设置nanoFramework所需的CMake参数
export CMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-MinSizeRel}"
export TARGET_BOARD="ESP32_S3"
export TARGET_SERIES="ESP32"
export RTOS="ESP32"
export ESP32_IDF_PATH="/home/runner/esp/esp-idf"

# 功能开关
export NF_FEATURE_DEBUGGER="${NF_FEATURE_DEBUGGER:-OFF}"
export NF_FEATURE_RTC="ON"
export NF_SECURITY_MBEDTLS="ON"
export NF_BUILD_RTM="${NF_BUILD_RTM:-ON}"
export NF_WP_IMPLEMENTS_CRC32="OFF"
export NF_FEATURE_HAS_SDCARD="ON"
export NF_FEATURE_HAS_CONFIG_BLOCK="ON"

# 网络配置
export ESP32_ETHERNET_SUPPORT="ON"
export ESP32_ETHERNET_PHY="W5500"
export ESP32_ETHERNET_SCLK_PIN="13"
export ESP32_ETHERNET_MISO_PIN="12"
export ESP32_ETHERNET_MOSI_PIN="11"
export ESP32_ETHERNET_CS_PIN="14"
export ESP32_ETHERNET_INT_PIN="10"
export ESP32_ETHERNET_RESET_PIN="9"

# API配置
export API_System.Device.Gpio="ON"
export API_System.Device.Spi="ON"
export API_System.Device.I2c="ON"
export API_System.Device.Pwm="ON"
export API_System.SerialCommunication="ON"
export API_System.IO.FileSystem="ON"
export API_Windows.Storage="ON"
export API_Windows.Devices="ON"
export API_System.Net="ON"
export API_System.Net.NetworkInformation="ON"
export API_System.Net.Sockets="ON"
export API_System.Net.Http="ON"
export API_System.Net.Security="ON"
export API_nanoFramework.ResourceManager="ON"
export API_nanoFramework.System.Collections="ON"
export API_nanoFramework.System.Text="ON"
export API_nanoFramework.Hardware.Esp32="ON"
export API_nanoFramework.Networking="ON"
export API_nanoFramework.Hardware.Esp32.Rmt="ON"
export API_nanoFramework.System.IO.Streams="ON"
export API_nanoFramework.Hardware.Esp32.Ble="ON"
export API_nanoFramework.System.Net="ON"
export API_nanoFramework.System.Net.Http="ON"
export API_nanoFramework.System.Net.Sockets="ON"
export API_nanoFramework.System.Net.Security="ON"
export API_nanoFramework.System.Net.WebSockets="ON"
export API_nanoFramework.System.Net.WebSockets.Client="ON"

# 其他配置
export SUPPORT_ANY_BASE_CONVERSION="ON"
export NF_PLATFORM_NO_CLR_WARNINGS="ON"

# 执行构建 - 使用CMake直接配置
export CMAKE_TOOLCHAIN_FILE="$HOME/esp/esp-idf/tools/cmake/toolchain-esp32s3.cmake"
export IDF_TARGET="esp32s3"

# 使用CMake配置构建
echo "✓ 配置CMake..."
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE" \
  -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TOOLCHAIN_FILE" \
  -DIDF_TARGET="$IDF_TARGET" \
  -DTOOLCHAIN_PREFIX="xtensa-esp32s3-elf" \
  -DRTOS="$RTOS" \
  -DTARGET_BOARD="$TARGET_BOARD" \
  -DTARGET_SERIES="$TARGET_SERIES" \
  -DNF_FEATURE_DEBUGGER="$NF_FEATURE_DEBUGGER" \
  -DNF_FEATURE_RTC="$NF_FEATURE_RTC" \
  -DNF_SECURITY_MBEDTLS="$NF_SECURITY_MBEDTLS" \
  -DNF_BUILD_RTM="$NF_BUILD_RTM" \
  -DNF_WP_IMPLEMENTS_CRC32="$NF_WP_IMPLEMENTS_CRC32" \
  -DNF_FEATURE_HAS_SDCARD="$NF_FEATURE_HAS_SDCARD" \
  -DNF_FEATURE_HAS_CONFIG_BLOCK="$NF_FEATURE_HAS_CONFIG_BLOCK" \
  -DESP32_IDF_PATH="$ESP32_IDF_PATH" \
  -DESP32_ETHERNET_SUPPORT="$ESP32_ETHERNET_SUPPORT" \
  -DESP32_ETHERNET_PHY="$ESP32_ETHERNET_PHY" \
  -DESP32_ETHERNET_SCLK_PIN="$ESP32_ETHERNET_SCLK_PIN" \
  -DESP32_ETHERNET_MISO_PIN="$ESP32_ETHERNET_MISO_PIN" \
  -DESP32_ETHERNET_MOSI_PIN="$ESP32_ETHERNET_MOSI_PIN" \
  -DESP32_ETHERNET_CS_PIN="$ESP32_ETHERNET_CS_PIN" \
  -DESP32_ETHERNET_INT_PIN="$ESP32_ETHERNET_INT_PIN" \
  -DESP32_ETHERNET_RESET_PIN="$ESP32_ETHERNET_RESET_PIN" \
  -DAPI_System.Device.Gpio="$API_System.Device.Gpio" \
  -DAPI_System.Device.Spi="$API_System.Device.Spi" \
  -DAPI_System.Device.I2c="$API_System.Device.I2c" \
  -DAPI_System.Device.Pwm="$API_System.Device.Pwm" \
  -DAPI_System.SerialCommunication="$API_System.SerialCommunication" \
  -DAPI_System.IO.FileSystem="$API_System.IO.FileSystem" \
  -DAPI_Windows.Storage="$API_Windows.Storage" \
  -DAPI_Windows.Devices="$API_Windows.Devices" \
  -DAPI_System.Net="$API_System.Net" \
  -DAPI_System.Net.NetworkInformation="$API_System.Net.NetworkInformation" \
  -DAPI_System.Net.Sockets="$API_System.Net.Sockets" \
  -DAPI_System.Net.Http="$API_System.Net.Http" \
  -DAPI_System.Net.Security="$API_System.Net.Security" \
  -DAPI_nanoFramework.ResourceManager="$API_nanoFramework.ResourceManager" \
  -DAPI_nanoFramework.System.Collections="$API_nanoFramework.System.Collections" \
  -DAPI_nanoFramework.System.Text="$API_nanoFramework.System.Text" \
  -DAPI_nanoFramework.Hardware.Esp32="$API_nanoFramework.Hardware.Esp32" \
  -DAPI_nanoFramework.Networking="$API_nanoFramework.Networking" \
  -DAPI_nanoFramework.Hardware.Esp32.Rmt="$API_nanoFramework.Hardware.Esp32.Rmt" \
  -DAPI_nanoFramework.System.IO.Streams="$API_nanoFramework.System.IO.Streams" \
  -DAPI_nanoFramework.Hardware.Esp32.Ble="$API_nanoFramework.Hardware.Esp32.Ble" \
  -DAPI_nanoFramework.System.Net="$API_nanoFramework.System.Net" \
  -DAPI_nanoFramework.System.Net.Http="$API_nanoFramework.System.Net.Http" \
  -DAPI_nanoFramework.System.Net.Sockets="$API_nanoFramework.System.Net.Sockets" \
  -DAPI_nanoFramework.System.Net.Security="$API_nanoFramework.System.Net.Security" \
  -DAPI_nanoFramework.System.Net.WebSockets="$API_nanoFramework.System.Net.WebSockets" \
  -DAPI_nanoFramework.System.Net.WebSockets.Client="$API_nanoFramework.System.Net.WebSockets.Client" \
  -DSUPPORT_ANY_BASE_CONVERSION="$SUPPORT_ANY_BASE_CONVERSION" \
  -DNF_PLATFORM_NO_CLR_WARNINGS="$NF_PLATFORM_NO_CLR_WARNINGS" \
  -B build \
  -S .

# 执行构建
echo "✓ 开始构建..."
cmake --build build --target nanoCLR

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