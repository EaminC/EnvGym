#!/usr/bin/env python3
"""
测试文件扫描工具演示脚本

使用方法:
    python test_scanning_demo.py          # 普通模式
    python test_scanning_demo.py -v       # 详细模式
"""

import sys
import os
from pathlib import Path

# Add current directory to path for imports
current_dir = Path(__file__).parent
sys.path.insert(0, str(current_dir))

from tool.test_scanning.entry import TestScanningTool


def main():
    """主函数"""
    import argparse
    
    parser = argparse.ArgumentParser(description="测试文件扫描工具演示")
    parser.add_argument("-v", "--verbose", action="store_true", 
                       help="启用详细输出模式")
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("测试文件扫描工具演示")
    print("=" * 60)
    
    try:
        # 创建并运行测试扫描工具
        tool = TestScanningTool(verbose=args.verbose)
        tool.run()
        
        print("\n" + "=" * 60)
        print("扫描完成！")
        
        # 检查输出文件
        output_file = "envgym/test.json"
        if os.path.exists(output_file):
            print(f"结果已保存到: {output_file}")
            
            # 读取并显示结果摘要
            import json
            with open(output_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            print(f"\n扫描摘要:")
            print(f"- 总文件数: {data.get('total_files', 0)}")
            print(f"- 扫描时间: {data.get('scan_timestamp', 'Unknown')}")
            
            categories = data.get('categories', {})
            if categories:
                print("\n按类型分类:")
                for category, files in categories.items():
                    category_names = {
                        'unit_tests': '单元测试',
                        'integration_tests': '集成测试',
                        'examples': '示例文件',
                        'benchmarks': '基准测试',
                        'demos': '演示文件',
                        'other_tests': '其他测试'
                    }
                    chinese_name = category_names.get(category, category)
                    print(f"  - {chinese_name}: {len(files)} 个文件")
        else:
            print(f"警告: 输出文件 {output_file} 不存在")
            
    except Exception as e:
        print(f"错误: {e}")
        if args.verbose:
            import traceback
            traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main() 