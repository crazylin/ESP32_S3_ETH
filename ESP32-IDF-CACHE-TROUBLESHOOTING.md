# ESP-IDF 缓存问题排查指南

## 🔍 常见缓存未命中原因

### 1. 缓存键不匹配
- **ESP-IDF版本变化**：v5.2.2 → v5.2.3
- **requirements.txt变更**：Python依赖更新
- **工具链更新**：xtensa-esp32s3-elf-gcc版本变化

### 2. 路径配置问题
- **缓存路径不完整**：缺少关键目录
- **权限问题**：缓存目录不可写
- **环境变量**：路径引用不一致

### 3. 缓存大小限制
- **GitHub缓存限制**：每个仓库10GB
- **文件大小**：ESP-IDF缓存约2-3GB

## 🛠️ 缓存优化配置

### 完整的ESP-IDF缓存路径
```yaml
- name: Cache ESP-IDF
  uses: actions/cache@v4
  with:
    path: |
      ~/esp/esp-idf                 # ESP-IDF源码
      ~/.espressif/python_env       # Python虚拟环境
      ~/.espressif/tools            # 工具链
      ~/.espressif/dist             # 下载的组件
      ~/.cache/esp32               # 其他缓存
    key: ${{ runner.os }}-esp-idf-${{ env.ESP_IDF_VERSION }}-${{ hashFiles('**/requirements.txt') }}
    restore-keys: |
      ${{ runner.os }}-esp-idf-${{ env.ESP_IDF_VERSION }}-
      ${{ runner.os }}-esp-idf-
```

### 缓存键优化
```yaml
# 包含版本和依赖哈希
key: ${{ runner.os }}-esp-idf-${{ env.ESP_IDF_VERSION }}-${{ hashFiles('**/requirements.txt') }}

# 恢复键层级
restore-keys: |
  ${{ runner.os }}-esp-idf-${{ env.ESP_IDF_VERSION }}-
  ${{ runner.os }}-esp-idf-
```

## 📊 调试缓存问题

### 检查缓存状态
```bash
# 在GitHub Actions中添加调试信息
- name: Debug Cache
  run: |
    echo "Cache key: ${{ steps.cache-keys.outputs.esp_idf_key }}"
    ls -la ~/esp/esp-idf || echo "ESP-IDF directory not found"
    du -sh ~/.espressif || echo "espressif directory not found"
    df -h
```

### 手动触发缓存更新
```bash
# 在workflow_dispatch中添加选项
on:
  workflow_dispatch:
    inputs:
      clear_cache:
        description: 'Clear ESP-IDF cache'
        required: false
        default: 'false'
        type: choice
        options:
        - 'false'
        - 'true'
```

## 🚀 强制缓存重建

### 方法1：修改缓存键
```yaml
# 在缓存键中添加时间戳或版本号
key: ${{ runner.os }}-esp-idf-${{ env.ESP_IDF_VERSION }}-v2
```

### 方法2：清除缓存
```bash
# 在GitHub Actions设置中手动清除缓存
# Settings -> Actions -> Cache -> Delete cache entries
```

## 🎯 最佳实践

### 1. 分层缓存策略
```yaml
# ESP-IDF缓存
- name: Cache ESP-IDF
  id: cache-esp-idf
  uses: actions/cache@v4
  with:
    path: ~/esp/esp-idf
    key: esp-idf-${{ env.ESP_IDF_VERSION }}

# 工具链缓存
- name: Cache ESP-IDF Tools
  uses: actions/cache@v4
  with:
    path: ~/.espressif
    key: esp-idf-tools-${{ env.ESP_IDF_VERSION }}
```

### 2. 缓存大小优化
```yaml
# 只缓存必要文件
path: |
  ~/esp/esp-idf
  ~/.espressif/tools/xtensa-esp32s3-elf
  ~/.espressif/python_env
```

### 3. 缓存验证
```yaml
- name: Validate Cache
  run: |
    if [ -d "~/esp/esp-idf" ]; then
      echo "ESP-IDF cache hit"
      source ~/esp/esp-idf/export.sh
      idf.py --version
    else
      echo "ESP-IDF cache miss"
    fi
```

## 🔧 常见问题解决方案

### 问题1：缓存总是未命中
**解决方案**：
1. 检查缓存键是否包含动态内容
2. 验证缓存路径是否正确
3. 查看Actions日志中的缓存状态

### 问题2：缓存文件损坏
**解决方案**：
1. 手动清除缓存
2. 更新缓存键版本
3. 检查文件权限

### 问题3：缓存大小超限
**解决方案**：
1. 减少缓存路径
2. 使用更精确的缓存键
3. 定期清理旧缓存

## 📈 性能监控

### 缓存命中率统计
```yaml
- name: Cache Statistics
  run: |
    echo "ESP-IDF cache hit: ${{ steps.cache-esp-idf.outputs.cache-hit }}"
    echo "Build cache hit: ${{ steps.cache-build.outputs.cache-hit }}"
```

### 构建时间对比
| 场景 | 无缓存 | 缓存命中 | 节省 |
|------|--------|----------|------|
| 首次构建 | 25-30分钟 | 25-30分钟 | 0% |
| 后续构建 | 25-30分钟 | 2-3分钟 | 90% |
| 工具链更新 | 25-30分钟 | 5-8分钟 | 75% |

## 🚀 Windows缓存特别说明

### Windows缓存行为
在Windows GitHub Actions中，缓存未命中是**完全正常**的：

```
Cache not found for input keys: Windows-esp-idf-tools-v5.2.3
```

**这不是错误**，而是首次运行的预期行为。

### Windows缓存路径
```yaml
# Windows专用缓存配置
- name: Cache ESP-IDF Tools
  uses: actions/cache@v3
  with:
    path: |
      C:\Espressif
      C:\esp\esp-idf\tools
    key: ${{ runner.os }}-esp-idf-tools-${{ env.ESP_IDF_VERSION }}-${{ hashFiles('C:\esp\esp-idf\tools\requirements\*.txt') }}
    restore-keys: |
      ${{ runner.os }}-esp-idf-tools-${{ env.ESP_IDF_VERSION }}-
      ${{ runner.os }}-esp-idf-tools-
```

### Windows缓存检查
```powershell
# Windows缓存检查脚本
Write-Host "=== Windows ESP-IDF Cache Check ==="
Write-Host "ESP-IDF directory: $(Test-Path C:\esp\esp-idf)"
Write-Host "Espressif directory: $(Test-Path C:\Espressif)"
Write-Host "ESP-IDF tools: $(Get-ChildItem C:\Espressif\tools -Directory | Select-Object -ExpandProperty Name)"
Write-Host "Cache size: $([math]::Round((Get-ChildItem C:\Espressif -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1GB, 2)) GB"
```

### Windows缓存性能
| 运行次数 | 缓存状态 | 构建时间 | 说明 |
|----------|----------|----------|------|
| 第1次 | 未命中 | 15-20分钟 | 正常：首次创建缓存 |
| 第2次 | 命中 | 3-5分钟 | 正常：使用缓存 |
| 版本更新 | 未命中 | 15-20分钟 | 正常：ESP-IDF版本变更 |

### 快速诊断

#### Windows缓存验证
```powershell
# 运行Windows缓存诊断
.\troubleshoot-windows-build.ps1 -Verbose

# 检查缓存状态
if (Test-Path C:\Espressif) {
    Write-Host "✅ ESP-IDF工具已缓存"
    Get-ChildItem C:\Espressif\tools -Directory | ForEach-Object {
        Write-Host "  $($_.Name): $($_.LastWriteTime)"
    }
} else {
    Write-Host "⚠️  ESP-IDF工具未缓存（首次运行正常）"
}
```

#### 缓存强制更新
```yaml
# 手动触发缓存刷新
on:
  workflow_dispatch:
    inputs:
      refresh_cache:
        description: 'Force refresh ESP-IDF cache'
        type: boolean
        default: false
```

---

**重要提醒**：在Windows GitHub Actions中，缓存未命中是**完全正常**的行为，特别是在首次运行或ESP-IDF版本更新时。后续运行将显著加速！

---

**使用这些配置后，ESP-IDF缓存应该能够正常工作，显著减少构建时间！**