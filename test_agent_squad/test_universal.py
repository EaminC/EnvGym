"""
五合一兼容性函数测试示例
"""

from universal_compat import get_dependency_tree, get_versions, get_all_info

def test_universal_functions():
    """测试五合一兼容性函数"""
    
    print("=== 🚀 五合一兼容性函数测试 ===\n")
    
    # 测试案例列表
    test_cases = [
        # Python
        {
            'name': '🐍 Python',
            'package': 'pandas==1.1.1',
            'versions_package': 'pandas',
            'language': None  # 自动检测
        },
        
        # Go
        {
            'name': '🐹 Go',
            'package': 'github.com/gin-gonic/gin@v1.8.0',
            'versions_package': 'github.com/gin-gonic/gin',
            'language': None  # 自动检测
        },
        
        # Rust
        {
            'name': '🦀 Rust',
            'package': 'serde==1.0.140',
            'versions_package': 'serde',
            'language': None,  # 自动检测
            'limit': 10
        },
        
        # Java
        {
            'name': '☕ Java',
            'package': 'org.springframework:spring-core:5.3.21',
            'versions_package': 'org.springframework:spring-core',
            'language': None,  # 自动检测
            'limit': 10
        },
        
        # C++
        {
            'name': '⚡ C++',
            'package': 'fmt',
            'versions_package': 'fmt',
            'language': 'cpp',
            'package_manager': 'vcpkg'
        }
    ]
    
    for case in test_cases:
        print(f"{case['name']} 测试:")
        print("-" * 50)
        
        # 测试依赖树
        print("📦 依赖树:")
        kwargs = {}
        if case.get('language'):
            kwargs['language'] = case['language']
        if case.get('package_manager'):
            kwargs['package_manager'] = case['package_manager']
            
        tree = get_dependency_tree(case['package'], **kwargs)
        print(f"  {tree}")
        
        # 测试版本信息
        print("🏷️  版本信息:")
        version_kwargs = kwargs.copy()
        if case.get('limit'):
            version_kwargs['limit'] = case['limit']
            
        versions = get_versions(case['versions_package'], **version_kwargs)
        print(f"  {versions}")
        
        print()

def test_all_info_function():
    """测试获取完整信息的函数"""
    
    print("=== 📋 完整信息测试 ===\n")
    
    # 测试获取完整信息
    package = "pandas"
    print(f"获取 {package} 的完整信息:")
    
    info = get_all_info(package, limit=5)
    print(f"依赖树: {info['dependency_tree']}")
    print(f"版本信息: {info['versions']}")
    print()

def test_language_detection():
    """测试语言自动检测功能"""
    
    print("=== 🔍 语言自动检测测试 ===\n")
    
    test_packages = [
        "pandas==1.1.1",  # Should detect as Python
        "github.com/gin-gonic/gin@v1.8.0",  # Should detect as Go
        "serde==1.0.140",  # Should detect as Rust
        "org.springframework:spring-core:5.3.21",  # Should detect as Java
    ]
    
    for package in test_packages:
        print(f"包名: {package}")
        tree = get_dependency_tree(package, verbose=True)  # verbose=True 显示检测结果
        print(f"结果: {tree[:100]}...")  # 只显示前100个字符
        print()

if __name__ == "__main__":
    # 运行所有测试
    test_universal_functions()
    test_all_info_function()
    test_language_detection()
    
    print("=== ✅ 测试完成 ===")
    print("\n💡 使用提示:")
    print("1. 可以让函数自动检测语言类型")
    print("2. 也可以手动指定 language 参数")
    print("3. C++ 需要指定 package_manager (vcpkg/conan)")
    print("4. 使用 limit 参数限制版本数量")
    print("5. 使用 get_all_info() 一次获取所有信息") 