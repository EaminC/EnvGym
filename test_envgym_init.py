#!/usr/bin/env python3
"""
测试envgym初始化功能的脚本
"""

import os
import sys
import tempfile
import shutil
from pathlib import Path

# 添加Agent0613目录到sys.path以便import agent
current_dir = Path(__file__).resolve().parent
agent_dir = current_dir / "Agent0613"
sys.path.insert(0, str(agent_dir))

# 导入agent模块
try:
    # 直接导入agent.py文件
    import importlib.util
    spec = importlib.util.spec_from_file_location("agent", agent_dir / "agent.py")
    agent_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(agent_module)
    initialize_envgym = agent_module.initialize_envgym
    
    from tool.initial.entry import create_envgym_directory, verify_envgym_directory
    print("✅ 成功导入agent模块和相关函数")
except ImportError as e:
    print(f"❌ 导入错误: {e}")
    sys.exit(1)


def test_in_current_directory():
    """在当前目录测试初始化功能"""
    print("\n" + "="*50)
    print("测试1: 在当前目录初始化envgym")
    print("="*50)
    
    # 如果当前目录已经有envgym，先删除
    current_envgym = Path("./envgym")
    if current_envgym.exists():
        shutil.rmtree(current_envgym)
        print("🗑️  清理了已存在的envgym目录")
    
    # 使用agent.py中的便利函数
    result = initialize_envgym()
    
    return result


def test_in_specific_directory():
    """在指定目录测试初始化功能"""
    print("\n" + "="*50)
    print("测试2: 在指定目录初始化envgym")
    print("="*50)
    
    # 创建临时目录
    with tempfile.TemporaryDirectory() as temp_dir:
        print(f"📁 临时目录: {temp_dir}")
        
        # 直接调用底层函数
        result = create_envgym_directory(temp_dir)
        
        if result["success"]:
            print(f"✅ {result['message']}")
            print(f"📁 envgym目录: {result['envgym_directory']}")
            print("📄 创建的文件:")
            for file_path in result["created_files"]:
                print(f"   - {file_path}")
            
            # 验证结果
            verify_result = verify_envgym_directory(temp_dir)
            if verify_result["success"]:
                print("✅ 验证成功：所有文件都已正确创建")
            else:
                print(f"⚠️  验证警告: {verify_result['message']}")
        else:
            print(f"❌ {result['message']}")
            if "error" in result:
                print(f"错误详情: {result['error']}")
    
    return result


def test_verification_function():
    """测试验证函数"""
    print("\n" + "="*50)
    print("测试3: 验证函数测试")
    print("="*50)
    
    # 测试在不存在envgym的目录中验证
    with tempfile.TemporaryDirectory() as temp_dir:
        print(f"📁 测试目录: {temp_dir}")
        
        # 先验证不存在的情况
        verify_result = verify_envgym_directory(temp_dir)
        print(f"📋 验证不存在的envgym: {verify_result['message']}")
        
        # 创建后再验证
        create_result = create_envgym_directory(temp_dir)
        if create_result["success"]:
            verify_result = verify_envgym_directory(temp_dir)
            print(f"📋 验证已创建的envgym: {verify_result['message']}")
            
            # 显示文件状态
            print("📄 文件状态详情:")
            for filename, status in verify_result["files_status"].items():
                print(f"   - {filename}: {'✅' if status['exists'] else '❌'}")


def main():
    """主函数"""
    print("🚀 开始测试envgym初始化功能")
    print("当前工作目录:", os.getcwd())
    
    try:
        # 测试1：在当前目录
        test_in_current_directory()
        
        # 测试2：在指定目录
        test_in_specific_directory()
        
        # 测试3：验证函数
        test_verification_function()
        
        print("\n" + "="*50)
        print("🎉 所有测试完成!")
        print("="*50)
        
    except Exception as e:
        print(f"\n❌ 测试过程中发生错误: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main() 