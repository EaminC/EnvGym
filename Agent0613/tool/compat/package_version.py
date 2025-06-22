# analyze.py

from .py.deptree import get_dependency_tree as get_dependency_tree_py
from .py.show import get_versions as get_versions_py

from .go.deptree import get_dependency_tree as get_dependency_tree_go
from .go.show import get_versions as get_versions_go

from .rust.deptree import get_dependency_tree as get_dependency_tree_rust
from .rust.show import get_versions as get_versions_rust

from .java.deptree import get_dependency_tree as get_dependency_tree_java
from .java.show import get_versions as get_versions_java

from .cpp.deptree import get_dependency_tree as get_dependency_tree_cpp
from .cpp.show import get_versions as get_versions_cpp


def analyze_package(lang, pkg, limit_version=20):
    """
    Analyze a single package's dependency tree and version list.

    :param lang: Programming language
    :param pkg: Package name with version (format varies by language)
    :param limit_version: Optional version limit (used for all languages)
    :return: Dict with keys: language, package, tree, versions, error
    """
    lang = lang.lower()
    result = {
        "language": lang,
        "package": pkg,
        "tree": None,
        "versions": None,
        "error": None
    }

    try:
        if lang == "python":
            result["tree"] = get_dependency_tree_py(pkg)
            result["versions"] = get_versions_py(pkg.split("==")[0], limit=limit_version)

        elif lang == "go":
            result["tree"] = get_dependency_tree_go(pkg)
            result["versions"] = get_versions_go(pkg.split("@")[0], limit=limit_version)

        elif lang == "rust":
            name = pkg.split("==")[0]
            result["tree"] = get_dependency_tree_rust(pkg)
            result["versions"] = get_versions_rust(name, limit=limit_version)

        elif lang == "java":
            name = ":".join(pkg.split(":")[:2])
            result["tree"] = get_dependency_tree_java(pkg)
            result["versions"] = get_versions_java(name, limit=limit_version)

        elif lang == "cpp":
            # C++ 统一使用 vcpkg 作为默认包管理器，调用方式与其他语言保持一致
            result["tree"] = get_dependency_tree_cpp(pkg, "vcpkg")
            result["versions"] = get_versions_cpp(pkg, "vcpkg", limit=limit_version)

        else:
            raise ValueError(f"Unsupported language: {lang}")

    except Exception as e:
        result["error"] = str(e)

    return result


def analyze_package_formatted(language: str, package_name_and_version: str) -> str:
    """
    分析包并返回格式化的详细输出，适用于AI Agent工具调用
    
    :param language: 编程语言
    :param package_name_and_version: 包名和版本
    :return: 格式化的分析结果字符串
    """
    try:
        result = analyze_package(language, package_name_and_version)
        
        # 格式化详细输出
        output = []
        output.append(f"📦 Package Analysis for {result['package']} ({result['language']})")
        output.append("=" * 60)
        
        if result['error']:
            output.append(f"❌ Error: {result['error']}")
            return "\n".join(output)
        
        # 依赖树信息
        if result['tree']:
            output.append(f"\n🌳 Dependency Tree:")
            output.append(f"{result['tree']}")
        
        # 版本信息
        if result['versions']:
            # 处理版本字符串（可能是逗号分隔的字符串）
            if isinstance(result['versions'], str):
                versions = [v.strip() for v in result['versions'].split(',')]
            else:
                versions = result['versions']
                
            output.append(f"\n📈 Available Versions ({len(versions)} total):")
            if len(versions) > 10:
                output.append(f"Latest 10: {', '.join(versions[:10])}")
                output.append(f"...")
                output.append(f"Oldest 5: {', '.join(versions[-5:])}")
            else:
                output.append(f"All versions: {', '.join(versions)}")
        
        # 兼容性分析提示
        output.append(f"\n🔍 Compatibility Analysis:")
        if result['tree'] and any(dep in result['tree'].lower() for dep in ['numpy', 'requests', 'flask', 'django']):
            output.append(f"- This package has important dependency requirements")
            output.append(f"- Check version compatibility with other packages in your environment")
        else:
            output.append(f"- Review dependency requirements before installation")
        
        return "\n".join(output)
        
    except Exception as e:
        return f"❌ Error analyzing package {package_name_and_version}: {str(e)}"


if __name__ == "__main__":
    print("=" * 60)
    res1 = analyze_package("python", "pandas==1.1.1")
    print(res1["tree"])
    print(res1["versions"])

    print("=" * 60)
    res2 = analyze_package("go", "k8s.io/kubernetes@v1.27.1")
    print(res2["tree"])
    print(res2["versions"])

    print("=" * 60)
    res3 = analyze_package("rust", "tokio==1.28.0")
    print(res3["tree"])
    print(res3["versions"])

    print("=" * 60)
    res4 = analyze_package("java", "org.apache.hadoop:hadoop-common:3.3.6")
    print(res4["tree"])
    print(res4["versions"])

    print("=" * 60)
    res5 = analyze_package("cpp", "fmt==10.0.0")
    print(res5["tree"])
    print(res5["versions"])