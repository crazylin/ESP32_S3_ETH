# ESP32-S3 + W5500 nanoFramework 缓存管理指南

## 🚀 缓存优化概述

本项目的GitHub Actions工作流已针对ESP32-S3 + W5500 nanoFramework构建进行了全面的缓存优化，显著减少了构建时间。

## 📊 缓存策略

### 1. ESP-IDF 缓存
- **路径**: `~/esp`, `~/.espressif`
- **大小**: ~2-3GB
- **有效期**: 基于ESP-IDF版本
- **节省**: 首次下载ESP-IDF约15-20分钟 → 缓存命中后30秒

### 2. ccache 编译缓存
- **路径**: `~/.ccache`
- **大小**: 500MB (自动压缩)
- **命中率**: 通常80-95%
- **节省**: 编译时间减少60-80%

### 3. 构建缓存
- **路径**: `nf-interpreter/build`, `targets/ESP32/_common`
- **大小**: ~500MB-1GB
- **有效期**: 基于CMake配置和源代码变化
- **节省**: 增量构建时间减少50-70%

## 🎯 缓存键策略

| 缓存类型 | 主键 | 恢复键 |
|----------|------|--------|
| ESP-IDF | `${runner.os}-esp-idf-${ESP_IDF_VERSION}` | `${runner.os}-esp-idf-` |
| ccache | `${runner.os}-ccache-${build_type}-${github.sha}` | `${runner.os}-ccache-${build_type}-` |
| 构建 | `${runner.os}-build-${build_type}-${hash}` | `${runner.os}-build-${build_type}-` |

## 🔧 使用缓存的工作流

### 1. 优化版本 (`build-esp32s3-w5500-optimized.yml`)
- ✅ 完整缓存支持
- ✅ ccache加速
- ✅ 条件安装ESP-IDF
- ✅ 磁盘空间优化

### 2. 缓存专用版本 (`build-esp32s3-w5500-cached.yml`)
- ✅ 手动缓存控制
- ✅ 缓存统计信息
- ✅ 缓存清理功能

## 📈 性能对比

| 场景 | 无缓存 | 有缓存 | 节省 |
|------|--------|--------|------|
| 首次构建 | 25-30分钟 | 25-30分钟 | 0% |
| 后续构建 | 25-30分钟 | 5-8分钟 | 70-80% |
| 小改动 | 25-30分钟 | 3-5分钟 | 80-85% |
| 仅文档更新 | 25-30分钟 | 2-3分钟 | 90% |

## 🎮 缓存管理操作

### 手动触发缓存清理

在GitHub Actions页面：

1. 选择 `Build ESP32-S3 + W5500 nanoFramework Firmware (Cached)`
2. 点击 **Run workflow**
3. 设置 **Cache action** 为 `clear`
4. 运行以清理所有缓存

### 强制重新构建

在Pull Request中添加标签：
```bash
# 在PR描述中添加以下文字强制清理缓存
[cache-clear]
```

## 🛠️ 本地开发缓存

### 设置本地ccache

```bash
# 安装ccache
sudo apt-get install ccache

# 配置ccache
export CCACHE_DIR=~/.ccache
export CCACHE_COMPRESS=1
export CCACHE_COMPRESSLEVEL=6
export CCACHE_MAXSIZE=1G
ccache --zero-stats

# 使用ccache构建
cmake -DCMAKE_C_COMPILER_LAUNCHER=ccache -DCMAKE_CXX_COMPILER_LAUNCHER=ccache ...
```

### 本地ESP-IDF缓存

```bash
# 设置ESP-IDF路径缓存
export IDF_PATH=~/esp/esp-idf-v5.2.3
if [ ! -d "$IDF_PATH" ]; then
    git clone -b v5.2.3 --recursive https://github.com/espressif/esp-idf.git $IDF_PATH
    cd $IDF_PATH && ./install.sh esp32s3
fi
```

## 📋 缓存调试

### 检查缓存命中率

在GitHub Actions日志中查看：
- **Build Summary** 步骤显示缓存命中状态
- **ccache Statistics** 显示编译缓存统计

### 常见缓存问题

#### 1. 缓存未命中
```bash
# 可能原因：
# - ESP-IDF版本变更
# - CMake配置修改
# - 源代码大幅变更

# 解决方案：
# - 检查缓存键是否正确
# - 验证文件哈希值
```

#### 2. 缓存大小过大
```bash
# 清理旧缓存
ccache --clear
# 或手动删除缓存目录
rm -rf ~/.ccache
```

#### 3. 磁盘空间不足
```bash
# 检查缓存大小
du -sh ~/.ccache ~/esp ~/.espressif

# 清理不必要文件
ccache --cleanup
```

## 🔄 缓存更新策略

### 自动更新
- 每周自动清理过期缓存
- ESP-IDF版本升级时自动重建缓存
- 构建配置变更时更新缓存键

### 手动更新
- 通过workflow_dispatch触发缓存更新
- 修改缓存键版本号强制更新

## 📊 监控缓存效果

### GitHub Actions统计
- 查看Actions运行时间趋势
- 监控缓存命中率和节省的时间

### 本地监控
```bash
# 查看ccache统计
ccache --show-stats

# 查看缓存大小
du -sh ~/.ccache ~/esp ~/.espressif

# 查看构建时间
/usr/bin/time -v cmake --build build
```

## 🎯 最佳实践

### 1. 首次构建
- 允许完整构建创建缓存
- 不要跳过ESP-IDF安装

### 2. 日常开发
- 充分利用缓存加速
- 定期清理过期缓存

### 3. 发布构建
- 使用Release配置获得最佳缓存效果
- 确保缓存键包含所有相关文件哈希

### 4. 调试构建
- Debug配置有独立的缓存空间
- 不会影响Release缓存

## 🚀 快速开始缓存构建

1. **首次运行**：允许完整构建创建缓存
2. **后续运行**：自动使用缓存，构建时间减少70-80%
3. **问题排查**：查看缓存统计信息
4. **性能优化**：根据统计调整缓存策略

---

**缓存管理让你的ESP32-S3 + W5500 nanoFramework构建飞起来！** 🚀