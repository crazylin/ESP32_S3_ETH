# ESP32-S3 + W5500 nanoFramework 构建配置

本项目提供了专门为 ESP32-S3 + W5500 以太网模块配置的 nanoFramework 构建配置。

## 文件说明

### 1. CMakePresets-W5500.json
专门为 ESP32-S3 + W5500 配置的 CMake 预设文件，包含：
- **Release 配置**: 优化大小，关闭调试功能
- **Debug 配置**: 启用调试功能，便于开发调试

### 2. .github/workflows/build-esp32s3-w5500-github.yml
GitHub Actions 工作流文件，用于在 GitHub 上自动构建固件。

## W5500 以太网配置

| 功能 | GPIO 引脚 |
|------|-----------|
| SCLK (SPI Clock) | 13 |
| MISO (SPI MISO) | 12 |
| MOSI (SPI MOSI) | 11 |
| CS (SPI Chip Select) | 14 |
| INT (Interrupt) | 10 |
| RESET | 9 |

## 使用方法

### 在 GitHub Actions 上构建

1. **自动触发**: 当您推送代码到 `main` 或 `develop` 分支时，工作流会自动触发
2. **手动触发**: 在 GitHub 仓库的 Actions 页面手动运行工作流
3. **PR 触发**: 创建 Pull Request 时会自动构建

### 构建产物

构建完成后，您可以在 GitHub Actions 的 Artifacts 中下载：
- `ESP32-S3-W5500-Release/` - Release 版本固件
- `ESP32-S3-W5500-Debug/` - Debug 版本固件

## 构建配置详情

### Release 配置
- 目标: ESP32-S3
- 构建类型: MinSizeRel (最小大小)
- 调试器: 关闭
- RTM: 启用
- 以太网支持: W5500

### Debug 配置
- 目标: ESP32-S3
- 构建类型: Debug
- 调试器: 启用
- RTM: 关闭
- 以太网支持: W5500

## 依赖要求

- ESP-IDF v5.0+
- Python 3.10+
- CMake 3.16+
- Ninja 构建系统

## 故障排除

### 常见问题

1. **构建失败**: 检查 ESP-IDF 版本是否兼容
2. **网络错误**: 确保 GitHub Actions 可以访问外部网络
3. **内存不足**: 检查构建环境的内存限制

### 日志查看

在 GitHub Actions 中查看详细构建日志，定位具体错误原因。

## 自定义配置

如需修改引脚配置或其他参数，请编辑 `CMakePresets-W5500.json` 文件中的相应值。

## 支持

如有问题，请：
1. 检查 GitHub Actions 构建日志
2. 确认 ESP-IDF 和 nanoFramework 版本兼容性
3. 验证 W5500 硬件连接配置
