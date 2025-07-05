import os
from pathlib import Path
from typing import Optional, Dict, Any, List
from datetime import datetime


def read_file_safe(file_path: Path) -> str:
    """
    安全地读取文件内容
    
    Args:
        file_path: 文件路径
        
    Returns:
        文件内容，如果文件不存在或为空则返回空字符串
    """
    try:
        if file_path.exists() and file_path.is_file():
            content = file_path.read_text(encoding='utf-8').strip()
            return content if content else ""
        return ""
    except Exception as e:
        print(f"警告: 无法读取文件 {file_path}: {e}")
        return ""


def append_to_file_safe(file_path: Path, content: str) -> bool:
    """
    安全地追加内容到文件
    
    Args:
        file_path: 文件路径
        content: 要追加的内容
        
    Returns:
        是否成功追加
    """
    try:
        # 确保父目录存在
        file_path.parent.mkdir(parents=True, exist_ok=True)
        
        # 追加内容
        with open(file_path, 'a', encoding='utf-8') as f:
            f.write(content + '\n')
        return True
    except Exception as e:
        print(f"错误: 无法写入文件 {file_path}: {e}")
        return False


def update_log_files(
    iteration_number: int,
    envgym_path: Optional[str] = None,
    verbose: bool = False
) -> Dict[str, Any]:
    """
    更新日志文件：将当前迭代的执行状态保存到 history.txt
    
    Args:
        iteration_number: 迭代次数
        envgym_path: envgym 目录路径，默认为当前目录下的 envgym
        verbose: 是否显示详细信息
        
    Returns:
        包含操作结果的字典
    """
    try:
        # 确定 envgym 目录路径
        if envgym_path is None:
            envgym_path = os.path.join(os.getcwd(), "envgym")
        
        envgym_dir = Path(envgym_path)
        
        # 检查 envgym 目录是否存在
        if not envgym_dir.exists():
            return {
                "success": False,
                "message": f"envgym 目录不存在: {envgym_dir}",
                "iteration": iteration_number,
                "files_processed": []
            }
        
        # 定义文件路径
        files_to_read = {
            "plan.txt": "PLAN",
            "next.txt": "NEXT", 
            "status.txt": "STATUS",
            "log.txt": "LOG",
            "envgym.dockerfile": "DOCKERFILE"
        }
        
        history_file = envgym_dir / "history.txt"
        
        # 获取当前时间戳
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # 开始写入历史记录
        processed_files = []
        
        # 写入迭代开始标记
        start_marker = f"=== Iteration {iteration_number} - [{timestamp}] ==="
        if not append_to_file_safe(history_file, start_marker):
            return {
                "success": False,
                "message": "无法写入历史文件",
                "iteration": iteration_number,
                "files_processed": []
            }
        
        if verbose:
            print(f"开始处理迭代 {iteration_number}")
        
        # 读取并追加各个文件的内容
        for filename, prefix in files_to_read.items():
            file_path = envgym_dir / filename
            content = read_file_safe(file_path)
            
            if content:  # 只处理非空文件
                # 分行显示：先写标题，再写内容
                if append_to_file_safe(history_file, f"{prefix}:"):
                    # 将内容按行分割并缩进
                    for line in content.split('\n'):
                        if line.strip():  # 跳过空行
                            append_to_file_safe(history_file, f"  {line}")
                    
                    processed_files.append(filename)
                    if verbose:
                        print(f"已处理 {filename}")
                else:
                    if verbose:
                        print(f"无法写入 {filename} 的内容")
            else:
                if verbose:
                    print(f"跳过空文件 {filename}")
        
        # 写入迭代结束标记
        end_marker = f"--- End of Iteration {iteration_number} ---"
        append_to_file_safe(history_file, end_marker)
        
        # 添加空行分隔
        append_to_file_safe(history_file, "")
        
        if verbose:
            print(f"迭代 {iteration_number} 处理完成")
        
        return {
            "success": True,
            "message": f"成功更新迭代 {iteration_number} 的日志文件",
            "iteration": iteration_number,
            "files_processed": processed_files,
            "history_file": str(history_file),
            "timestamp": timestamp
        }
        
    except Exception as e:
        return {
            "success": False,
            "message": f"更新日志文件时出错: {str(e)}",
            "iteration": iteration_number,
            "files_processed": [],
            "error": str(e)
        }


def analyze_log_files(
    envgym_path: Optional[str] = None,
    verbose: bool = False
) -> Dict[str, Any]:
    """
    分析日志文件：读取当前 Docker 执行结果并分析
    
    Args:
        envgym_path: envgym 目录路径，默认为当前目录下的 envgym
        verbose: 是否显示详细信息
        
    Returns:
        包含分析结果的字典
    """
    try:
        # 确定 envgym 目录路径
        if envgym_path is None:
            envgym_path = os.path.join(os.getcwd(), "envgym")
        
        envgym_dir = Path(envgym_path)
        
        # 检查 envgym 目录是否存在
        if not envgym_dir.exists():
            return {
                "success": False,
                "message": f"envgym 目录不存在: {envgym_dir}",
                "analysis": {}
            }
        
        log_file = envgym_dir / "log.txt"
        status_file = envgym_dir / "status.txt"
        next_file = envgym_dir / "next.txt"
        
        # 读取日志文件
        log_content = read_file_safe(log_file)
        
        if not log_content:
            return {
                "success": False,
                "message": "log.txt 文件为空或不存在",
                "analysis": {}
            }
        
        if verbose:
            print("开始分析日志文件...")
        
        # 分析日志内容
        analysis = {
            "total_lines": len(log_content.split('\n')),
            "has_errors": False,
            "has_warnings": False,
            "success_indicators": [],
            "error_indicators": [],
            "warning_indicators": []
        }
        
        # 检查常见的成功/失败指示器
        success_patterns = [
            "Successfully built",
            "Successfully tagged",
            "BUILD SUCCESSFUL",
            "build successful",
            "Tests passed",
            "All tests passed"
        ]
        
        error_patterns = [
            "ERROR",
            "Error",
            "error:",
            "FAILED",
            "Failed",
            "Exception",
            "BUILD FAILED",
            "build failed"
        ]
        
        warning_patterns = [
            "WARNING",
            "Warning",
            "warning:",
            "WARN",
            "deprecated"
        ]
        
        lines = log_content.split('\n')
        
        for line in lines:
            line_lower = line.lower()
            
            # 检查成功指示器
            for pattern in success_patterns:
                if pattern.lower() in line_lower:
                    analysis["success_indicators"].append(line.strip())
                    break
            
            # 检查错误指示器
            for pattern in error_patterns:
                if pattern.lower() in line_lower:
                    analysis["has_errors"] = True
                    analysis["error_indicators"].append(line.strip())
                    break
            
            # 检查警告指示器
            for pattern in warning_patterns:
                if pattern.lower() in line_lower:
                    analysis["has_warnings"] = True
                    analysis["warning_indicators"].append(line.strip())
                    break
        
        # 生成分析总结
        if analysis["success_indicators"] and not analysis["has_errors"]:
            overall_status = "SUCCESS"
        elif analysis["has_errors"]:
            overall_status = "FAILED"
        elif analysis["has_warnings"]:
            overall_status = "WARNING"
        else:
            overall_status = "UNKNOWN"
        
        analysis["overall_status"] = overall_status
        
        # 生成建议的下一步行动
        if overall_status == "SUCCESS":
            next_steps = "环境构建成功。可以继续下一步操作。"
        elif overall_status == "FAILED":
            next_steps = "环境构建失败。需要检查错误日志并修复 Dockerfile。"
        elif overall_status == "WARNING":
            next_steps = "环境构建有警告。建议检查警告信息并考虑优化。"
        else:
            next_steps = "无法确定构建状态。需要人工检查日志文件。"
        
        analysis["suggested_next_steps"] = next_steps
        
        # 更新状态文件
        status_content = f"分析结果: {overall_status}\n"
        status_content += f"成功指示器: {len(analysis['success_indicators'])}\n"
        status_content += f"错误指示器: {len(analysis['error_indicators'])}\n"
        status_content += f"警告指示器: {len(analysis['warning_indicators'])}\n"
        status_content += f"总行数: {analysis['total_lines']}\n"
        
        status_file.write_text(status_content, encoding='utf-8')
        
        # 更新下一步文件
        next_file.write_text(next_steps, encoding='utf-8')
        
        if verbose:
            print(f"日志分析完成，整体状态: {overall_status}")
            print(f"建议的下一步: {next_steps}")
        
        return {
            "success": True,
            "message": "日志文件分析完成",
            "analysis": analysis,
            "files_updated": [str(status_file), str(next_file)]
        }
        
    except Exception as e:
        return {
            "success": False,
            "message": f"分析日志文件时出错: {str(e)}",
            "analysis": {},
            "error": str(e)
        }


def batch_update_logs(
    start_iteration: int,
    end_iteration: int,
    envgym_path: Optional[str] = None,
    verbose: bool = False
) -> Dict[str, Any]:
    """
    批量更新多个迭代的日志文件
    
    Args:
        start_iteration: 开始迭代次数
        end_iteration: 结束迭代次数
        envgym_path: envgym 目录路径
        verbose: 是否显示详细信息
        
    Returns:
        包含批量操作结果的字典
    """
    results = []
    
    for iteration in range(start_iteration, end_iteration + 1):
        if verbose:
            print(f"处理迭代 {iteration}...")
        
        result = update_log_files(
            iteration_number=iteration,
            envgym_path=envgym_path,
            verbose=verbose
        )
        
        results.append(result)
        
        # 如果某个迭代失败了，询问是否继续
        if not result["success"] and verbose:
            print(f"迭代 {iteration} 处理失败: {result['message']}")
    
    successful_count = sum(1 for r in results if r["success"])
    
    return {
        "success": successful_count > 0,
        "message": f"批量处理完成: {successful_count}/{len(results)} 成功",
        "total_iterations": len(results),
        "successful_iterations": successful_count,
        "results": results
    }


def get_log_summary(
    envgym_path: Optional[str] = None,
    last_n_iterations: int = 3
) -> Dict[str, Any]:
    """
    获取日志摘要：读取最近几次迭代的摘要
    
    Args:
        envgym_path: envgym 目录路径
        last_n_iterations: 显示最近几次迭代
        
    Returns:
        包含日志摘要的字典
    """
    try:
        # 确定 envgym 目录路径
        if envgym_path is None:
            envgym_path = os.path.join(os.getcwd(), "envgym")
        
        envgym_dir = Path(envgym_path)
        history_file = envgym_dir / "history.txt"
        
        if not history_file.exists():
            return {
                "success": False,
                "message": "history.txt 文件不存在",
                "summary": {}
            }
        
        history_content = read_file_safe(history_file)
        
        if not history_content:
            return {
                "success": False,
                "message": "history.txt 文件为空",
                "summary": {}
            }
        
        # 分析历史记录
        lines = history_content.split('\n')
        iterations = []
        current_iteration = None
        
        for line in lines:
            if line.startswith("=== Iteration"):
                # 提取迭代信息
                parts = line.split()
                if len(parts) >= 3:
                    iteration_num = parts[2]
                    timestamp = line.split('[')[1].split(']')[0] if '[' in line else "未知时间"
                    current_iteration = {
                        "iteration": iteration_num,
                        "timestamp": timestamp,
                        "content": []
                    }
            elif line.startswith("--- End of Iteration"):
                if current_iteration:
                    iterations.append(current_iteration)
                    current_iteration = None
            elif current_iteration and line.strip():
                current_iteration["content"].append(line.strip())
        
        # 获取最近的 n 次迭代
        recent_iterations = iterations[-last_n_iterations:] if iterations else []
        
        summary = {
            "total_iterations": len(iterations),
            "recent_iterations": recent_iterations,
            "last_n_shown": len(recent_iterations)
        }
        
        return {
            "success": True,
            "message": f"成功获取日志摘要，显示最近 {len(recent_iterations)} 次迭代",
            "summary": summary
        }
        
    except Exception as e:
        return {
            "success": False,
            "message": f"获取日志摘要时出错: {str(e)}",
            "summary": {},
            "error": str(e)
        }


if __name__ == "__main__":
    # 测试功能
    print("测试日志更新功能...")
    
    # 测试更新日志文件
    result = update_log_files(iteration_number=1, verbose=True)
    print(f"更新结果: {result}")
    
    # 测试分析日志文件
    analysis_result = analyze_log_files(verbose=True)
    print(f"分析结果: {analysis_result}")
    
    # 测试获取日志摘要
    summary_result = get_log_summary()
    print(f"摘要结果: {summary_result}") 