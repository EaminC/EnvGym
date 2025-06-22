import os
import sys
import glob
from pathlib import Path

# 添加 aider 到 sys.path
aider_path = os.path.join(os.path.dirname(__file__), '..', 'Agent0613', 'tool', 'aider')
sys.path.insert(0, aider_path)

from aider.repomap import RepoMap


class SimpleIO:
    """简单的 IO 类，用于 RepoMap"""
    
    def __init__(self, verbose=False):
        self.verbose = verbose
    
    def tool_output(self, message):
        if self.verbose:
            print(f"[INFO] {message}")
    
    def tool_warning(self, message):
        print(f"[WARNING] {message}")
        
    def tool_error(self, message):
        print(f"[ERROR] {message}")
    
    def read_text(self, filename):
        """读取文件内容"""
        try:
            with open(filename, 'r', encoding='utf-8') as f:
                return f.read()
        except Exception as e:
            self.tool_warning(f"无法读取文件 {filename}: {e}")
            return ""


class SimpleModel:
    """简单的模型类，用于 token 计算"""
    
    def token_count(self, text):
        # 简单的 token 估算：按字符数 / 4
        return len(text) // 4


def get_repo_map(repo_path, max_tokens=1024, include_patterns=None, exclude_patterns=None, verbose=False):
    """
    获取指定仓库的 repo map
    
    Args:
        repo_path: 仓库路径
        max_tokens: 最大 token 数量
        include_patterns: 包含的文件模式列表，如 ['*.py', '*.js']
        exclude_patterns: 排除的文件模式列表，如 ['*.pyc', '__pycache__']
        verbose: 是否显示详细信息
    
    Returns:
        str: repo map 字符串
    """
    if not os.path.exists(repo_path):
        raise ValueError(f"仓库路径不存在: {repo_path}")
    
    # 创建简单的 IO 和模型对象
    io = SimpleIO(verbose=verbose)
    model = SimpleModel()
    
    # 创建 RepoMap 实例
    repo_map = RepoMap(
        map_tokens=max_tokens,
        root=repo_path,
        main_model=model,
        io=io,
        verbose=verbose
    )
    
    # 获取所有源文件
    all_files = []
    
    # 默认包含的文件扩展名
    default_includes = [
        '*.py', '*.js', '*.ts', '*.tsx', '*.jsx', 
        '*.java', '*.cpp', '*.c', '*.h', '*.hpp',
        '*.cs', '*.go', '*.rs', '*.php', '*.rb',
        '*.swift', '*.kt', '*.scala', '*.clj',
        '*.html', '*.css', '*.scss', '*.less',
        '*.md', '*.txt', '*.yaml', '*.yml', '*.json',
        '*.toml', '*.ini', '*.cfg'
    ]
    
    # 默认排除的模式
    default_excludes = [
        '*.pyc', '*__pycache__*', '*.egg-info*',
        'node_modules*', '*.git*', '*.svn*',
        '*.build*', '*.dist*', '*.tmp*', '*.temp*',
        '*.log', '*.cache*', '.DS_Store'
    ]
    
    include_patterns = include_patterns or default_includes
    exclude_patterns = exclude_patterns or default_excludes
    
    # 收集文件
    for root, dirs, files in os.walk(repo_path):
        # 过滤目录
        dirs[:] = [d for d in dirs if not any(
            Path(os.path.join(root, d)).match(pattern) for pattern in exclude_patterns
        )]
        
        for file in files:
            file_path = os.path.join(root, file)
            rel_path = os.path.relpath(file_path, repo_path)
            
            # 检查是否匹配包含模式
            if any(Path(rel_path).match(pattern) for pattern in include_patterns):
                # 检查是否匹配排除模式
                if not any(Path(rel_path).match(pattern) for pattern in exclude_patterns):
                    all_files.append(file_path)
    
    if verbose:
        print(f"找到 {len(all_files)} 个文件")
    
    if not all_files:
        return "没有找到符合条件的文件"
    
    # 生成 repo map
    try:
        result = repo_map.get_repo_map(
            chat_files=[],  # 没有聊天文件
            other_files=all_files,
            force_refresh=True
        )
        return result or "无法生成 repo map"
    except Exception as e:
        return f"生成 repo map 时出错: {e}"


def print_repo_map(repo_path, max_tokens=1024, include_patterns=None, exclude_patterns=None, verbose=False):
    """
    打印指定仓库的 repo map
    """
    print(f"正在生成 {repo_path} 的 repo map...")
    print("=" * 50)
    
    repo_map = get_repo_map(
        repo_path=repo_path,
        max_tokens=max_tokens,
        include_patterns=include_patterns,
        exclude_patterns=exclude_patterns,
        verbose=verbose
    )
    
    print(repo_map)
    print("=" * 50)
    print(f"Repo map 生成完成")


# 测试函数
if __name__ == "__main__":
    # 测试当前项目
    current_repo = os.path.join(os.path.dirname(__file__), '..')
    print_repo_map(current_repo, max_tokens=2048, verbose=True)
    
    # 也可以测试 Python 文件
    print("\n" + "="*60 + "\n")
    print("仅包含 Python 文件的 repo map:")
    print_repo_map(current_repo, max_tokens=1024, include_patterns=['*.py'], verbose=True)


# 额外的工具函数
def get_typescript_repo_map(repo_path, max_tokens=1024, verbose=False):
    """获取 TypeScript/JavaScript 项目的 repo map"""
    patterns = ['*.ts', '*.tsx', '*.js', '*.jsx', '*.json']
    return get_repo_map(repo_path, max_tokens, patterns, verbose=verbose)


def get_web_repo_map(repo_path, max_tokens=1024, verbose=False):
    """获取 Web 项目的 repo map"""
    patterns = ['*.html', '*.css', '*.js', '*.ts', '*.jsx', '*.tsx', '*.vue', '*.svelte']
    return get_repo_map(repo_path, max_tokens, patterns, verbose=verbose)


def get_java_repo_map(repo_path, max_tokens=1024, verbose=False):
    """获取 Java 项目的 repo map"""
    patterns = ['*.java', '*.kt', '*.scala']
    return get_repo_map(repo_path, max_tokens, patterns, verbose=verbose)


def compare_repo_maps(repo_path1, repo_path2, max_tokens=1024, verbose=False):
    """比较两个仓库的 repo map"""
    print(f"仓库 1: {repo_path1}")
    print("="*50)
    map1 = get_repo_map(repo_path1, max_tokens, verbose=verbose)
    print(map1)
    
    print(f"\n仓库 2: {repo_path2}")
    print("="*50)
    map2 = get_repo_map(repo_path2, max_tokens, verbose=verbose)
    print(map2)
    
    return map1, map2


def get_filtered_repo_map(repo_path, keywords, max_tokens=1024, verbose=False):
    """获取包含特定关键词文件的 repo map"""
    all_files = []
    
    for root, dirs, files in os.walk(repo_path):
        for file in files:
            file_path = os.path.join(root, file)
            if any(keyword in file.lower() for keyword in keywords):
                all_files.append(file_path)
    
    if verbose:
        print(f"找到包含关键词 {keywords} 的 {len(all_files)} 个文件")
    
    if not all_files:
        return "没有找到包含指定关键词的文件"
    
    # 创建简单的 IO 和模型对象
    io = SimpleIO(verbose=verbose)
    model = SimpleModel()
    
    # 创建 RepoMap 实例
    repo_map = RepoMap(
        map_tokens=max_tokens,
        root=repo_path,
        main_model=model,
        io=io,
        verbose=verbose
    )
    
    try:
        result = repo_map.get_repo_map(
            chat_files=[],
            other_files=all_files,
            force_refresh=True
        )
        return result or "无法生成 repo map"
    except Exception as e:
        return f"生成 repo map 时出错: {e}"


# 使用示例：
"""
使用示例：

# 基本使用
from test_aider import get_repo_map, print_repo_map

# 生成当前项目的 repo map
repo_map = get_repo_map(".", max_tokens=1024, verbose=True)
print(repo_map)

# 只查看 Python 文件
python_map = get_repo_map(".", include_patterns=['*.py'], verbose=True)

# 只查看特定关键词的文件
agent_files = get_filtered_repo_map(".", ["agent", "test"], verbose=True)

# 比较两个项目
compare_repo_maps("./project1", "./project2")

# 针对特定语言的 repo map
ts_map = get_typescript_repo_map("./frontend", max_tokens=2048)
java_map = get_java_repo_map("./backend", max_tokens=2048)
"""
