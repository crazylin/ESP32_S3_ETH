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

# 复制CMake预设文件和补丁
echo "✓ 复制CMake预设文件..."
if [ -f "../CMakePresets-W5500.json" ]; then
    cp ../CMakePresets-W5500.json CMakePresets.json
    echo "  已复制 CMakePresets-W5500.json -> CMakePresets.json"
elif [ -f "./CMakePresets-W5500.json" ]; then
    cp ./CMakePresets-W5500.json CMakePresets.json
    echo "  已复制 CMakePresets-W5500.json -> CMakePresets.json"
else
    echo "  警告: 未找到 CMakePresets-W5500.json"
fi

# 复制CMake补丁文件
echo "✓ 复制CMake补丁文件..."
if [ -f "../CMakeLists-patch.txt" ]; then
    cp ../CMakeLists-patch.txt CMakeLists-patch.txt
    echo "  ✅ CMake补丁文件已复制"
elif [ -f "./CMakeLists-patch.txt" ]; then
    cp ./CMakeLists-patch.txt CMakeLists-patch.txt
    echo "  ✅ CMake补丁文件已复制"
fi

# 验证CMake预设文件
if [ -f "CMakePresets.json" ]; then
    echo "  ✅ CMakePresets.json 已创建"
else
    echo "  ❌ CMakePresets.json 未创建"
    exit 1
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

# 清理之前的构建缓存
echo "✓ 清理构建缓存..."
if [ -d "build" ]; then
    echo "  清理旧的构建目录..."
    rm -rf build
fi

# 复制CMake补丁到nf-interpreter目录
if [ -f "../CMakeLists-patch-updated.txt" ]; then
    echo "✓ 复制CMake补丁文件..."
    cp ../CMakeLists-patch-updated.txt targets/ESP32/_IDF/CMakeLists-patch.cmake
fi

# 使用CMake预设配置构建
echo "✓ 使用CMake预设配置构建..."
if [ "$BUILD_TYPE" = "Debug" ]; then
    cmake --preset ESP32_S3_W5500_Debug
    BUILD_PRESET="ESP32_S3_W5500_Debug"
else
    cmake --preset ESP32_S3_W5500_Release
    BUILD_PRESET="ESP32_S3_W5500_Release"
fi

# 验证CMake配置成功
echo "✓ 验证CMake配置..."
if [ -f "build/build.ninja" ]; then
    echo "  ✅ CMake配置完成"
else
    echo "  ❌ CMake配置失败"
    echo "  检查CMake错误日志..."
    cat build/CMakeFiles/CMakeError.log 2>/dev/null || echo "无错误日志"
    exit 1
fi

# 显示CMake缓存内容
echo "✓ CMake缓存内容摘要:"
grep -E "(NF_|TARGET_|RTOS|ESP32_)" build/CMakeCache.txt | head -10

# 执行构建
echo "✓ 开始构建..."
echo "  构建预设: $BUILD_PRESET"

# 使用CMake构建
echo "  使用CMake构建..."
if [ "$BUILD_TYPE" = "Debug" ]; then
    echo "  构建Debug版本..."
    cmake --build build --target all --config Debug
else
    echo "  构建Release版本..."
    cmake --build build --target all --config Release
fi

# 验证构建结果
echo "=== 构建完成 ==="
echo "检查构建产物..."

# 检查构建目录是否存在
if [ ! -d "build" ]; then
    echo "  ❌ 构建目录不存在"
    exit 1
fi

cd build
FIRMWARE_FOUND=false

# 查找所有可能的固件文件
FIRMWARE_FILES=$(find . -name "*.bin" -o -name "*.elf" | grep -E "(nanoCLR|app|firmware)" | head -10)

if [ -n "$FIRMWARE_FILES" ]; then
    echo "$FIRMWARE_FILES" | while read file; do
        if [ -f "$file" ]; then
            size=$(stat -c%s "$file" 2>/dev/null || echo "未知大小")
            echo "  ✅ 找到: $file ($size bytes)"
        fi
    done
    FIRMWARE_FOUND=true
else
    echo "  ⚠️  未找到标准固件文件"
fi

# 检查ESP-IDF标准输出文件
echo "  检查ESP-IDF标准输出..."
for target_dir in "app" "bootloader" "partition_table"; do
    if [ -d "$target_dir" ]; then
        echo "  ✅ 目录存在: $target_dir"
        ls -la "$target_dir"/*.bin 2>/dev/null | head -3
    fi
done

# 检查是否有分区表
if [ -f "partitions.bin" ]; then
    echo "  ✅ partitions.bin 已生成"
    ls -la partitions.bin
fi

# 检查是否有bootloader
if [ -f "bootloader/bootloader.bin" ]; then
    echo "  ✅ bootloader.bin 已生成"
    ls -la bootloader/bootloader.bin
fi

# 检查CMake生成的文件
if [ -f "build.ninja" ]; then
    echo "  ✅ build.ninja 已生成"
fi

# 显示构建摘要
echo "  构建摘要:"
echo "  工作目录: $(pwd)"
echo "  构建类型: $BUILD_TYPE"
echo "  构建时间: $(date)"

cd ..

echo "  ✅ 构建过程已完成"