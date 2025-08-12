#!/bin/bash

# ESP-IDF Dependencies Installation Script
# This script ensures all ESP-IDF Python dependencies are properly installed

set -e

echo "=== ESP-IDF Dependencies Installation ==="

# Check if we're in ESP-IDF directory
if [ ! -f "tools/requirements/requirements.core.txt" ]; then
    echo "Error: Not in ESP-IDF directory or requirements file not found"
    echo "Expected: tools/requirements/requirements.core.txt"
    exit 1
fi

echo "Installing ESP-IDF Python requirements..."

# Install ESP-IDF core requirements
python3 -m pip install -r tools/requirements/requirements.core.txt

# Install additional required packages
python3 -m pip install click pyserial pyparsing

echo "Verifying installations..."

# Verify click
python3 -c "import click; print(f'✓ click: {click.__version__}')" || {
    echo "✗ click installation failed"
    exit 1
}

# Verify pyserial
python3 -c "import serial; print(f'✓ pyserial: {serial.VERSION}')" || {
    echo "✗ pyserial installation failed"
    exit 1
}

# Verify pyparsing
python3 -c "import pyparsing; print(f'✓ pyparsing: {pyparsing.__version__}')" || {
    echo "✗ pyparsing installation failed"
    exit 1
}

echo "=== All ESP-IDF dependencies installed successfully ==="