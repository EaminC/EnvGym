#!/usr/bin/env python3
"""调试JSON解析问题的测试脚本"""

import json

# 模拟从OpenAI返回的可能有问题的JSON字符串
problematic_jsons = [
    # 包含未转义的换行符
    '{"userinput": "test input\nwith newline", "selected_agent": "rust_agent", "confidence": 0.8}',
    
    # 包含未转义的引号
    '{"userinput": "test input with "quotes"", "selected_agent": "rust_agent", "confidence": 0.8}',
    
    # 包含回车符
    '{"userinput": "test input\rwith carriage return", "selected_agent": "rust_agent", "confidence": 0.8}',
    
    # 模拟长依赖树数据（简化版）
    '{"userinput": "long text with ├── symbols and ^0.3.58 versions", "selected_agent": "rust_agent", "confidence": 0.8}',
]

def test_json_parsing():
    """测试各种可能导致JSON解析失败的情况"""
    for i, json_str in enumerate(problematic_jsons):
        print(f"\n测试 {i+1}: {json_str[:50]}...")
        try:
            result = json.loads(json_str)
            print(f"✅ 成功: {result}")
        except json.JSONDecodeError as e:
            print(f"❌ JSON解析错误: {e}")
            print(f"   错误位置: 第{e.lineno}行, 第{e.colno}列 (字符{e.pos})")

if __name__ == "__main__":
    test_json_parsing() 