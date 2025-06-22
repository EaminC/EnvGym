import os
import sys
import subprocess
from pathlib import Path

# 添加 codex 到 sys.path
codex_path = os.path.join(os.path.dirname(__file__), '..', 'Agent0613', 'tool', 'codex')
sys.path.insert(0, codex_path)

def run_codex_command(query, approval_mode='full-auto', verbose=False):
    """
    运行 codex 命令并返回结果
    
    Args:
        query: 要执行的查询字符串
        approval_mode: 审批模式，可选值：'full-auto', 'semi-auto', 'manual'
        verbose: 是否显示详细信息
    
    Returns:
        str: 命令执行结果
    """
    try:
        # 构建 codex cli 路径
        cli_path = os.path.join(codex_path, 'codex-cli', 'dist', 'cli.js')
        
        if not os.path.exists(cli_path):
            raise FileNotFoundError(f"找不到 codex cli: {cli_path}")
        
        # 构建命令
        cmd = [
            'node',
            cli_path,
            '-q',  # quiet mode
            f'--approval-mode={approval_mode}',
            query
        ]
        
        if verbose:
            print(f"执行命令: {' '.join(cmd)}")
        
        # 执行命令
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True
        )
        
        return result.stdout.strip()
        
    except subprocess.CalledProcessError as e:
        error_msg = f"命令执行失败: {e.stderr}"
        if verbose:
            print(error_msg)
        return error_msg
    except Exception as e:
        error_msg = f"发生错误: {str(e)}"
        if verbose:
            print(error_msg)
        return error_msg

def test_codex_basic():
    """测试基本的 codex 功能"""
    print("测试创建文件...")
    result = run_codex_command("create a hello.txt file with content 'Hello, World!'", verbose=True)
    print(f"结果: {result}")
    
    print("\n测试读取文件...")
    result = run_codex_command("read the content of hello.txt", verbose=True)
    print(f"结果: {result}")

def test_codex_with_different_modes():
    """测试不同的审批模式"""
    modes = ['full-auto', 'semi-auto', 'manual']
    for mode in modes:
        print(f"\n测试 {mode} 模式...")
        result = run_codex_command(
            "list files in current directory",
            approval_mode=mode,
            verbose=True
        )
        print(f"结果: {result}")

if __name__ == "__main__":
    print("=== 运行基本测试 ===")
    test_codex_basic()
    
    print("\n=== 运行不同模式测试 ===")
    test_codex_with_different_modes()
    
    print("\n所有测试完成")

# 使用示例：
"""
使用示例：

# 基本使用
from test_codex import run_codex_command

# 执行简单命令
result = run_codex_command("create a new file test.txt")
print(result)

# 使用不同的审批模式
result = run_codex_command("list all python files", approval_mode='semi-auto')
print(result)

# 启用详细输出
result = run_codex_command("show current directory", verbose=True)
print(result)
""" 