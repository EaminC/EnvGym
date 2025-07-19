# API 统计工具

这个工具用于记录和跟踪 Forge API 的使用情况，包括 token 使用量、请求次数和成本等信息。

## 功能特性

- 自动记录会话开始和结束时的 API 使用统计
- 计算会话期间的使用量差值
- 保存详细的统计信息到 JSON 文件
- 支持命令行独立使用

## 数据记录

工具会记录以下所有 API 返回的字段：

- `provider_name`: API 提供商名称 (如 "OpenAI")
- `model`: 使用的模型 (如 "gpt-4.1")
- `input_tokens`: 输入 token 数量
- `output_tokens`: 输出 token 数量
- `total_tokens`: 总 token 数量
- `requests_count`: 请求次数
- `cost`: 成本 (美元)

## 使用方法

### 1. 集成到 agent.py

工具已经集成到主程序中，会在执行开始时自动记录会话开始统计，在结束时记录会话结束统计。

### 2. 命令行独立使用

```bash
# 记录会话开始
python Agent/tool/stats/entry.py start

# 记录会话结束
python Agent/tool/stats/entry.py end

# 检查当前 API 状态
python Agent/tool/stats/entry.py check

# 启用详细输出
python Agent/tool/stats/entry.py check --verbose
```

### 3. 编程方式使用

```python
from tool.stats.entry import StatsTool

# 创建工具实例
stats_tool = StatsTool(verbose=True)

# 记录会话开始
stats_tool.record_session_start()

# 记录会话结束
stats_tool.record_session_end()

# 检查当前状态
stats_tool.run("check")
```

## 输出文件

统计信息会保存到 `envgym/stat.json` 文件，包含以下结构：

```json
{
  "session_start": "2024-01-01T10:00:00",
  "session_end": "2024-01-01T11:00:00",
  "start_stats": [...],
  "end_stats": [...],
  "usage_delta": {
    "input_tokens": 1000,
    "output_tokens": 500,
    "total_tokens": 1500,
    "requests_count": 10,
    "cost": 0.001234
  },
  "api_info": {
    "provider_name": "OpenAI",
    "model": "gpt-4.1"
  },
  "execution_info": {}
}
```

## 配置要求

确保 `.env` 文件中包含以下配置：

```bash
FORGE_API_KEY=your-forge-api-key-here
FORGE_BASE_URL=https://api.forge.tensorblock.co
```

## 测试

运行测试脚本验证功能：

```bash
python Agent/tool/stats/test_stats.py
```
