"""
本地兼容性Agent使用示例
演示如何使用LocalCompatibilityAgent进行软件包兼容性分析
"""

import asyncio
from local_compatibility_agent import create_local_compatibility_agent, CompatibilityRequest, SupportedLanguage


async def example_usage():
    """演示本地兼容性Agent的使用方法"""
    
    # 创建agent实例
    agent = create_local_compatibility_agent(verbose=True)
    
    print("🌟 本地软件包兼容性分析Agent演示")
    print("=" * 60)
    
    # 示例1: 通过自然语言处理请求
    print("\n📝 示例1: 自然语言请求处理")
    natural_requests = [
        "检查 pandas 和 numpy 的兼容性",
        "获取 pandas==1.1.1 的依赖树",
        "查看 requests 的版本信息",
        "serde 版本信息",  # Rust包
        "github.com/gin-gonic/gin 依赖树",  # Go包
    ]
    
    for request in natural_requests:
        print(f"\n🔍 处理请求: '{request}'")
        result = await agent.process_request(request)
        
        print(f"✅ 成功: {result.success}")
        print(f"🔤 语言: {result.language}")
        print(f"⚡ 操作: {result.operation}")
        
        if result.success:
            print("📋 结果:")
            print(result.result)
        else:
            print(f"❌ 错误: {result.error}")
        
        print("-" * 40)
    
    print("\n" + "=" * 60)
    
    # 示例2: 直接使用Agent方法
    print("\n📝 示例2: 直接调用Agent方法")
    
    # Python包兼容性检查
    python_request = CompatibilityRequest(
        language=SupportedLanguage.PYTHON,
        package1="pandas",
        package2="numpy",
        operation="check_compatibility"
    )
    
    print("\n🐍 Python包兼容性检查:")
    result = await agent.check_compatibility(python_request)
    if result.success:
        print(result.result)
    else:
        print(f"错误: {result.error}")
    
    # Rust包依赖树
    rust_request = CompatibilityRequest(
        language=SupportedLanguage.RUST,
        package1="serde==1.0.140",
        operation="get_dependency_tree"
    )
    
    print("\n🦀 Rust包依赖树:")
    result = await agent.get_dependency_tree(rust_request)
    if result.success:
        print(result.result)
    else:
        print(f"错误: {result.error}")
    
    print("\n" + "=" * 60)
    print("✨ 演示完成!")


async def interactive_mode():
    """交互式模式，允许用户输入请求"""
    agent = create_local_compatibility_agent(verbose=True)
    
    print("\n🎯 进入交互模式")
    print("支持的命令示例:")
    print("  - 检查 pandas numpy 兼容性")
    print("  - 获取 requests 版本信息")
    print("  - pandas==1.1.1 依赖树")
    print("  - 输入 'quit' 或 'exit' 退出")
    print("-" * 50)
    
    while True:
        try:
            user_input = input("\n💬 请输入您的请求: ").strip()
            
            if user_input.lower() in ['quit', 'exit', '退出']:
                print("👋 再见!")
                break
            
            if not user_input:
                continue
            
            print(f"🔄 正在处理: '{user_input}'")
            result = await agent.process_request(user_input)
            
            print(f"\n📊 处理结果:")
            print(f"成功: {'✅' if result.success else '❌'}")
            print(f"语言: {result.language}")
            print(f"操作: {result.operation}")
            
            if result.success:
                print(f"\n📋 输出:\n{result.result}")
            else:
                print(f"\n❌ 错误: {result.error}")
            
            print("-" * 50)
            
        except KeyboardInterrupt:
            print("\n\n👋 程序被用户中断，再见!")
            break
        except Exception as e:
            print(f"❌ 发生错误: {e}")


def print_agent_info():
    """打印Agent信息"""
    agent = create_local_compatibility_agent()
    
    print("🤖 本地软件包兼容性分析Agent")
    print("=" * 50)
    print(f"Agent名称: {agent.name}")
    print(f"支持的语言: {', '.join(agent.get_supported_languages())}")
    print("\n支持的操作:")
    for op in agent.get_supported_operations():
        print(f"  • {op}")
    print("=" * 50)


async def main():
    """主函数"""
    print("🚀 本地兼容性Agent示例程序")
    
    # 显示Agent信息
    print_agent_info()
    
    # 选择运行模式
    print("\n请选择运行模式:")
    print("1. 运行示例演示")
    print("2. 进入交互模式")
    
    try:
        choice = input("请输入选择 (1/2): ").strip()
        
        if choice == "1":
            await example_usage()
        elif choice == "2":
            await interactive_mode()
        else:
            print("❌ 无效选择，运行默认演示")
            await example_usage()
            
    except KeyboardInterrupt:
        print("\n👋 程序被用户中断，再见!")
    except Exception as e:
        print(f"❌ 程序运行出错: {e}")


if __name__ == "__main__":
    asyncio.run(main()) 