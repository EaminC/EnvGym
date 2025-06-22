"""
五合一兼容性函数封装
支持 Python、Go、Rust、Java、C++ 五种编程语言的依赖分析
"""

from typing import Optional, Union
import logging

# 导入各语言模块
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


class UniversalCompatManager:
    """五合一兼容性管理器"""
    
    SUPPORTED_LANGUAGES = ['python', 'py', 'go', 'rust', 'java', 'cpp', 'c++']
    
    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.logger = logging.getLogger(__name__)
        
    def _detect_language(self, package: str) -> str:
        """
        根据包名格式自动检测编程语言
        """
        # Go 模块通常包含域名
        if 'github.com' in package or 'golang.org' in package or 'go.dev' in package:
            return 'go'
        
        # Java 包通常包含组织名称和冒号
        if ':' in package and ('.' in package.split(':')[0]):
            return 'java'
        
        # Rust 包通常较简单，但可能有版本号
        if '==' in package and len(package.split('==')[0].split('.')) <= 2:
            return 'rust'
        
        # 默认返回 Python
        return 'python'
    
    def get_dependency_tree(self, 
                          package: str, 
                          language: Optional[str] = None,
                          package_manager: Optional[str] = None,
                          verbose: Optional[bool] = None) -> str:
        """
        获取依赖树的五合一函数
        
        Args:
            package: 包名（格式因语言而异）
            language: 编程语言 ('python', 'go', 'rust', 'java', 'cpp')
            package_manager: 包管理器（主要用于 C++，如 'vcpkg', 'conan'）
            verbose: 是否显示详细信息
            
        Returns:
            str: 依赖树字符串
        """
        if verbose is None:
            verbose = self.verbose
            
        # 自动检测语言
        if language is None:
            language = self._detect_language(package)
            if verbose:
                print(f"🔍 自动检测到语言: {language}")
        
        # 统一语言名称
        language = language.lower()
        if language == 'py':
            language = 'python'
        elif language == 'c++':
            language = 'cpp'
            
        try:
            if language == 'python':
                return get_dependency_tree_py(package, verbose=verbose)
            
            elif language == 'go':
                return get_dependency_tree_go(package, verbose=verbose)
            
            elif language == 'rust':
                return get_dependency_tree_rust(package, verbose=verbose)
            
            elif language == 'java':
                return get_dependency_tree_java(package, verbose=verbose)
            
            elif language == 'cpp':
                if package_manager is None:
                    package_manager = 'vcpkg'  # 默认使用 vcpkg
                return get_dependency_tree_cpp(package, package_manager, verbose=verbose)
            
            else:
                return f"Error: 不支持的语言 '{language}'. 支持的语言: {', '.join(self.SUPPORTED_LANGUAGES)}"
                
        except Exception as e:
            return f"Error: 获取 {language} 包 '{package}' 的依赖树时出错: {e}"
    
    def get_versions(self, 
                    package: str, 
                    language: Optional[str] = None,
                    package_manager: Optional[str] = None,
                    limit: Optional[int] = None,
                    verbose: Optional[bool] = None) -> str:
        """
        获取版本信息的五合一函数
        
        Args:
            package: 包名（格式因语言而异）
            language: 编程语言 ('python', 'go', 'rust', 'java', 'cpp')
            package_manager: 包管理器（主要用于 C++，如 'vcpkg', 'conan'）
            limit: 限制返回的版本数量
            verbose: 是否显示详细信息
            
        Returns:
            str: 版本列表字符串（逗号分隔）
        """
        if verbose is None:
            verbose = self.verbose
            
        # 自动检测语言
        if language is None:
            language = self._detect_language(package)
            if verbose:
                print(f"🔍 自动检测到语言: {language}")
        
        # 统一语言名称
        language = language.lower()
        if language == 'py':
            language = 'python'
        elif language == 'c++':
            language = 'cpp'
            
        try:
            if language == 'python':
                return get_versions_py(package, limit=limit, verbose=verbose)
            
            elif language == 'go':
                return get_versions_go(package, limit=limit, verbose=verbose)
            
            elif language == 'rust':
                return get_versions_rust(package, limit=limit, verbose=verbose)
            
            elif language == 'java':
                return get_versions_java(package, limit=limit, verbose=verbose)
            
            elif language == 'cpp':
                if package_manager is None:
                    package_manager = 'vcpkg'  # 默认使用 vcpkg
                return get_versions_cpp(package, package_manager, limit=limit, verbose=verbose)
            
            else:
                return f"Error: 不支持的语言 '{language}'. 支持的语言: {', '.join(self.SUPPORTED_LANGUAGES)}"
                
        except Exception as e:
            return f"Error: 获取 {language} 包 '{package}' 的版本信息时出错: {e}"


# 创建全局实例
universal_compat = UniversalCompatManager()

# 便捷函数
def get_dependency_tree(package: str, 
                       language: Optional[str] = None,
                       package_manager: Optional[str] = None,
                       verbose: bool = False) -> str:
    """
    获取依赖树的便捷函数
    
    示例:
        # 自动检测语言
        tree = get_dependency_tree("pandas==1.1.1")
        
        # 指定语言
        tree = get_dependency_tree("github.com/gin-gonic/gin@v1.8.0", language="go")
        tree = get_dependency_tree("serde==1.0.140", language="rust")
        tree = get_dependency_tree("org.springframework:spring-core:5.3.21", language="java")
        tree = get_dependency_tree("fmt", language="cpp", package_manager="vcpkg")
    """
    return universal_compat.get_dependency_tree(package, language, package_manager, verbose)


def get_versions(package: str, 
                language: Optional[str] = None,
                package_manager: Optional[str] = None,
                limit: Optional[int] = None,
                verbose: bool = False) -> str:
    """
    获取版本信息的便捷函数
    
    示例:
        # 自动检测语言
        versions = get_versions("pandas")
        
        # 指定语言和限制
        versions = get_versions("github.com/gin-gonic/gin", language="go")
        versions = get_versions("serde", language="rust", limit=10)
        versions = get_versions("org.springframework:spring-core", language="java", limit=10)
        versions = get_versions("fmt", language="cpp", package_manager="vcpkg")
    """
    return universal_compat.get_versions(package, language, package_manager, limit, verbose)


def get_all_info(package: str, 
                language: Optional[str] = None,
                package_manager: Optional[str] = None,
                limit: Optional[int] = None,
                verbose: bool = False) -> dict:
    """
    获取包的完整信息（依赖树和版本信息）
    
    Returns:
        dict: 包含 'dependency_tree' 和 'versions' 的字典
    """
    return {
        'dependency_tree': get_dependency_tree(package, language, package_manager, verbose),
        'versions': get_versions(package, language, package_manager, limit, verbose)
    }


if __name__ == "__main__":
    # 测试示例
    print("=== 五合一兼容性函数测试 ===\n")
    
    # Python
    print("🐍 Python 测试:")
    print("依赖树:", get_dependency_tree("pandas==1.1.1"))
    print("版本信息:", get_versions("pandas"))
    print()
    
    # Go
    print("🐹 Go 测试:")
    print("依赖树:", get_dependency_tree("github.com/gin-gonic/gin@v1.8.0"))
    print("版本信息:", get_versions("github.com/gin-gonic/gin"))
    print()
    
    # Rust
    print("🦀 Rust 测试:")
    print("依赖树:", get_dependency_tree("serde==1.0.140"))
    print("版本信息:", get_versions("serde", limit=10))
    print()
    
    # Java
    print("☕ Java 测试:")
    print("依赖树:", get_dependency_tree("org.springframework:spring-core:5.3.21"))
    print("版本信息:", get_versions("org.springframework:spring-core", limit=10))
    print()
    
    # C++
    print("⚡ C++ 测试:")
    print("依赖树:", get_dependency_tree("fmt", language="cpp", package_manager="vcpkg"))
    print("版本信息:", get_versions("fmt", language="cpp", package_manager="vcpkg")) 