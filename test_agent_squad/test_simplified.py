"""
使用五合一函数的简化测试
替代原来的分别导入各语言模块的方式
"""

from universal_compat import get_dependency_tree, get_versions

# 原来需要这样导入：
# from compat.py.deptree import get_dependency_tree as get_dependency_tree_py
# from compat.py.show import get_versions as get_versions_py
# from compat.go.deptree import get_dependency_tree as get_dependency_tree_go
# from compat.go.show import get_versions as get_versions_go
# ... 等等

print("=== 🎯 五合一函数简化测试 ===\n")

# Python 测试
print("🐍 Python:")
tree = get_dependency_tree("pandas==1.1.1")
print(f"依赖树: {tree}")

versions = get_versions("pandas")
print(f"版本: {versions}")
print()

# Go 测试
print("🐹 Go:")
tree = get_dependency_tree("github.com/gin-gonic/gin@v1.8.0")
print(f"依赖树: {tree}")

versions = get_versions("github.com/gin-gonic/gin")
print(f"版本: {versions}")
print()

# Rust 测试
print("🦀 Rust:")
tree = get_dependency_tree("serde==1.0.140")
print(f"依赖树: {tree}")

versions = get_versions("serde", limit=10)
print(f"版本: {versions}")
print()

# Java 测试
print("☕ Java:")
tree = get_dependency_tree("org.springframework:spring-core:5.3.21")
print(f"依赖树: {tree}")

versions = get_versions("org.springframework:spring-core", limit=10)
print(f"版本: {versions}")
print()

# C++ 测试
print("⚡ C++:")
tree = get_dependency_tree("fmt", language="cpp", package_manager="vcpkg")
print(f"依赖树: {tree}")

versions = get_versions("fmt", language="cpp", package_manager="vcpkg")
print(f"版本: {versions}")

print("\n✨ 对比原来的方式，现在只需要：")
print("1. 导入一个模块: from universal_compat import get_dependency_tree, get_versions")
print("2. 使用两个函数: get_dependency_tree() 和 get_versions()")
print("3. 支持自动语言检测，也可以手动指定")
print("4. 统一的接口，更简洁的代码！") 