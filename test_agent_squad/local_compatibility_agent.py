"""
本地软件包兼容性分析Agent
集成了Python、Rust、Go、Java、C++等多种语言的包兼容性检查功能
"""

import os
import asyncio
import json
from typing import List, Optional, Dict, Any
from dataclasses import dataclass
from enum import Enum

# 导入各语言的兼容性检查模块
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


class SupportedLanguage(Enum):
    """支持的编程语言枚举"""
    PYTHON = "python"
    RUST = "rust"
    GO = "go"
    JAVA = "java"
    CPP = "cpp"


@dataclass
class CompatibilityRequest:
    """兼容性检查请求"""
    language: SupportedLanguage
    package1: str
    package2: Optional[str] = None
    operation: str = "check_compatibility"  # 'check_compatibility', 'get_dependency_tree', 'get_versions'


@dataclass
class CompatibilityResult:
    """兼容性检查结果"""
    success: bool
    language: str
    operation: str
    result: str
    error: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None


class LocalCompatibilityAgent:
    """本地软件包兼容性分析Agent"""
    
    def __init__(self, name: str = "LocalCompatibilityAgent", verbose: bool = False):
        self.name = name
        self.verbose = verbose
        self.supported_languages = list(SupportedLanguage)
        
        # 语言特定的函数映射
        self._dependency_tree_functions = {
            SupportedLanguage.PYTHON: get_dependency_tree_py,
            SupportedLanguage.RUST: get_dependency_tree_rust,
            SupportedLanguage.GO: get_dependency_tree_go,
            SupportedLanguage.JAVA: get_dependency_tree_java,
            SupportedLanguage.CPP: get_dependency_tree_cpp,
        }
        
        self._version_functions = {
            SupportedLanguage.PYTHON: get_versions_py,
            SupportedLanguage.RUST: get_versions_rust,
            SupportedLanguage.GO: get_versions_go,
            SupportedLanguage.JAVA: get_versions_java,
            SupportedLanguage.CPP: get_versions_cpp,
        }
    
    def detect_language_from_package(self, package_name: str) -> Optional[SupportedLanguage]:
        """从包名自动检测编程语言"""
        if self.verbose:
            print(f"🔍 正在检测包 '{package_name}' 的语言类型...")
        
        # Go包的特征 (优先检测)
        if package_name.startswith("github.com/") or package_name.startswith("golang.org/"):
            return SupportedLanguage.GO
        
        # Java包的特征 (优先检测)
        if ":" in package_name and "." in package_name.split(":")[0]:
            return SupportedLanguage.JAVA
        
        # Rust包的特征 (在Python之前检测)
        if "==" in package_name:
            # 常见的Rust包名模式
            package_base = package_name.split("==")[0]
            rust_patterns = ["serde", "tokio", "clap", "regex", "rand", "reqwest", "actix", "diesel"]
            if any(pattern in package_base for pattern in rust_patterns):
                return SupportedLanguage.RUST
            # 如果包名简单且包含版本号，可能是Rust
            if package_base.replace("-", "").replace("_", "").isalnum() and len(package_base) < 20:
                return SupportedLanguage.RUST
        
        # Python包的特征
        if any(char.islower() for char in package_name) and not package_name.startswith("github.com"):
            if package_name.replace("-", "").replace("_", "").replace("=", "").replace(">", "").replace("<", "").replace("!", "").replace("~", "").isalnum():
                return SupportedLanguage.PYTHON
        
        # 默认返回Python
        return SupportedLanguage.PYTHON
    
    async def get_dependency_tree(self, request: CompatibilityRequest) -> CompatibilityResult:
        """获取依赖树"""
        try:
            func = self._dependency_tree_functions.get(request.language)
            if not func:
                return CompatibilityResult(
                    success=False,
                    language=request.language.value,
                    operation="get_dependency_tree",
                    result="",
                    error=f"不支持的语言: {request.language.value}"
                )
            
            if self.verbose:
                print(f"📊 正在获取 {request.language.value} 包 '{request.package1}' 的依赖树...")
            
            # 调用相应语言的依赖树函数
            if request.language == SupportedLanguage.CPP:
                result = func(request.package1, "vcpkg")  # C++需要额外的参数
            else:
                result = func(request.package1)
            
            return CompatibilityResult(
                success=True,
                language=request.language.value,
                operation="get_dependency_tree",
                result=result,
                metadata={"package": request.package1}
            )
            
        except Exception as e:
            return CompatibilityResult(
                success=False,
                language=request.language.value,
                operation="get_dependency_tree",
                result="",
                error=str(e)
            )
    
    async def get_versions(self, request: CompatibilityRequest) -> CompatibilityResult:
        """获取包版本信息"""
        try:
            func = self._version_functions.get(request.language)
            if not func:
                return CompatibilityResult(
                    success=False,
                    language=request.language.value,
                    operation="get_versions",
                    result="",
                    error=f"不支持的语言: {request.language.value}"
                )
            
            if self.verbose:
                print(f"📋 正在获取 {request.language.value} 包 '{request.package1}' 的版本信息...")
            
            # 调用相应语言的版本函数
            if request.language == SupportedLanguage.CPP:
                result = func(request.package1, "vcpkg")  # C++需要额外的参数
            else:
                result = func(request.package1, limit=10)
            
            return CompatibilityResult(
                success=True,
                language=request.language.value,
                operation="get_versions",
                result=result,
                metadata={"package": request.package1}
            )
            
        except Exception as e:
            return CompatibilityResult(
                success=False,
                language=request.language.value,
                operation="get_versions",
                result="",
                error=str(e)
            )
    
    async def check_compatibility(self, request: CompatibilityRequest) -> CompatibilityResult:
        """检查两个包的兼容性"""
        if not request.package2:
            return CompatibilityResult(
                success=False,
                language=request.language.value,
                operation="check_compatibility",
                result="",
                error="兼容性检查需要提供两个包名"
            )
        
        try:
            if self.verbose:
                print(f"🔍 正在检查 {request.language.value} 包兼容性: '{request.package1}' vs '{request.package2}'")
            
            # 获取两个包的依赖树和版本信息
            dep_tree1 = await self.get_dependency_tree(
                CompatibilityRequest(request.language, request.package1)
            )
            dep_tree2 = await self.get_dependency_tree(
                CompatibilityRequest(request.language, request.package2)
            )
            
            versions1 = await self.get_versions(
                CompatibilityRequest(request.language, request.package1)
            )
            versions2 = await self.get_versions(
                CompatibilityRequest(request.language, request.package2)
            )
            
            # 生成兼容性分析报告
            compatibility_report = self._generate_compatibility_report(
                request.package1, request.package2,
                dep_tree1, dep_tree2, versions1, versions2
            )
            
            return CompatibilityResult(
                success=True,
                language=request.language.value,
                operation="check_compatibility",
                result=compatibility_report,
                metadata={
                    "package1": request.package1,
                    "package2": request.package2,
                    "dep_tree1": dep_tree1.result if dep_tree1.success else None,
                    "dep_tree2": dep_tree2.result if dep_tree2.success else None,
                    "versions1": versions1.result if versions1.success else None,
                    "versions2": versions2.result if versions2.success else None,
                }
            )
            
        except Exception as e:
            return CompatibilityResult(
                success=False,
                language=request.language.value,
                operation="check_compatibility",
                result="",
                error=str(e)
            )
    
    def _generate_compatibility_report(
        self, 
        package1: str, 
        package2: str,
        dep_tree1: CompatibilityResult,
        dep_tree2: CompatibilityResult,
        versions1: CompatibilityResult,
        versions2: CompatibilityResult
    ) -> str:
        """生成兼容性分析报告"""
        report = []
        report.append(f"📊 软件包兼容性分析报告")
        report.append(f"=" * 50)
        report.append(f"包1: {package1}")
        report.append(f"包2: {package2}")
        report.append("")
        
        # 依赖树分析
        report.append("🌲 依赖树分析:")
        if dep_tree1.success:
            report.append(f"  {package1}: {dep_tree1.result}")
        else:
            report.append(f"  {package1}: 获取依赖树失败 - {dep_tree1.error}")
        
        if dep_tree2.success:
            report.append(f"  {package2}: {dep_tree2.result}")
        else:
            report.append(f"  {package2}: 获取依赖树失败 - {dep_tree2.error}")
        
        report.append("")
        
        # 版本信息
        report.append("📋 版本信息:")
        if versions1.success:
            report.append(f"  {package1} 可用版本: {versions1.result}")
        else:
            report.append(f"  {package1}: 获取版本失败 - {versions1.error}")
        
        if versions2.success:
            report.append(f"  {package2} 可用版本: {versions2.result}")
        else:
            report.append(f"  {package2}: 获取版本失败 - {versions2.error}")
        
        report.append("")
        
        # 兼容性建议
        report.append("💡 兼容性建议:")
        if dep_tree1.success and dep_tree2.success:
            report.append("  ✅ 成功获取两个包的依赖信息")
            report.append("  📝 建议根据依赖树检查是否存在版本冲突")
        else:
            report.append("  ⚠️  部分包信息获取失败，请检查包名是否正确")
        
        return "\n".join(report)
    
    async def process_request(
        self, 
        user_input: str,
        user_id: str = "default_user",
        session_id: str = "default_session"
    ) -> CompatibilityResult:
        """处理用户请求的主要接口"""
        try:
            # 解析用户输入
            request = self._parse_user_input(user_input)
            
            # 根据操作类型执行相应功能
            if request.operation == "get_dependency_tree":
                return await self.get_dependency_tree(request)
            elif request.operation == "get_versions":
                return await self.get_versions(request)
            elif request.operation == "check_compatibility":
                return await self.check_compatibility(request)
            else:
                return CompatibilityResult(
                    success=False,
                    language=request.language.value,
                    operation=request.operation,
                    result="",
                    error=f"不支持的操作: {request.operation}"
                )
                
        except Exception as e:
            return CompatibilityResult(
                success=False,
                language="unknown",
                operation="parse_request",
                result="",
                error=f"解析请求失败: {str(e)}"
            )
    
    def _parse_user_input(self, user_input: str) -> CompatibilityRequest:
        """解析用户输入，提取包名和操作类型"""
        user_input = user_input.strip().lower()
        
        # 检测操作类型
        if "compatibility" in user_input or "兼容" in user_input:
            operation = "check_compatibility"
        elif "dependency" in user_input or "依赖" in user_input or "tree" in user_input:
            operation = "get_dependency_tree"
        elif "version" in user_input or "版本" in user_input:
            operation = "get_versions"
        else:
            operation = "check_compatibility"  # 默认操作
        
        # 提取包名 (这里简化处理，实际可能需要更复杂的解析)
        # 假设用户输入格式: "check compatibility pandas numpy" 或 "pandas vs numpy"
        words = user_input.replace(",", " ").replace("vs", " ").replace("和", " ").split()
        packages = [word for word in words if not word in ["check", "compatibility", "兼容", "dependency", "依赖", "version", "版本", "tree"]]
        
        if not packages:
            raise ValueError("未找到有效的包名")
        
        package1 = packages[0]
        package2 = packages[1] if len(packages) > 1 else None
        
        # 自动检测语言
        language = self.detect_language_from_package(package1)
        
        return CompatibilityRequest(
            language=language,
            package1=package1,
            package2=package2,
            operation=operation
        )
    
    def get_supported_operations(self) -> List[str]:
        """获取支持的操作列表"""
        return [
            "check_compatibility - 检查两个包的兼容性",
            "get_dependency_tree - 获取包的依赖树",
            "get_versions - 获取包的版本信息"
        ]
    
    def get_supported_languages(self) -> List[str]:
        """获取支持的语言列表"""
        return [lang.value for lang in self.supported_languages]


# 便捷的工厂函数
def create_local_compatibility_agent(verbose: bool = False) -> LocalCompatibilityAgent:
    """创建本地兼容性检查agent的工厂函数"""
    return LocalCompatibilityAgent(verbose=verbose)


# 示例使用
async def main():
    """示例使用方法"""
    agent = create_local_compatibility_agent(verbose=True)
    
    print("🚀 本地软件包兼容性分析Agent已启动")
    print(f"支持的语言: {', '.join(agent.get_supported_languages())}")
    print(f"支持的操作: {', '.join(agent.get_supported_operations())}")
    print("-" * 50)
    
    # 示例请求
    test_requests = [
        "check compatibility pandas numpy",
        "get dependency tree pandas==1.1.1",
        "get versions pandas",
        "check compatibility github.com/gin-gonic/gin github.com/gorilla/mux",
    ]
    
    for request in test_requests:
        print(f"\n📝 处理请求: {request}")
        result = await agent.process_request(request)
        print(f"结果: {'✅ 成功' if result.success else '❌ 失败'}")
        if result.success:
            print(f"输出:\n{result.result}")
        else:
            print(f"错误: {result.error}")
        print("-" * 30)


if __name__ == "__main__":
    asyncio.run(main()) 