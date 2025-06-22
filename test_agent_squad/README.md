# 本地软件包兼容性分析 Agent

这是一个基于 Agent Squad 框架的本地软件包兼容性分析工具，支持多种编程语言的软件包兼容性检查。

## 🌟 功能特性

- **多语言支持**: Python, Rust, Go, Java, C++
- **智能语言检测**: 自动识别包名对应的编程语言
- **多种分析功能**:
  - 软件包兼容性检查
  - 依赖树分析
  - 版本信息查询
- **自然语言处理**: 支持中英文自然语言请求
- **异步处理**: 基于 asyncio 的高性能异步处理
- **详细报告**: 生成详细的兼容性分析报告

## 📁 项目结构

```
test_agent_squad/
├── local_compatibility_agent.py    # 主要的Agent类
├── agent_usage_example.py          # 使用示例
├── quickstart.py                   # 原始的Agent Squad配置
├── test.py                         # 测试脚本
├── debug_json_issue.py             # JSON调试工具
├── sample.txt                      # 示例文本
└── compat/                         # 兼容性检查模块
    ├── py/                         # Python模块
    ├── rust/                       # Rust模块
    ├── go/                         # Go模块
    ├── java/                       # Java模块
    └── cpp/                        # C++模块
```

## 🚀 快速开始

### 1. 安装依赖

```bash
pip install requests python-dotenv
```

### 2. 基本使用

```python
import asyncio
from local_compatibility_agent import create_local_compatibility_agent

async def main():
    # 创建agent
    agent = create_local_compatibility_agent(verbose=True)

    # 自然语言请求
    result = await agent.process_request("检查 pandas 和 numpy 的兼容性")

    if result.success:
        print(result.result)
    else:
        print(f"错误: {result.error}")

asyncio.run(main())
```

### 3. 运行示例

```bash
# 运行使用示例
python agent_usage_example.py

# 运行测试
python test.py
```

## 🔧 API 使用指南

### 创建 Agent 实例

```python
from local_compatibility_agent import create_local_compatibility_agent

# 创建agent (verbose=True开启详细日志)
agent = create_local_compatibility_agent(verbose=True)
```

### 自然语言请求处理

```python
# 兼容性检查
result = await agent.process_request("检查 pandas 和 numpy 的兼容性")

# 依赖树查询
result = await agent.process_request("获取 pandas==1.1.1 的依赖树")

# 版本信息查询
result = await agent.process_request("查看 requests 的版本信息")
```

### 直接调用 Agent 方法

```python
from local_compatibility_agent import CompatibilityRequest, SupportedLanguage

# 创建请求对象
request = CompatibilityRequest(
    language=SupportedLanguage.PYTHON,
    package1="pandas",
    package2="numpy",
    operation="check_compatibility"
)

# 执行兼容性检查
result = await agent.check_compatibility(request)
```

## 🎯 支持的操作

### 1. 兼容性检查 (check_compatibility)

分析两个软件包之间的兼容性，生成详细报告。

```python
# 自然语言
result = await agent.process_request("检查 pandas 和 numpy 的兼容性")

# 直接调用
request = CompatibilityRequest(
    language=SupportedLanguage.PYTHON,
    package1="pandas",
    package2="numpy",
    operation="check_compatibility"
)
result = await agent.check_compatibility(request)
```

### 2. 依赖树分析 (get_dependency_tree)

获取软件包的依赖关系树。

```python
# 自然语言
result = await agent.process_request("获取 pandas==1.1.1 的依赖树")

# 直接调用
request = CompatibilityRequest(
    language=SupportedLanguage.PYTHON,
    package1="pandas==1.1.1",
    operation="get_dependency_tree"
)
result = await agent.get_dependency_tree(request)
```

### 3. 版本信息查询 (get_versions)

查询软件包的可用版本列表。

```python
# 自然语言
result = await agent.process_request("查看 requests 的版本信息")

# 直接调用
request = CompatibilityRequest(
    language=SupportedLanguage.PYTHON,
    package1="requests",
    operation="get_versions"
)
result = await agent.get_versions(request)
```

## 🌍 多语言支持

### Python 包

```python
# 示例包名格式
"pandas"
"pandas==1.1.1"
"requests>=2.0.0"
```

### Rust 包

```python
# 示例包名格式
"serde"
"serde==1.0.140"
"tokio==1.0"
```

### Go 包

```python
# 示例包名格式
"github.com/gin-gonic/gin"
"github.com/gin-gonic/gin@v1.8.0"
"golang.org/x/net"
```

### Java 包

```python
# 示例包名格式
"org.springframework:spring-core"
"org.springframework:spring-core:5.3.21"
"com.fasterxml.jackson.core:jackson-core:2.13.0"
```

### C++ 包

```python
# 示例包名格式
"fmt"
"boost"
"opencv"
```

## 🔍 语言自动检测

Agent 会根据包名格式自动检测编程语言：

- **Python**: 简单包名 (pandas, numpy)
- **Go**: 以 `github.com/` 或 `golang.org/` 开头
- **Java**: 包含冒号的 Maven 格式 (group:artifact:version)
- **Rust**: 包含 `==` 的简单格式
- **C++**: 其他格式或手动指定

## 📊 结果格式

所有操作都返回 `CompatibilityResult` 对象：

```python
@dataclass
class CompatibilityResult:
    success: bool                    # 操作是否成功
    language: str                    # 检测到的语言
    operation: str                   # 执行的操作
    result: str                      # 结果内容
    error: Optional[str] = None      # 错误信息（如果有）
    metadata: Optional[Dict] = None  # 附加元数据
```

## 🛠️ 交互式模式

运行交互式模式进行实时测试：

```bash
python agent_usage_example.py
# 选择选项 2 进入交互模式
```

支持的交互命令示例：

- `检查 pandas numpy 兼容性`
- `获取 requests 版本信息`
- `pandas==1.1.1 依赖树`
- `quit` 或 `exit` 退出

## 🐛 调试和故障排除

### 开启详细日志

```python
agent = create_local_compatibility_agent(verbose=True)
```

### 检查支持的操作和语言

```python
print("支持的语言:", agent.get_supported_languages())
print("支持的操作:", agent.get_supported_operations())
```

### 常见问题

1. **网络连接问题**: 确保可以访问各语言的包管理器 API
2. **包名格式错误**: 参考上述各语言的包名格式示例
3. **依赖缺失**: 确保安装了所需的 Python 包

## 📄 许可证

本项目基于原有的 Agent Squad 框架进行开发，请参考相关许可证要求。

## 🤝 贡献

欢迎提交 issue 和 pull request 来改进这个工具！

## 📧 联系方式

如有问题或建议，请通过 GitHub issue 联系我们。
