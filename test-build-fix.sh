#!/bin/bash

# ESP32-S3 + W5500 nanoFramework 构建测试脚本
# 验证所有修复是否有效

set -e

echo "=== ESP32-S3 + W5500 构建测试 ==="

# 检查当前目录
if [ ! -f "CMakeLists.txt" ]; then
    echo "错误：必须在nf-interpreter目录中运行"
    echo "请切换到nf-interpreter目录后再次运行"
    exit 1
fi

echo "✓ 当前在正确的nf-interpreter目录"

# 检查ESP-IDF
if [ -z "$IDF_PATH" ]; then
    echo "错误：ESP-IDF环境未设置"
    echo "请运行: source $HOME/esp/esp-idf/export.sh"
    exit 1
fi

echo "✓ ESP-IDF环境已设置: $IDF_PATH"

# 验证工具链
echo "✓ 验证工具链..."
which xtensa-esp32s3-elf-gcc || echo "❌ xtensa-esp32s3-elf-gcc未找到"
which cmake || echo "❌ cmake未找到"
which ninja || echo "❌ ninja未找到"

# 清理构建缓存
echo "✓ 清理构建缓存..."
rm -rf build

# 复制CMake补丁
echo "✓ 应用CMake补丁..."
if [ -f "../CMakeLists-patch-updated.txt" ]; then
    mkdir -p targets/ESP32/_IDF/
    cp ../CMakeLists-patch-updated.txt targets/ESP32/_IDF/CMakeLists-patch.cmake
    echo "  已复制CMake补丁"
else
    echo "  警告：未找到CMakeLists-patch-updated.txt"
fi

# 复制CMake预设
echo "✓ 复制CMake预设..."
if [ -f "../CMakePresets-W5500.json" ]; then
    cp ../CMakePresets-W5500.json CMakePresets.json
    echo "  已复制CMakePresets-W5500.json"
else
    echo "  警告：未找到CMakePresets-W5500.json"
fi

# 验证JSON语法
echo "✓ 验证CMakePresets.json语法..."
python3 -m json.tool CMakePresets.json > /dev/null && echo "  ✅ JSON语法正确" || echo "❌ JSON语法错误"

# 配置构建
echo "✓ 配置CMake构建..."
cmake --preset ESP32_S3_W5500_Release

# 验证配置
echo "✓ 验证CMake配置..."
if [ -f "build/build.ninja" ]; then
    echo "  ✅ CMake配置成功"
else
    echo "  ❌ CMake配置失败"
    exit 1
fi

# 显示关键配置
echo "✓ 显示关键配置..."
grep -E "(NF_FEATURE_DEBUGGER|NF_DEBUGGER_NO_PORT|NF_BUILD_RTM)" build/CMakeCache.txt || echo "  部分变量未找到"

# 尝试构建（可选）
echo ""
echo "=== 配置完成 ==="
echo "构建已配置完成，可以运行："
echo "  cmake --build build --target all"
echo ""
echo "或者直接运行完整构建："
echo "  cmake --build --preset ESP32_S3_W5500_Release"