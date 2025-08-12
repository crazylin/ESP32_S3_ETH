#!/bin/bash

# ESP-IDF Python Dependencies Debug Script
echo "=== ESP-IDF Python Dependencies Debug ==="
echo ""

# Check if ESP-IDF is sourced
echo "1. ESP-IDF Environment Check:"
if [ -n "$IDF_PATH" ]; then
    echo "   ✓ IDF_PATH: $IDF_PATH"
else
    echo "   ✗ IDF_PATH not set"
fi

# Check Python interpreter
echo ""
echo "2. Python Interpreter:"
echo "   Python: $(which python3)"
echo "   Version: $(python3 --version)"

# Check pip location
echo ""
echo "3. Pip Location:"
echo "   pip: $(which pip3)"

# Check ESP-IDF Python environment
echo ""
echo "4. ESP-IDF Python Environment:"
if [ -f "$IDF_PATH/tools/idf_tools.py" ]; then
    echo "   ✓ idf_tools.py found"
    python3 "$IDF_PATH/tools/idf_tools.py" check-python-dependencies
else
    echo "   ✗ idf_tools.py not found"
fi

# Check click module
echo ""
echo "5. Click Module Check:"
python3 -c "import click; print('   ✓ click version:', click.__version__)" 2>/dev/null || echo "   ✗ click module missing"

# Check pyserial
echo ""
echo "6. PySerial Module Check:"
python3 -c "import serial; print('   ✓ pyserial version:', serial.VERSION)" 2>/dev/null || echo "   ✗ pyserial module missing"

# Check pyparsing
echo ""
echo "7. Pyparsing Module Check:"
python3 -c "import pyparsing; print('   ✓ pyparsing version:', pyparsing.__version__)" 2>/dev/null || echo "   ✗ pyparsing module missing"

# List all installed packages
echo ""
echo "8. Installed Python Packages:"
python3 -m pip list | grep -E "(click|pyserial|pyparsing)" || echo "   No matching packages found"

echo ""
echo "=== Debug Complete ==="