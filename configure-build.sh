#!/bin/bash

# ESP32-S3 + W5500 nanoFramework Build Configuration Script
# This script handles ESP-IDF path configuration and CMake setup

set -e

echo "=== ESP32-S3 + W5500 nanoFramework Build Configuration ==="

# Ensure we're in nf-interpreter directory
if [ ! -f "CMakeLists.txt" ]; then
    echo "Error: Must be run from nf-interpreter directory"
    exit 1
fi

# Clear IDF_PATH to avoid conflicts
unset IDF_PATH
echo "✓ Cleared IDF_PATH environment variable"

# Verify ESP-IDF installation
if [ ! -d "$HOME/esp/esp-idf" ]; then
    echo "Error: ESP-IDF not found at $HOME/esp/esp-idf"
    exit 1
fi

echo "✓ ESP-IDF found at $HOME/esp/esp-idf"

# Verify ESP-IDF version
source "$HOME/esp/esp-idf/export.sh"
idf.py --version

# Copy CMake presets
echo "✓ Copying CMake presets for ESP32-S3 + W5500..."
cp ../CMakePresets-W5500.json CMakePresets.json

# Configure build
echo "✓ Configuring CMake with ESP32-S3 + W5500 preset..."
cmake --preset ESP32_S3_W5500_Release

echo "=== Configuration Complete ==="
echo "Ready to build with: cmake --build --preset ESP32_S3_W5500_Release --target nanoCLR"