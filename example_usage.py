#!/usr/bin/env python3
"""
envgym初始化功能使用示例
可以在任意目录中运行此脚本来初始化envgym环境
"""

import os
import sys
from pathlib import Path

def setup_agent_path():
    """设置agent.py的导入路径"""
    # 这里需要根据实际情况修改agent.py的路径
    # 假设Agent0613目录与当前脚本在同一目录下
    current_dir = Path(__file__).resolve().parent
    agent_dir = current_dir / "Agent0613"
    
    # 如果Agent0613不在当前目录，请修改下面的路径
    # agent_dir = Path("path/to/your/Agent0613")
    
    if not agent_dir.exists():
        print(f"❌ 错误：找不到Agent0613目录: {agent_dir}")
        print("请修改script中的agent_dir路径指向正确的Agent0613目录")
        return None
    
    sys.path.insert(0, str(agent_dir))
    return agent_dir

def import_agent_functions(agent_dir):
    """导入agent.py中的函数"""
    try:
        # 导入agent.py文件
        import importlib.util
        spec = importlib.util.spec_from_file_location("agent", agent_dir / "agent.py")
        agent_module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(agent_module)
        
        # 导入tool函数
        from tool.initial.entry import create_envgym_directory, verify_envgym_directory
        
        return agent_module.initialize_envgym, create_envgym_directory, verify_envgym_directory
    except ImportError as e:
        print(f"❌ 导入错误: {e}")
        return None, None, None

def main():
    """主函数"""
    print("🚀 envgym初始化示例")
    print(f"当前工作目录: {os.getcwd()}")
    
    # 设置导入路径
    agent_dir = setup_agent_path()
    if agent_dir is None:
        return
    
    # 导入函数
    initialize_envgym, create_envgym_directory, verify_envgym_directory = import_agent_functions(agent_dir)
    if initialize_envgym is None:
        return
    
    # 选择使用方式
    print("\n选择使用方式:")
    print("1. 在当前目录初始化envgym")
    print("2. 在指定目录初始化envgym")
    print("3. 验证现有envgym目录")
    
    choice = input("请输入选择 (1-3): ").strip()
    
    if choice == "1":
        print("\n--- 在当前目录初始化envgym ---")
        result = initialize_envgym()
        
    elif choice == "2":
        target_dir = input("请输入目标目录路径: ").strip()
        if not target_dir:
            print("❌ 未提供目录路径")
            return
        
        print(f"\n--- 在目录 {target_dir} 初始化envgym ---")
        result = create_envgym_directory(target_dir)
        
        if result["success"]:
            print(f"✅ {result['message']}")
            print(f"📁 envgym目录: {result['envgym_directory']}")
            print("📄 创建的文件:")
            for file_path in result["created_files"]:
                print(f"   - {file_path}")
        else:
            print(f"❌ {result['message']}")
            if "error" in result:
                print(f"错误详情: {result['error']}")
    
    elif choice == "3":
        target_dir = input("请输入要验证的目录路径 (留空为当前目录): ").strip()
        if not target_dir:
            target_dir = None
        
        print(f"\n--- 验证envgym目录 ---")
        result = verify_envgym_directory(target_dir)
        
        if result["success"]:
            print(f"✅ {result['message']}")
            print(f"📁 envgym目录: {result['envgym_directory']}")
            print("📄 文件状态:")
            for filename, status in result["files_status"].items():
                print(f"   - {filename}: {'✅' if status['exists'] else '❌'}")
        else:
            print(f"❌ {result['message']}")
    
    else:
        print("❌ 无效的选择")

if __name__ == "__main__":
    main() 