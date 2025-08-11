# ESP32-S3 + W5500 nanoFramework GitHub Actions

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
