"""
History manager entry point module.
This module provides interfaces for managing execution history.
"""

import os
from pathlib import Path
from datetime import datetime

def auto_save_to_history(iteration_number: int, envgym_path: str = None) -> str:
    """
    自动保存当前执行状态到 history.txt
    读取 envgym 目录下的 plan.txt, next.txt, status.txt, log.txt 文件内容
    并追加到 history.txt 中，带有适当的格式和时间戳
    
    Args:
        iteration_number: 迭代编号
        envgym_path: envgym 目录路径，默认为当前目录下的 envgym
        
    Returns:
        str: 执行结果消息
    """
    # 设置 envgym 目录路径
    if envgym_path is None:
        envgym_dir = Path("envgym")
    else:
        envgym_dir = Path(envgym_path)
    
    history_file = envgym_dir / "history.txt"
    
    # 创建时间戳
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # 要读取的文件列表
    files_to_read = ["plan.txt", "next.txt", "status.txt", "log.txt"]
    
    # 准备要追加的内容
    content_to_append = []
    content_to_append.append(f"=== Iteration {iteration_number} - {timestamp} ===")
    
    # 统计处理的文件
    processed_files = []
    errors = []
    
    # 读取每个文件的内容
    for filename in files_to_read:
        file_path = envgym_dir / filename
        
        if file_path.exists():
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    file_content = f.read().strip()
                
                if file_content:  # 只有文件有内容时才添加
                    processed_files.append(filename)
                    
                    # 根据文件类型添加不同的前缀
                    if filename == "plan.txt":
                        # plan.txt 每行添加 PLAN: 前缀
                        lines = file_content.split('\n')
                        for line in lines:
                            if line.strip():  # 跳过空行
                                content_to_append.append(f"PLAN: {line}")
                    elif filename == "next.txt":
                        # next.txt 每行添加 NEXT: 前缀
                        lines = file_content.split('\n')
                        for line in lines:
                            if line.strip():  # 跳过空行
                                content_to_append.append(f"NEXT: {line}")
                    elif filename == "status.txt":
                        # status.txt 每行添加 STATUS: 前缀
                        lines = file_content.split('\n')
                        for line in lines:
                            if line.strip():  # 跳过空行
                                content_to_append.append(f"STATUS: {line}")
                    elif filename == "log.txt":
                        # log.txt 内容太长，只保存摘要或最后几行
                        lines = file_content.split('\n')
                        # 只保存最后 10 行非空行作为摘要
                        non_empty_lines = [line for line in lines if line.strip()]
                        last_lines = non_empty_lines[-10:] if len(non_empty_lines) > 10 else non_empty_lines
                        
                        if last_lines:
                            content_to_append.append("LOG: === Docker Execution Summary (Last 10 lines) ===")
                            for line in last_lines:
                                content_to_append.append(f"LOG: {line}")
                else:
                    # 文件存在但为空
                    content_to_append.append(f"INFO: {filename} is empty")
                        
            except Exception as e:
                error_msg = f"Failed to read {filename}: {str(e)}"
                errors.append(error_msg)
                content_to_append.append(f"ERROR: {error_msg}")
        else:
            # 如果文件不存在，记录这个信息
            content_to_append.append(f"INFO: {filename} not found")
    
    # 追加内容到 history.txt
    try:
        # 确保 envgym 目录存在
        envgym_dir.mkdir(exist_ok=True)
        
        # 追加到 history.txt
        with open(history_file, 'a', encoding='utf-8') as f:
            f.write('\n'.join(content_to_append) + '\n')
        
        # 构建成功消息
        result_msg = f"✅ Successfully saved iteration {iteration_number} status to history.txt"
        if processed_files:
            result_msg += f"\n📁 Processed files: {', '.join(processed_files)}"
        if errors:
            result_msg += f"\n⚠️ Errors encountered: {'; '.join(errors)}"
        
        result_msg += f"\n📍 History file location: {history_file.absolute()}"
        
        return result_msg
        
    except Exception as e:
        error_msg = f"❌ Failed to save to history.txt: {str(e)}"
        return error_msg

def read_history_summary(envgym_path: str = None, last_n_iterations: int = 3) -> str:
    """
    读取历史记录摘要
    
    Args:
        envgym_path: envgym 目录路径，默认为当前目录下的 envgym
        last_n_iterations: 显示最近几次迭代，默认为 3
        
    Returns:
        str: 历史记录摘要
    """
    # 设置 envgym 目录路径
    if envgym_path is None:
        envgym_dir = Path("envgym")
    else:
        envgym_dir = Path(envgym_path)
    
    history_file = envgym_dir / "history.txt"
    
    if not history_file.exists():
        return "❌ History file not found: history.txt"
    
    try:
        with open(history_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 按迭代分割内容
        iterations = content.split('=== Iteration ')
        
        if len(iterations) <= 1:
            return "📝 History file exists but no iterations found"
        
        # 取最后 n 次迭代（跳过第一个空元素）
        recent_iterations = iterations[-last_n_iterations:] if len(iterations) > last_n_iterations else iterations[1:]
        
        summary = []
        summary.append(f"📚 History Summary (Last {len(recent_iterations)} iterations)")
        summary.append("=" * 60)
        
        for i, iteration_content in enumerate(recent_iterations):
            if iteration_content.strip():
                lines = iteration_content.split('\n')
                iteration_header = lines[0] if lines else "Unknown iteration"
                summary.append(f"\n🔄 Iteration {iteration_header}")
                
                # 统计各类信息
                plan_count = len([l for l in lines if l.startswith('PLAN:')])
                next_count = len([l for l in lines if l.startswith('NEXT:')])
                status_count = len([l for l in lines if l.startswith('STATUS:')])
                log_count = len([l for l in lines if l.startswith('LOG:')])
                
                summary.append(f"   📋 Plan entries: {plan_count}")
                summary.append(f"   ⏭️ Next steps: {next_count}")
                summary.append(f"   📊 Status updates: {status_count}")
                summary.append(f"   📜 Log entries: {log_count}")
        
        return "\n".join(summary)
        
    except Exception as e:
        return f"❌ Error reading history file: {str(e)}" 