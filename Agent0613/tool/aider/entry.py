"""
Entry point for aider-based repository mapping functionality.
This module provides the interface to our custom repo map tool.
"""

import sys
import os
from pathlib import Path

# 添加项目根目录到 Python 路径
project_root = Path(__file__).resolve().parent.parent.parent.parent
tool_tests_path = project_root / "tool_tests"
sys.path.insert(0, str(tool_tests_path))

# 导入我们的 repo map 工具
from test_aider import get_repo_map, print_repo_map

# 重新导出主要函数，使其可以从其他模块使用
__all__ = ['get_repo_map', 'print_repo_map']

def generate_repository_map(repo_path, max_tokens=1024, include_patterns=None, exclude_patterns=None, verbose=False):
    """
    Wrapper function for get_repo_map with more descriptive name.
    
    Args:
        repo_path: Path to the repository to analyze
        max_tokens: Maximum tokens for the repo map
        include_patterns: File patterns to include
        exclude_patterns: File patterns to exclude  
        verbose: Enable verbose output
        
    Returns:
        str: Generated repository map
    """
    return get_repo_map(
        repo_path=repo_path,
        max_tokens=max_tokens,
        include_patterns=include_patterns,
        exclude_patterns=exclude_patterns,
        verbose=verbose
    )
