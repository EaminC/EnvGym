#!/usr/bin/env python3
"""
快速测试修复后的格式
"""

import os
import sys
from pathlib import Path

# 添加当前目录到 Python 路径
current_dir = Path(__file__).parent
sys.path.insert(0, str(current_dir))

from entry import update_log_files


def create_test_files():
    """创建测试文件"""
    test_dir = Path("format_test")
    test_dir.mkdir(exist_ok=True)
    
    # 创建测试文件
    test_files = {
        "plan.txt": "第一行计划\n第二行计划\n第三行计划",
        "next.txt": "下一步操作1\n下一步操作2",
        "status.txt": "状态信息\n进度: 80%\n剩余时间: 5分钟",
        "log.txt": "Docker 构建开始\nSuccessfully built abc123\nSuccessfully tagged test:latest\nBUILD SUCCESSFUL",
        "envgym.dockerfile": "FROM python:3.9\nWORKDIR /app\nCOPY . .\nRUN pip install -r requirements.txt\nCMD [\"python\", \"main.py\"]",
        "history.txt": ""
    }
    
    for filename, content in test_files.items():
        (test_dir / filename).write_text(content, encoding='utf-8')
    
    return str(test_dir)


def main():
    print("🧪 测试修复后的格式...")
    
    # 创建测试文件
    test_dir = create_test_files()
    print(f"✅ 创建测试目录: {test_dir}")
    
    # 更新日志文件
    result = update_log_files(
        iteration_number=1,
        envgym_path=test_dir,
        verbose=True
    )
    
    print(f"✅ 更新结果: {result['success']}")
    
    # 显示生成的 history.txt 内容
    history_file = Path(test_dir) / "history.txt"
    if history_file.exists():
        print("\n📄 生成的 history.txt 内容:")
        print("=" * 60)
        content = history_file.read_text(encoding='utf-8')
        print(content)
        print("=" * 60)
    
    # 清理测试文件
    import shutil
    shutil.rmtree(test_dir)
    print(f"🧹 已清理测试目录: {test_dir}")


if __name__ == "__main__":
    main() 