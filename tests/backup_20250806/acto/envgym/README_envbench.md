# EnvBench 脚本修改说明

## 修改概述

对 `envbench.sh` 脚本进行了以下增强：

1. **Dockerfile 检查逻辑**：如果 Dockerfile 不存在，测评直接 0 分
2. **Docker Build 检查逻辑**：如果 Docker build 失败，测评直接 0 分  
3. **JSON 结果输出**：所有 PASS/FAIL/WARN 结果写入 `envgym/envbench.json` 文件

## 新增功能

### 1. Dockerfile 检查
- 检查 `envgym/envgym.dockerfile` 是否存在
- 如果不存在，创建 JSON 文件并设置分数为 0
- 输出错误信息并退出

### 2. Docker Build 检查
- 检查 Docker 镜像构建是否成功
- 如果构建失败，创建 JSON 文件并设置分数为 0
- 输出错误信息并退出

### 3. JSON 结果输出
- 所有测试结果都会记录到 JSON 数组中
- 包含测试状态、消息和时间戳
- 生成测试摘要（总数、通过数、失败数、警告数、分数）
- 最终写入 `envgym/envbench.json` 文件

## JSON 输出格式

```json
{
  "test_summary": {
    "total_tests": 45,
    "pass_count": 42,
    "fail_count": 2,
    "warn_count": 1,
    "score": 93
  },
  "results": [
    {
      "status": "PASS",
      "message": "Python is installed",
      "timestamp": "2024-01-15T10:30:00Z"
    },
    {
      "status": "FAIL", 
      "message": "Dockerfile not found",
      "timestamp": "2024-01-15T10:30:01Z"
    }
  ],
  "timestamp": "2024-01-15T10:31:07Z"
}
```

## 分数计算

- **分数公式**：`(PASS_COUNT * 100) / (PASS_COUNT + FAIL_COUNT + WARN_COUNT)`
- **0 分情况**：
  - Dockerfile 不存在
  - Docker build 失败

## 使用方法

```bash
# 运行环境测评
./envbench.sh

# 查看 JSON 结果
cat envgym/envbench.json

# 使用 jq 解析 JSON 结果
jq '.test_summary.score' envgym/envbench.json
```

## 新增文件

- `test_envbench.sh`：测试脚本，验证修改是否正确
- `envbench_example.json`：示例 JSON 输出格式
- `README_envbench.md`：本说明文件

## 测试验证

运行测试脚本验证修改：

```bash
./test_envbench.sh
```

测试脚本会检查：
- 脚本是否存在且可执行
- Dockerfile 是否存在
- JSON 输出功能是否存在
- Dockerfile 检查逻辑是否存在
- Docker build 检查逻辑是否存在 