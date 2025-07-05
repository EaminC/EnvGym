#!/usr/bin/env python3
"""
测试日志更新功能的脚本
"""

import os
import sys
from pathlib import Path

# 添加当前目录到 Python 路径
current_dir = Path(__file__).parent
sys.path.insert(0, str(current_dir))

from entry import (
    update_log_files,
    analyze_log_files,
    batch_update_logs,
    get_log_summary
)


def create_test_envgym():
    """创建测试用的 envgym 目录和文件"""
    print("创建测试环境...")
    
    # 创建 envgym 目录
    envgym_dir = Path("test_envgym")
    envgym_dir.mkdir(exist_ok=True)
    
    # 创建测试文件
    test_files = {
        "plan.txt": "这是一个测试计划\n包含多行内容\n用于测试日志更新功能",
        "next.txt": "下一步需要执行的操作\n1. 构建 Docker 镜像\n2. 运行测试",
        "status.txt": "当前状态: 准备中\n进度: 50%",
        "log.txt": "Docker 构建日志\nSuccessfully built abc123\nSuccessfully tagged test:latest\nBUILD SUCCESSFUL",
        "envgym.dockerfile": "FROM python:3.9\nWORKDIR /app\nCOPY . .\nRUN pip install -r requirements.txt\nCMD [\"python\", \"main.py\"]",
        "history.txt": ""  # 空的历史文件
    }
    
    for filename, content in test_files.items():
        file_path = envgym_dir / filename
        file_path.write_text(content, encoding='utf-8')
    
    print(f"测试环境创建完成: {envgym_dir}")
    return str(envgym_dir)


def test_update_log_files():
    """测试更新日志文件功能"""
    print("\n" + "="*50)
    print("测试更新日志文件功能")
    print("="*50)
    
    # 创建测试环境
    envgym_path = create_test_envgym()
    
    # 测试单次更新
    print("\n1. 测试单次更新...")
    result = update_log_files(
        iteration_number=1,
        envgym_path=envgym_path,
        verbose=True
    )
    
    print(f"更新结果: {result}")
    
    # 检查 history.txt 文件
    history_file = Path(envgym_path) / "history.txt"
    if history_file.exists():
        print(f"\n生成的历史文件内容:")
        print("-" * 40)
        print(history_file.read_text(encoding='utf-8'))
        print("-" * 40)
    
    return result["success"]


def test_analyze_log_files():
    """测试分析日志文件功能"""
    print("\n" + "="*50)
    print("测试分析日志文件功能")
    print("="*50)
    
    # 使用之前创建的测试环境
    envgym_path = "test_envgym"
    
    result = analyze_log_files(
        envgym_path=envgym_path,
        verbose=True
    )
    
    print(f"\n分析结果: {result}")
    
    # 检查更新的状态文件
    status_file = Path(envgym_path) / "status.txt"
    next_file = Path(envgym_path) / "next.txt"
    
    if status_file.exists():
        print(f"\n更新的状态文件内容:")
        print("-" * 40)
        print(status_file.read_text(encoding='utf-8'))
        print("-" * 40)
    
    if next_file.exists():
        print(f"\n更新的下一步文件内容:")
        print("-" * 40)
        print(next_file.read_text(encoding='utf-8'))
        print("-" * 40)
    
    return result["success"]


def test_batch_update():
    """测试批量更新功能"""
    print("\n" + "="*50)
    print("测试批量更新功能")
    print("="*50)
    
    # 使用之前创建的测试环境
    envgym_path = "test_envgym"
    
    # 批量更新迭代 2-4
    result = batch_update_logs(
        start_iteration=2,
        end_iteration=4,
        envgym_path=envgym_path,
        verbose=True
    )
    
    print(f"\n批量更新结果: {result}")
    
    # 检查 history.txt 文件
    history_file = Path(envgym_path) / "history.txt"
    if history_file.exists():
        print(f"\n批量更新后的历史文件内容:")
        print("-" * 40)
        print(history_file.read_text(encoding='utf-8'))
        print("-" * 40)
    
    return result["success"]


def test_get_log_summary():
    """测试获取日志摘要功能"""
    print("\n" + "="*50)
    print("测试获取日志摘要功能")
    print("="*50)
    
    # 使用之前创建的测试环境
    envgym_path = "test_envgym"
    
    result = get_log_summary(
        envgym_path=envgym_path,
        last_n_iterations=3
    )
    
    print(f"\n摘要结果: {result}")
    
    if result["success"]:
        summary = result["summary"]
        print(f"\n总迭代次数: {summary['total_iterations']}")
        print(f"显示最近 {summary['last_n_shown']} 次迭代:")
        
        for i, iteration in enumerate(summary["recent_iterations"]):
            print(f"\n迭代 {iteration['iteration']} [{iteration['timestamp']}]:")
            for line in iteration["content"]:
                print(f"  {line}")
    
    return result["success"]


def cleanup_test_files():
    """清理测试文件"""
    print("\n" + "="*50)
    print("清理测试文件")
    print("="*50)
    
    import shutil
    
    test_dir = Path("test_envgym")
    if test_dir.exists():
        shutil.rmtree(test_dir)
        print(f"已删除测试目录: {test_dir}")
    else:
        print("测试目录不存在")


def main():
    """主测试函数"""
    print("开始测试日志更新功能...")
    
    test_results = []
    
    # 运行所有测试
    test_results.append(("更新日志文件", test_update_log_files()))
    test_results.append(("分析日志文件", test_analyze_log_files()))
    test_results.append(("批量更新", test_batch_update()))
    test_results.append(("获取日志摘要", test_get_log_summary()))
    
    # 显示测试结果
    print("\n" + "="*60)
    print("测试结果汇总")
    print("="*60)
    
    for test_name, success in test_results:
        status = "✓ 通过" if success else "✗ 失败"
        print(f"{test_name:<20} {status}")
    
    # 清理测试文件
    cleanup_test_files()
    
    # 计算总体结果
    total_passed = sum(1 for _, success in test_results if success)
    total_tests = len(test_results)
    
    print(f"\n总体结果: {total_passed}/{total_tests} 测试通过")
    
    if total_passed == total_tests:
        print("🎉 所有测试都通过了！")
        return 0
    else:
        print("❌ 部分测试失败")
        return 1


if __name__ == "__main__":
    sys.exit(main()) 