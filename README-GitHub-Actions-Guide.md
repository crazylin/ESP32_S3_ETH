# ESP32-S3 + W5500 nanoFramework GitHub Actions 构建指南

基于 [nanoFramework/nf-interpreter](https://github.com/nanoframework/nf-interpreter) 官方仓库的ESP32-S3 + W5500固件构建流程。

## 可用的GitHub Actions工作流

### 1. 优化版本 (`build-esp32s3-w5500-optimized.yml`)
功能丰富的完整构建流程，包含：
- 缓存优化（ESP-IDF和构建缓存）
- 矩阵构建（Release/Debug）
- 自动发布功能
- 详细的构建摘要
- 工件上传

### 2. 简化版本 (`esp32s3-w5500-simple.yml`)
简洁的构建流程，适合：
- 快速测试
- 初学者使用
- 最小化配置

## 使用方法

### 手动触发构建

1. 进入GitHub仓库的 **Actions** 标签页
2. 选择对应的工作流
3. 点击 **Run workflow** 按钮
4. 配置参数：
   - **Build type**: Release（推荐）或 Debug
   - **Target board**: ESP32_S3_ETH（默认）
   - **Upload artifacts**: 是否上传构建结果

### 自动触发

- 推送到 `main` 分支时自动触发
- 创建Pull Request时自动触发

## 构建配置

### 核心组件

基于ESP-IDF v5.2.3，包含以下功能：

- **硬件支持**: ESP32-S3 + W5500以太网
- **文件系统**: 支持SD卡和内部文件系统
- **网络功能**: WiFi + 以太网双网卡支持
- **外设接口**: GPIO, SPI, I2C, PWM, UART
- **蓝牙**: BLE支持
- **调试**: 可选调试器支持

### API支持

```yaml
- System.IO.FileSystem
- Windows.Devices.Gpio
- Windows.Devices.Spi
- Windows.Devices.I2c
- Windows.Devices.Pwm
- Windows.Networking
- nanoFramework.Networking.ESP32.Ethernet
- nanoFramework.Device.Bluetooth
- nanoFramework.Hardware.Esp32
```

## 构建产物

构建完成后，会生成以下文件：

- `nanoCLR.bin` - 主CLR固件
- `nanoCLR.elf` - 带调试信息的ELF文件
- `nanoBooter.bin` - Bootloader
- `partitions.bin` - 分区表
- `bootloader.bin` - ESP32引导程序

## 本地开发环境

### 前置要求

- Ubuntu 22.04+ 或 WSL2
- Python 3.11+
- ESP-IDF v5.2.3
- CMake 3.20+
- Ninja构建系统

### 本地构建步骤

```bash
# 1. 克隆仓库
git clone --recursive https://github.com/nanoframework/nf-interpreter.git
cd nf-interpreter

# 2. 设置ESP-IDF
export IDF_PATH=$HOME/esp/esp-idf-v5.2.3
source $IDF_PATH/export.sh

# 3. 配置构建
cmake -G Ninja \
  -DCMAKE_BUILD_TYPE=MinSizeRel \
  -DCMAKE_TOOLCHAIN_FILE=$IDF_PATH/tools/cmake/toolchain-esp32s3.cmake \
  -DIDF_TARGET=esp32s3 \
  -DTOOLCHAIN_PREFIX=xtensa-esp32s3-elf \
  -DRTOS=ESP32 \
  -DNF_BUILD_RTM=ON \
  -DNF_FEATURE_DEBUGGER=OFF \
  -DAPI_nanoFramework.Networking.ESP32.Ethernet=ON \
  -B build \
  -S .

# 4. 执行构建
cmake --build build --config MinSizeRel
```

## 烧录固件

### 使用nanoff工具（推荐）

```bash
# 安装nanoff
dotnet tool install -g nanoff

# 烧录固件
nanoff --target ESP32_S3_ETH --update --serialport COM3
```

### 使用esptool.py

```bash
# 烧录所有组件
esptool.py --chip esp32s3 --port COM3 --baud 921600 write_flash \
  0x1000 bootloader.bin \
  0x8000 partitions.bin \
  0x10000 nanoCLR.bin
```

## 故障排除

### 常见问题

1. **构建失败**
   - 检查ESP-IDF版本是否为v5.2.3
   - 确保所有子模块已更新: `git submodule update --init --recursive`

2. **网络功能异常**
   - 确认W5500模块连接正确
   - 检查SPI引脚配置

3. **内存不足**
   - 使用Release构建类型
   - 禁用不必要的API功能

### 调试信息

在GitHub Actions构建日志中查看：
- **Build Summary** 步骤包含构建统计信息
- **Upload Artifacts** 步骤确认文件已正确生成

## 贡献指南

1. Fork本仓库
2. 创建功能分支
3. 提交Pull Request
4. 确保所有工作流通过

## 相关资源

- [nanoFramework官方文档](https://docs.nanoframework.net/)
- [ESP32-S3技术参考手册](https://docs.espressif.com/projects/esp-idf/en/latest/esp32s3/api-reference/)
- [W5500数据手册](https://docs.wiznet.io/Product/iEthernet/W5500/overview)

## 许可证

本项目遵循nanoFramework的开源许可证。