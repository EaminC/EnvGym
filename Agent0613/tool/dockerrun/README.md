# Docker 执行器

这个模块提供了执行 Dockerfile 并收集运行结果和日志的功能，类似于 `entry.py` 模块的结构。

## 功能特性

- 🐳 **自动构建**：读取 Dockerfile 并自动构建 Docker 镜像
- 🚀 **容器运行**：自动运行构建的容器并收集输出
- 📝 **日志记录**：将构建和运行的详细日志保存到 JSON 文件
- 🧹 **自动清理**：可选择在完成后自动清理生成的镜像
- ⏱️ **超时控制**：支持构建和运行的超时设置

## 使用方法

### 基本用法

```python
from entry import run_dockerfile_with_logs

# 执行 Dockerfile 并记录日志
result = run_dockerfile_with_logs(
    dockerfile_path="path/to/Dockerfile",
    verbose=True,
    cleanup=True
)

print(f"执行状态: {'成功' if result['success'] else '失败'}")
print(f"运行输出: {result['run_output']}")
```

### 简化用法

```python
from entry import execute_dockerfile_simple

# 简单执行，只返回输出字符串
output = execute_dockerfile_simple("path/to/Dockerfile")
print(output)
```

### 高级用法

```python
from entry import DockerRunner, print_execution_result

# 创建 Docker 运行器实例
runner = DockerRunner(output_dir="./docker_logs")

# 手动控制构建和运行过程
build_success, build_out, build_err = runner.build_image("path/to/Dockerfile", "my_image")
if build_success:
    run_success, run_out, run_err = runner.run_container("my_image")

    # 保存结果
    result_file = runner.save_results(
        "path/to/Dockerfile",
        (build_success, build_out, build_err),
        (run_success, run_out, run_err),
        "my_image"
    )

    print(f"结果已保存到: {result_file}")
```

## 输出格式

执行结果会保存为 JSON 格式，包含以下信息：

```json
{
  "timestamp": "20231201_143022",
  "dockerfile_path": "/path/to/Dockerfile",
  "image_name": "envgym_test_1701431422",
  "build": {
    "success": true,
    "stdout": "构建输出...",
    "stderr": "构建错误信息..."
  },
  "run": {
    "success": true,
    "stdout": "运行输出...",
    "stderr": "运行错误信息..."
  }
}
```

## 参数说明

### `run_dockerfile_with_logs()`

- `dockerfile_path`: Dockerfile 文件路径
- `output_dir`: 输出目录路径（可选，默认为 `./output`）
- `verbose`: 是否显示详细输出（默认 `True`）
- `cleanup`: 是否在完成后清理镜像（默认 `True`）

### 返回值

返回一个包含执行结果的字典：

- `success`: 总体执行是否成功
- `build_success`: 构建是否成功
- `run_success`: 运行是否成功
- `build_output`: 构建标准输出
- `build_error`: 构建错误输出
- `run_output`: 运行标准输出
- `run_error`: 运行错误输出
- `result_file`: 结果文件路径
- `image_name`: 生成的镜像名称

## 测试

运行测试脚本：

```bash
cd EnvGym/Agent0613/tool/dockerrun
python test_docker_runner.py
```

## 依赖要求

- Python 3.7+
- Docker（需要在系统中安装并可以通过命令行访问）
- 标准库模块：`subprocess`, `json`, `pathlib`, `datetime`

## 注意事项

1. 确保 Docker 已正确安装并在系统 PATH 中
2. 运行脚本的用户需要有 Docker 执行权限
3. 构建超时默认为 5 分钟，运行超时默认为 60 秒
4. 生成的镜像名称格式为 `envgym_test_{timestamp}`
5. 结果文件会保存在指定的输出目录中
