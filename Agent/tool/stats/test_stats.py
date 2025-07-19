#!/usr/bin/env python3
"""
测试统计工具的功能
"""

import sys
import os
from pathlib import Path

# 添加父目录到路径
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from stats.entry import StatsTool

def test_stats_tool():
    """测试统计工具的基本功能"""
    print("=== 测试统计工具 ===")
    
    # 创建统计工具实例
    tool = StatsTool(verbose=True)
    
    print("\n1. 测试API统计获取...")
    stats = tool.get_api_stats()
    if stats:
        print("✓ 成功获取API统计")
        print(f"统计数据: {stats}")
    else:
        print("✗ 无法获取API统计")
    
    print("\n2. 测试会话开始记录...")
    tool.record_session_start()
    
    print("\n3. 测试会话结束记录...")
    tool.record_session_end()
    
    print("\n4. 检查生成的统计文件...")
    if os.path.exists("envgym/stat.json"):
        print("✓ 统计文件已生成")
        with open("envgym/stat.json", 'r', encoding='utf-8') as f:
            import json
            data = json.load(f)
            print(f"文件内容: {json.dumps(data, indent=2, ensure_ascii=False)}")
    else:
        print("✗ 统计文件未生成")

if __name__ == "__main__":
    test_stats_tool() 