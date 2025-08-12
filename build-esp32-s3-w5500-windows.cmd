@echo off
REM ESP32-S3 + W5500 nanoFramework Windows构建脚本
REM 基于官方nanoFramework ESP32构建文档

title ESP32-S3 + W5500 nanoFramework 构建

REM 设置控制台颜色
set "COLOR_RESET=[0m"
set "COLOR_GREEN=[32m"
set "COLOR_RED=[31m"
set "COLOR_YELLOW=[33m"
set "COLOR_CYAN=[36m"

REM 初始化变量
set "BUILD_TYPE=Release"
set "SKIP_BUILD=0"
set "VERBOSE=0"

:parse_args
if "%~1"=="" goto :main
if /i "%~1"=="debug" (
    set "BUILD_TYPE=Debug"
    shift
    goto :parse_args
)
if /i "%~1"=="release" (
    set "BUILD_TYPE=Release"
    shift
    goto :parse_args
)
if /i "%~1"=="skip" (
    set "SKIP_BUILD=1"
    shift
    goto :parse_args
)
if /i "%~1"=="verbose" (
    set "VERBOSE=1"
    shift
    goto :parse_args
)
if /i "%~1"=="help" goto :show_help
if /i "%~1"=="?" goto :show_help
goto :parse_args

:show_help
echo %COLOR_CYAN%ESP32-S3 + W5500 nanoFramework Windows构建脚本%COLOR_RESET%
echo.
echo 用法: %~nx0 [debug^|release] [skip] [verbose] [help]
echo.
echo 参数:
echo   debug     构建Debug版本
echo   release   构建Release版本 (默认)
echo   skip      跳过实际构建，仅验证环境
echo   verbose   显示详细信息
echo   help      显示此帮助信息
echo.
echo 示例:
echo   %~nx0 debug verbose    - 构建Debug版本并显示详细信息
echo   %~nx0 release skip     - 仅验证Release环境
pause
exit /b 0

:main
cls
echo %COLOR_CYAN%=== ESP32-S3 + W5500 nanoFramework Windows构建 ===%COLOR_RESET%
echo 构建类型: %BUILD_TYPE%
echo.

REM 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %COLOR_RED%错误: 需要管理员权限运行此脚本%COLOR_RESET%
    echo 请右键点击脚本选择"以管理员身份运行"
    pause
    exit /b 1
)

REM 检查必需目录
echo %COLOR_YELLOW%1. 检查项目结构...%COLOR_RESET%
set "required_paths[0]=C:\esp\esp-idf"
set "required_paths[1]=C:\nanoFramework\nf-interpreter"
set "required_paths[2]=CMakePresets-W5500.json"
set "required_paths[3]=CMakeLists-patch-updated.txt"

set "all_found=1"
for /l %%i in (0,1,3) do (
    set "path_var=!required_paths[%%i]!"
    if %%i lss 2 (
        if exist "!path_var!" (
            echo %COLOR_GREEN%✅ 找到: !path_var!%COLOR_RESET%
        ) else (
            echo %COLOR_RED%❌ 未找到: !path_var!%COLOR_RESET%
            set "all_found=0"
        )
    ) else (
        if exist "!path_var!" (
            echo %COLOR_GREEN%✅ 找到: !path_var!%COLOR_RESET%
        ) else (
            echo %COLOR_RED%❌ 未找到: !path_var!%COLOR_RESET%
            set "all_found=0"
        )
    )
)

if %all_found%==0 (
    echo %COLOR_RED%项目结构检查失败%COLOR_RESET%
    pause
    exit /b 1
)

echo.
echo %COLOR_YELLOW%2. 检查构建工具...%COLOR_RESET%

REM 检查必需工具
set "tools[0]=python"
set "tools[1]=cmake"
set "tools[2]=ninja"
set "tools[3]=git"

for /l %%i in (0,1,3) do (
    set "tool=!tools[%%i]!"
    for /f "tokens=*" %%v in ('"!tool!" --version 2^>nul') do (
        set "version=%%v"
        goto :tool_found_%%i
    )
    echo %COLOR_RED%❌ 未找到: !tool!%COLOR_RESET%
    pause
    exit /b 1
    :tool_found_%%i
    echo %COLOR_GREEN%✅ !tool!: !version!%COLOR_RESET%
)

echo.
echo %COLOR_YELLOW%3. 检查ESP-IDF工具链...%COLOR_RESET%

REM 检查ESP32-S3工具链
set "toolchain_found=0"
for /f "tokens=*" %%p in ('dir /b /s "C:\Espressif\tools\xtensa-esp32s3-elf-*\xtensa-esp32s3-elf\bin\xtensa-esp32s3-elf-gcc.exe" 2^>nul') do (
    set "gcc_path=%%p"
    set "toolchain_found=1"
    goto :toolchain_found
)

for /f "tokens=*" %%p in ('dir /b /s "C:\Espressif\tools\xtensa-esp-elf-*\xtensa-esp-elf\bin\xtensa-esp-elf-gcc.exe" 2^>nul') do (
    set "gcc_path=%%p"
    set "toolchain_found=1"
    goto :toolchain_found
)

:toolchain_found
if %toolchain_found%==1 (
    for /f "tokens=*" %%v in ('"!gcc_path!" --version 2^>nul') do (
        set "gcc_version=%%v"
    )
    echo %COLOR_GREEN%✅ ESP32-S3工具链: !gcc_path!%COLOR_RESET%
    echo %COLOR_GREEN%✅ GCC版本: !gcc_version!%COLOR_RESET%
    set "CC=!gcc_path!"
    set "CXX=!gcc_path:gcc.exe=g++.exe!"
) else (
    echo %COLOR_RED%❌ ESP32-S3工具链未找到%COLOR_RESET%
    echo %COLOR_YELLOW%请运行ESP-IDF安装器或检查C:\Espressif\tools目录%COLOR_RESET%
    pause
    exit /b 1
)

echo.
echo %COLOR_YELLOW%4. 检查ESP-IDF环境...%COLOR_RESET%

REM 设置ESP-IDF环境变量
if not defined IDF_PATH (
    set "IDF_PATH=C:\esp\esp-idf"
    echo %COLOR_YELLOW%⚠️  IDF_PATH未设置，使用默认值: !IDF_PATH!%COLOR_RESET%
) else (
    echo %COLOR_GREEN%✅ IDF_PATH: !IDF_PATH!%COLOR_RESET%
)

if not defined IDF_TOOLS_PATH (
    set "IDF_TOOLS_PATH=C:\Espressif"
    echo %COLOR_YELLOW%⚠️  IDF_TOOLS_PATH未设置，使用默认值: !IDF_TOOLS_PATH!%COLOR_RESET%
) else (
    echo %COLOR_GREEN%✅ IDF_TOOLS_PATH: !IDF_TOOLS_PATH!%COLOR_RESET%
)

REM 验证ESP-IDF
if exist "!IDF_PATH!\tools\idf.py" (
    for /f "tokens=*" %%v in ('python "!IDF_PATH!\tools\idf.py" --version 2^>nul') do (
        echo %COLOR_GREEN%✅ ESP-IDF: %%v%COLOR_RESET%
    )
) else (
    echo %COLOR_RED%❌ ESP-IDF未正确安装%COLOR_RESET%
    pause
    exit /b 1
)

echo.
echo %COLOR_YELLOW%5. 检查项目配置...%COLOR_RESET%

REM 切换到nf-interpreter目录
set "nf_interpreter_path=C:\nanoFramework\nf-interpreter"
if exist "!nf_interpreter_path!" (
    cd /d "!nf_interpreter_path!"
) else (
    echo %COLOR_RED%❌ nanoFramework目录不存在: !nf_interpreter_path!%COLOR_RESET%
    pause
    exit /b 1
)

REM 复制配置文件
if exist "%CD%\CMakePresets-W5500.json" (
    copy /y "%CD%\CMakePresets-W5500.json" "CMakePresets.json" >nul
    echo %COLOR_GREEN%✅ CMake预设已复制%COLOR_RESET%
) else (
    copy /y "%~dp0CMakePresets-W5500.json" "CMakePresets.json" >nul
    echo %COLOR_GREEN%✅ CMake预设已复制%COLOR_RESET%
)

REM 应用CMake补丁
if not exist "targets\ESP32\_IDF" (
    mkdir "targets\ESP32\_IDF" >nul
)

if exist "%~dp0CMakeLists-patch-updated.txt" (
    copy /y "%~dp0CMakeLists-patch-updated.txt" "targets\ESP32\_IDF\CMakeLists-patch.cmake" >nul
    echo %COLOR_GREEN%✅ CMake补丁已应用%COLOR_RESET%
) else (
    echo %COLOR_RED%❌ CMake补丁文件不存在%COLOR_RESET%
    pause
    exit /b 1
)

echo.
echo %COLOR_YELLOW%6. 验证JSON配置...%COLOR_RESET%

REM 验证JSON格式
python -c "import json; json.load(open('CMakePresets.json'))" 2>nul
if %errorlevel% neq 0 (
    echo %COLOR_RED%❌ CMakePresets.json格式错误%COLOR_RESET%
    pause
    exit /b 1
) else (
    echo %COLOR_GREEN%✅ CMakePresets.json格式正确%COLOR_RESET%
)

REM 检查必需预设
if %BUILD_TYPE%==Release (
    set "preset_name=ESP32_S3_W5500_Release"
) else (
    set "preset_name=ESP32_S3_W5500_Debug"
)

echo %COLOR_GREEN%✅ 使用预设: !preset_name!%COLOR_RESET%

if %SKIP_BUILD%==1 (
    echo %COLOR_YELLOW%跳过构建 (--skip)%COLOR_RESET%
    goto :success
)

echo.
echo %COLOR_YELLOW%7. 测试CMake配置...%COLOR_RESET%

REM 清理之前的构建
if exist "build" (
    rmdir /s /q "build"
)

REM 配置构建
cmake --preset !preset_name!
if %errorlevel% neq 0 (
    echo %COLOR_RED%❌ CMake配置失败%COLOR_RESET%
    echo %COLOR_YELLOW%检查构建日志获取详细信息%COLOR_RESET%
    pause
    exit /b 1
)

echo %COLOR_GREEN%✅ CMake配置成功%COLOR_RESET%

echo.
echo %COLOR_YELLOW%8. 验证构建文件...%COLOR_RESET%

set "build_files[0]=build\build.ninja"
set "build_files[1]=build\CMakeCache.txt"

for /l %%i in (0,1,1) do (
    set "file=!build_files[%%i]!"
    if exist "!file!" (
        echo %COLOR_GREEN%✅ 构建文件已创建: !file!%COLOR_RESET%
    ) else (
        echo %COLOR_RED%❌ 构建文件缺失: !file!%COLOR_RESET%
        pause
        exit /b 1
    )
)

if %VERBOSE%==1 (
    echo.
    echo %COLOR_YELLOW%9. 执行完整构建测试...%COLOR_RESET%
    
    cmake --build build --config MinSizeRel
    if %errorlevel% neq 0 (
        echo %COLOR_YELLOW%⚠️  完整构建失败，但配置成功%COLOR_RESET%
    ) else (
        echo %COLOR_GREEN%✅ 完整构建成功%COLOR_RESET%
        
        if exist "build\nanoCLR.bin" (
            for %%a in ("build\nanoCLR.bin") do (
                set "size=%%~za"
            )
            echo %COLOR_GREEN%✅ 输出文件: build\nanoCLR.bin (!size! bytes)%COLOR_RESET%
        )
        
        if exist "build\nanoCLR.elf" (
            for %%a in ("build\nanoCLR.elf") do (
                set "size=%%~za"
            )
            echo %COLOR_GREEN%✅ 输出文件: build\nanoCLR.elf (!size! bytes)%COLOR_RESET%
        )
    )
)

:success
echo.
echo %COLOR_GREEN%=== Windows构建环境验证完成 ===%COLOR_RESET%
echo %COLOR_GREEN%所有检查通过，环境已就绪%COLOR_RESET%
echo.
echo %COLOR_CYAN%下一步操作:%COLOR_RESET%
echo   1. 运行: cmake --build build
echo   2. 使用: nanoff工具刷写固件
echo   3. 测试: W5500以太网连接
echo.
pause