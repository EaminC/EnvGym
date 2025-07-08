import os
import sys
import glob
from pathlib import Path
from typing import Optional, List, Union

# 添加当前目录到系统路径，确保能导入aider模块
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, current_dir)

try:
    from aider.repomap import RepoMap
except ImportError as e:
    print(f"无法导入 RepoMap: {e}")
    sys.exit(1)


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
        # 简单的 token 估算：按字符数 / 4 (GPT模型大约这个比例)
        return len(text) // 4


def get_repo_map(
    repo_path: Optional[str] = None,
    max_tokens: int = 1024,
    include_patterns: Optional[List[str]] = None,
    exclude_patterns: Optional[List[str]] = None,
    verbose: bool = False
) -> str:
    """
    获取指定仓库的 repo map（使用 aider 的原生实现）
    
    Args:
        repo_path: 仓库路径，默认为当前工作目录
        max_tokens: 最大 token 数量，默认 1024
        include_patterns: 包含的文件模式列表，如 ['*.py', '*.js']
        exclude_patterns: 排除的文件模式列表，如 ['*.pyc', '__pycache__']
        verbose: 是否显示详细信息
    
    Returns:
        str: repo map 字符串
    """
    if repo_path is None:
        repo_path = os.getcwd()
    
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
    
    # 生成 repo map (使用 aider 的原生实现)
    try:
        result = repo_map.get_repo_map(
            chat_files=[],  # 没有聊天文件
            other_files=all_files,
            force_refresh=True
        )
        return result or "无法生成 repo map"
    except Exception as e:
        return f"生成 repo map 时出错: {e}"


def print_repo_map(
    repo_path: Optional[str] = None,
    max_tokens: int = 1024,
    include_patterns: Optional[List[str]] = None,
    exclude_patterns: Optional[List[str]] = None,
    verbose: bool = False
) -> None:
    """
    打印指定仓库的 repo map
    
    Args:
        repo_path: 仓库路径，默认为当前工作目录
        max_tokens: 最大 token 数量，默认 1024
        include_patterns: 包含的文件模式列表
        exclude_patterns: 排除的文件模式列表
        verbose: 是否显示详细信息
    """
    if repo_path is None:
        repo_path = os.getcwd()
    
    print(f"正在生成 {repo_path} 的 repo map...")
    print(f"最大 token 数量: {max_tokens}")
    print("=" * 60)
    
    repo_map = get_repo_map(
        repo_path=repo_path,
        max_tokens=max_tokens,
        include_patterns=include_patterns,
        exclude_patterns=exclude_patterns,
        verbose=verbose
    )
    
    print(repo_map)
    print("=" * 60)
    
    # 计算实际token数量
    actual_tokens = len(repo_map) // 4
    print(f"实际生成的 token 数量: {actual_tokens}")
    print(f"Repo map 生成完成")


def get_current_dir_repo_map(max_tokens: int = 1024, verbose: bool = False) -> str:
    """
    获取当前工作目录的 repo map（最简单的接口）
    
    Args:
        max_tokens: 最大 token 数量，默认 1024
        verbose: 是否显示详细信息
    
    Returns:
        str: repo map 字符串
    """
    return get_repo_map(
        repo_path=None,  # 使用当前目录
        max_tokens=max_tokens,
        verbose=verbose
    )


def main():
    """命令行接口"""
    import argparse
    
    parser = argparse.ArgumentParser(description="生成代码仓库的 repo map")
    parser.add_argument('--path', '-p', default=None, help='仓库路径（默认为当前目录）')
    parser.add_argument('--max-tokens', '-t', type=int, default=1024, help='最大 token 数量（默认 1024）')
    parser.add_argument('--include', '-i', nargs='*', help='包含的文件模式')
    parser.add_argument('--exclude', '-e', nargs='*', help='排除的文件模式')
    parser.add_argument('--verbose', '-v', action='store_true', help='显示详细信息')
    
    args = parser.parse_args()
    
    print_repo_map(
        repo_path=args.path,
        max_tokens=args.max_tokens,
        include_patterns=args.include,
        exclude_patterns=args.exclude,
        verbose=args.verbose
    )


if __name__ == "__main__":
    main()
