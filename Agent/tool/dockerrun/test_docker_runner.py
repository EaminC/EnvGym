#!/usr/bin/env python3
"""
Docker 执行器测试脚本
演示如何使用 Docker 执行器来构建和运行 Dockerfile
"""

import sys
from pathlib import Path

# 添加当前目录到路径
current_dir = Path(__file__).parent
sys.path.insert(0, str(current_dir))

from entry import run_dockerfile_with_logs, execute_dockerfile_simple, print_execution_result

def test_with_sample_dockerfile():
    """使用示例 Dockerfile 进行测试"""
    
    # 使用项目中已有的测试 Dockerfile
    dockerfile_path = Path(__file__).parent.parent.parent.parent / "data" / "test_repo1" / "Dockerfile"
    
    print("=== Docker 执行器测试 ===")
    print(f"测试 Dockerfile: {dockerfile_path}")
    
    if not dockerfile_path.exists():
        print(f"错误: Dockerfile 不存在于 {dockerfile_path}")
        return False
    
    print("\n1. 使用详细模式执行...")
    result = run_dockerfile_with_logs(
        dockerfile_path=str(dockerfile_path),
        verbose=True,
        cleanup=True
    )
    
    print_execution_result(result)
    
    print("\n" + "="*50)
    print("2. 使用简化模式执行...")
    simple_output = execute_dockerfile_simple(str(dockerfile_path))
    print(f"简化输出: {simple_output}")
    
    return result['success']

def main():
    """主函数"""
    print("Docker 执行器测试开始...")
    
    try:
        success = test_with_sample_dockerfile()
        if success:
            print("\n✅ 测试成功完成!")
        else:
            print("\n❌ 测试失败!")
            return 1
    except Exception as e:
        print(f"\n❌ 测试过程中发生异常: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main()) 