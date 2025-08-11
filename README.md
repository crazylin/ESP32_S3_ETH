# ESP32-S3 + W5500 nanoFramework 固件

这个仓库包含了为 ESP32-S3 开发板配置的 nanoFramework 固件，专门支持 W5500 以太网模块。

## 硬件配置

### ESP32-S3 引脚分配
- **SPI 接口**:
  - SCLK: GPIO13
  - MISO: GPIO12
  - MOSI: GPIO11
  - CS: GPIO14
  - INT: GPIO10
  - RST: GPIO9

### 支持的硬件
- **开发板**: ESP32-S3
- **以太网模块**: W5500 (SPI 接口)
- **其他**: SD卡、GPIO、I2C、PWM、串口通信

## 构建方式

### 1. GitHub Actions 自动构建 (推荐)

#### 手动触发构建
1. 进入 **Actions** 标签页
2. 选择 **Build ESP32-S3 + W5500 nanoFramework Firmware** 工作流
3. 点击 **Run workflow**
4. 选择构建类型:
   - **Release**: 生产版本，优化大小，禁用调试
   - **Debug**: 开发版本，包含调试信息

#### 推送标签自动发布
- 推送一个版本标签 (如 `v1.0.0`) 到 `main` 分支
- 系统会自动构建 Release 版本并创建 GitHub Release
- 固件文件会自动上传为 Release 资源

### 2. 构建产物

构建完成后，您可以下载以下文件：
- `nanoCLR.bin` - 固件二进制文件
- `nanoCLR.elf` - ELF 调试文件
- `release-notes.md` - 构建说明文档

## 固件特性

### Release 版本
- ✅ 生产优化 (RTM 启用)
- ✅ 调试器禁用
- ✅ 大小优化
- ✅ 最小固件大小

### Debug 版本
- ✅ 完整调试支持
- ✅ 调试符号包含
- ✅ Visual Studio 调试支持
- ✅ 开发友好

## 使用方法

1. **下载固件**: 从 GitHub Actions 或 Releases 下载 `nanoCLR.bin`
2. **烧录固件**: 使用 nanoFramework Flash Tool 烧录到 ESP32-S3
3. **连接硬件**: 按照引脚配置连接 W5500 模块
4. **开发应用**: 使用 Visual Studio + nanoFramework 扩展进行开发

## 网络配置

固件支持以下网络功能：
- TCP/UDP 套接字
- HTTP 客户端/服务器
- WebSocket 支持
- 网络信息获取
- 安全连接 (TLS/SSL)

## 依赖版本

- **ESP-IDF**: v5.2.3
- **nanoFramework**: 最新稳定版本
- **CMake**: 3.16+
- **Ninja**: 1.10+

## 故障排除

### 常见问题
1. **构建失败**: 检查 ESP-IDF 版本是否为 v5.2.3
2. **网络连接问题**: 确认 W5500 引脚连接正确
3. **固件过大**: 使用 Release 版本构建

### 获取帮助
- 查看构建日志了解详细错误信息
- 检查硬件连接和引脚配置
- 参考 nanoFramework 官方文档

## 许可证

本项目遵循 nanoFramework 的许可证条款。
