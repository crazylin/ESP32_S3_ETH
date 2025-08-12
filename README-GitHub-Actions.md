# ESP32-S3 + W5500 nanoFramework GitHub Actions

基于 [nanoFramework/nf-interpreter](https://github.com/nanoframework/nf-interpreter) 官方仓库的完整GitHub Actions自动化构建解决方案。

## 🚀 快速开始

### 自动构建
本项目包含3种不同的GitHub Actions工作流，满足不同需求：

| 工作流文件 | 用途 | 特点 |
|------------|------|------|
| `build-esp32s3-w5500-optimized.yml` | 生产级构建 | 缓存优化、矩阵构建、自动发布 |
| `esp32s3-w5500-simple.yml` | 快速测试 | 简洁配置、快速构建 |
| `build-esp32s3-w5500.yml` | 原始版本 | 基础功能 |

### 一键构建
1. 进入 [Actions](../../actions) 页面
2. 选择 `ESP32-S3 W5500 Simple Build` 或 `Build ESP32-S3 + W5500 nanoFramework Firmware (Optimized)`
3. 点击 **Run workflow** 按钮
4. 等待构建完成并下载固件

## 📋 构建配置

### 硬件支持
- **主控芯片**: ESP32-S3 (Xtensa LX7 双核 @ 240MHz)
- **以太网控制器**: W5500 (SPI接口)
- **存储**: 8MB Flash, 8MB PSRAM
- **时钟**: 80MHz SPI频率

### 引脚配置 (W5500)
```
SCLK  -> GPIO13
MISO  -> GPIO12
MOSI  -> GPIO11
CS    -> GPIO14
INT   -> GPIO10
RESET -> GPIO9
```

### 软件功能
- **nanoFramework CLR**: 最新稳定版本
- **网络协议栈**: WiFi + 以太网双网卡
- **文件系统**: SD卡支持 + 内部Flash文件系统
- **外设支持**: GPIO, SPI, I2C, PWM, UART, ADC, DAC
- **蓝牙**: BLE 5.0支持
- **调试**: 可选调试器支持

## 🔧 本地开发

### 环境要求
- **操作系统**: Ubuntu 22.04+ / WSL2 / macOS
- **Python**: 3.11+
- **ESP-IDF**: v5.2.3
- **构建工具**: CMake 3.20+, Ninja

### 本地构建命令
```bash
# 克隆代码
git clone --recursive https://github.com/nanoframework/nf-interpreter.git
cd nf-interpreter

# 设置ESP-IDF
export IDF_PATH=$HOME/esp/esp-idf-v5.2.3
source $IDF_PATH/export.sh

# 使用CMake预设构建
cmake --preset ESP32_S3_W5500_Release
cmake --build --preset ESP32_S3_W5500_Release
```

## 📦 构建产物

构建完成后，可从 [Actions](../../actions) 页面下载以下文件：

| 文件名 | 用途 | 大小 |
|--------|------|------|
| `nanoCLR.bin` | 主CLR固件 | ~1.2MB |
| `nanoCLR.elf` | 调试符号文件 | ~4.5MB |
| `nanoBooter.bin` | Bootloader | ~48KB |
| `partitions.bin` | 分区表 | ~3KB |
| `bootloader.bin` | ESP32引导程序 | ~22KB |

## 🔌 烧录固件

### 方法1: nanoff工具 (推荐)
```bash
# 安装nanoff
dotnet tool install -g nanoff

# 烧录固件 (自动检测端口)
nanoff --target ESP32_S3_ETH --update

# 指定端口烧录
nanoff --target ESP32_S3_ETH --update --serialport COM3
```

### 方法2: esptool.py
```bash
# 烧录完整固件
esptool.py --chip esp32s3 --port COM3 --baud 921600 write_flash \
  0x1000 bootloader.bin \
  0x8000 partitions.bin \
  0x10000 nanoCLR.bin
```

## 📖 文档资源

### 官方文档
- [nanoFramework文档](https://docs.nanoframework.net/)
- [ESP32-S3技术手册](https://docs.espressif.com/projects/esp-idf/en/latest/esp32s3/)
- [W5500芯片手册](https://docs.wiznet.io/Product/iEthernet/W5500/overview)

### 相关链接
- [nanoFramework GitHub](https://github.com/nanoframework/nf-interpreter)
- [ESP-IDF GitHub](https://github.com/espressif/esp-idf)
- [W5500驱动参考](https://github.com/Wiznet/WIZ5500_EVB)

## 🛠️ 故障排除

### 构建问题
```bash
# 清理构建缓存
rm -rf nf-interpreter/build

# 更新子模块
git submodule update --init --recursive

# 验证ESP-IDF安装
idf.py --version
```

### 网络连接问题
- 检查W5500模块供电 (3.3V)
- 验证SPI引脚连接
- 使用逻辑分析仪检查SPI通信

### 内存优化
- Release构建比Debug构建节省约30%空间
- 禁用不必要的API功能
- 使用 `MinSizeRel` 构建类型

## 📄 许可证

本项目基于nanoFramework开源项目，遵循其原始许可证条款。

## 🤝 贡献

欢迎提交Issue和Pull Request来改进构建流程和文档。

---

**最后更新**: 2024年基于nanoFramework最新版本构建

这个仓库包含了用于在 GitHub Actions 中构建 ESP32-S3 + W5500 nanoFramework 固件的完整工作流配置。

## 🚀 工作流文件

### 1. `build-esp32s3-w5500.yml` - 主要构建工作流
- **功能**: 构建 ESP32-S3 + W5500 nanoFramework 固件
- **触发**: 推送到 main 分支或手动触发
- **输出**: 固件文件、发布说明、GitHub Release

### 2. `test-build-env.yml` - 环境测试工作流
- **功能**: 测试构建环境是否正确配置
- **触发**: 推送到 main 分支或手动触发
- **用途**: 调试构建问题，验证工具链

## 🛠️ 构建环境

### Ubuntu 环境
- **操作系统**: Ubuntu 22.04 LTS
- **CMake**: 3.31.6+
- **Ninja**: 最新版本
- **GCC/G++**: 最新版本
- **Python**: 3.12

### ESP-IDF 工具链
- **版本**: v5.2.3
- **目标**: ESP32-S3
- **工具**: xtensa-esp32s3-elf, riscv32-esp-elf, esp32ulp-elf

## 📋 使用方法

### 手动触发构建

1. 进入 **Actions** 标签页
2. 选择 **Build ESP32-S3 + W5500 nanoFramework Firmware**
3. 点击 **Run workflow**
4. 选择构建类型:
   - **Release**: 生产优化版本
   - **Debug**: 调试版本
5. 选择是否上传构建产物
6. 点击 **Run workflow**

### 手动触发环境测试

1. 进入 **Actions** 标签页
2. 选择 **Test Build Environment**
3. 点击 **Run workflow**
4. 等待测试完成，查看结果

## 🔧 故障排除

### 常见问题

#### 1. CMake 找不到 Ninja
```
CMake Error: CMake was unable to find a build program corresponding to "Ninja"
```
**解决方案**: 工作流已包含 `ninja-build` 包安装

#### 2. 编译器未设置
```
CMake Error: CMAKE_C_COMPILER not set, after EnableLanguage
```
**解决方案**: 工作流已包含 `build-essential` 包安装

#### 3. ESP-IDF 环境未设置
```
CMake Error: ESP_IDF_PATH not found
```
**解决方案**: 工作流自动安装和配置 ESP-IDF

### 调试步骤

1. **运行环境测试工作流**:
   - 使用 `test-build-env.yml` 验证环境
   - 检查工具版本和路径

2. **查看构建日志**:
   - 检查 "Verify Build Tools" 步骤输出
   - 检查 "Environment Variables" 输出
   - 检查 "CMake Cache Contents" 输出

3. **检查预设配置**:
   - 验证 `CMakePresets-W5500.json` 语法
   - 确认预设名称正确

## 📁 构建产物

### 固件文件
- `nanoCLR.bin` - 二进制固件文件
- `nanoCLR.elf` - ELF 调试文件

### 文档
- `release-notes.md` - 构建说明和硬件配置

### 自动发布
- 推送到标签时自动创建 GitHub Release
- 包含固件文件和说明文档

## ⚙️ 自定义配置

### 修改构建类型
编辑 `CMakePresets-W5500.json` 中的预设配置

### 修改硬件配置
调整 SPI 引脚配置:
```json
"ESP32_ETHERNET_SCLK_PIN": "13",
"ESP32_ETHERNET_MISO_PIN": "12",
"ESP32_ETHERNET_MOSI_PIN": "11",
"ESP32_ETHERNET_CS_PIN": "14",
"ESP32_ETHERNET_INT_PIN": "10",
"ESP32_ETHERNET_RESET_PIN": "9"
```

### 添加新的 API
在预设的 `cacheVariables` 中添加:
```json
"API_YourNewAPI": "ON"
```

## 🔄 工作流优化

### 缓存策略
- ESP-IDF 工具链缓存
- 构建产物缓存 (30天保留)

### 并行构建
- 使用 `-j$(nproc)` 并行编译
- 支持多核构建加速

### 错误处理
- 详细的错误诊断信息
- 环境验证步骤
- 构建工具检查

## 📞 支持

如果遇到问题:
1. 检查 GitHub Actions 日志
2. 运行环境测试工作流
3. 查看故障排除部分
4. 提交 Issue 描述问题

---

**注意**: 确保仓库有足够的 GitHub Actions 分钟数配额，完整构建可能需要 15-30 分钟。
