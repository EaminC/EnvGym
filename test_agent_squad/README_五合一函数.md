# 五合一兼容性函数使用说明

## 🚀 概述

五合一兼容性函数将 Python、Go、Rust、Java、C++ 五种编程语言的依赖分析功能统一封装，提供简洁统一的接口。

## 📦 功能特性

- ✅ **统一接口**: 只需两个函数 `get_dependency_tree()` 和 `get_versions()`
- ✅ **自动检测**: 根据包名格式自动识别编程语言
- ✅ **手动指定**: 支持手动指定语言类型
- ✅ **灵活配置**: 支持限制版本数量、包管理器选择等
- ✅ **错误处理**: 完善的异常处理和错误提示

## 🔧 安装使用

```python
from universal_compat import get_dependency_tree, get_versions, get_all_info
```

## 📖 API 文档

### get_dependency_tree()

获取包的依赖树信息。

```python
get_dependency_tree(
    package: str,                    # 包名
    language: Optional[str] = None,  # 编程语言 ('python', 'go', 'rust', 'java', 'cpp')
    package_manager: Optional[str] = None,  # 包管理器 (主要用于C++)
    verbose: bool = False           # 是否显示详细信息
) -> str
```

### get_versions()

获取包的版本信息。

```python
get_versions(
    package: str,                    # 包名
    language: Optional[str] = None,  # 编程语言
    package_manager: Optional[str] = None,  # 包管理器
    limit: Optional[int] = None,     # 限制返回版本数量
    verbose: bool = False           # 是否显示详细信息
) -> str
```

### get_all_info()

一次性获取包的完整信息（依赖树 + 版本信息）。

```python
get_all_info(
    package: str,
    language: Optional[str] = None,
    package_manager: Optional[str] = None,
    limit: Optional[int] = None,
    verbose: bool = False
) -> dict  # {'dependency_tree': str, 'versions': str}
```

## 🌟 使用示例

### 自动语言检测

```python
# Python - 根据 == 格式自动检测
tree = get_dependency_tree("pandas==1.1.1")
versions = get_versions("pandas")

# Go - 根据域名格式自动检测
tree = get_dependency_tree("github.com/gin-gonic/gin@v1.8.0")
versions = get_versions("github.com/gin-gonic/gin")

# Java - 根据冒号分隔格式自动检测
tree = get_dependency_tree("org.springframework:spring-core:5.3.21")
versions = get_versions("org.springframework:spring-core")

# Rust - 根据包名特征自动检测
tree = get_dependency_tree("serde==1.0.140")
versions = get_versions("serde", limit=10)
```

### 手动指定语言

```python
# C++ 需要手动指定语言和包管理器
tree = get_dependency_tree("fmt", language="cpp", package_manager="vcpkg")
versions = get_versions("fmt", language="cpp", package_manager="vcpkg")

# 也可以手动指定其他语言
tree = get_dependency_tree("pandas", language="python")
versions = get_versions("gin", language="go")
```

### 获取完整信息

```python
# 一次获取所有信息
info = get_all_info("pandas", limit=5)
print(f"依赖树: {info['dependency_tree']}")
print(f"版本信息: {info['versions']}")
```

### 详细模式

```python
# 启用详细模式查看自动检测过程
tree = get_dependency_tree("pandas==1.1.1", verbose=True)
# 输出: 🔍 自动检测到语言: python
```

## 🎯 语言检测规则

| 语言   | 检测规则                                        | 示例                              |
| ------ | ----------------------------------------------- | --------------------------------- |
| Go     | 包含域名 (`github.com`, `golang.org`, `go.dev`) | `github.com/gin-gonic/gin`        |
| Java   | 包含冒号且第一部分有点号                        | `org.springframework:spring-core` |
| Rust   | 包含 `==` 且包名简单                            | `serde==1.0.140`                  |
| Python | 默认选择                                        | `pandas`, `pandas==1.1.1`         |
| C++    | 需要手动指定 `language="cpp"`                   | `fmt`                             |

## 🛠️ 支持的包管理器

| 语言   | 包管理器            | 说明                       |
| ------ | ------------------- | -------------------------- |
| Python | PyPI                | 自动使用                   |
| Go     | Go Proxy            | 自动使用                   |
| Rust   | crates.io           | 自动使用                   |
| Java   | Maven Central       | 自动使用                   |
| C++    | vcpkg (默认), conan | 需要指定 `package_manager` |

## 🔄 对比原来的方式

### 原来的方式 (繁琐)

```python
from compat.py.deptree import get_dependency_tree as get_dependency_tree_py
from compat.py.show import get_versions as get_versions_py
from compat.go.deptree import get_dependency_tree as get_dependency_tree_go
from compat.go.show import get_versions as get_versions_go
from compat.rust.deptree import get_dependency_tree as get_dependency_tree_rust
from compat.rust.show import get_versions as get_versions_rust
from compat.java.deptree import get_dependency_tree as get_dependency_tree_java
from compat.java.show import get_versions as get_versions_java
from compat.cpp.deptree import get_dependency_tree as get_dependency_tree_cpp
from compat.cpp.show import get_versions as get_versions_cpp

# 需要记住每个函数名
tree = get_dependency_tree_py("pandas==1.1.1")
versions = get_versions_py("pandas")
tree = get_dependency_tree_go("github.com/gin-gonic/gin@v1.8.0")
# ... 等等
```

### 现在的方式 (简洁)

```python
from universal_compat import get_dependency_tree, get_versions

# 统一的函数，自动检测语言
tree = get_dependency_tree("pandas==1.1.1")
versions = get_versions("pandas")
tree = get_dependency_tree("github.com/gin-gonic/gin@v1.8.0")
versions = get_versions("github.com/gin-gonic/gin")
```

## 🚨 注意事项

1. **C++ 包**: 必须手动指定 `language="cpp"` 和 `package_manager`
2. **网络访问**: 需要网络连接来访问各语言的包仓库
3. **错误处理**: 函数会返回错误信息字符串，而不是抛出异常
4. **版本限制**: 使用 `limit` 参数避免返回过多版本信息

## 🧪 测试文件

- `test_universal.py`: 完整功能测试
- `test_simplified.py`: 简化使用示例
- `universal_compat.py`: 主要实现文件

运行测试：

```bash
python test_universal.py
python test_simplified.py
```
