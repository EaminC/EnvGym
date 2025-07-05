"""
Docker 执行器模块，用于构建和运行 Dockerfile。
此模块提供了执行 Dockerfile 并收集运行结果和日志的功能。
"""

import sys
import os
import subprocess
import json
import time
from pathlib import Path
from datetime import datetime
from typing import Dict, Optional, List, Tuple

# 添加项目根目录到 Python 路径
project_root = Path(__file__).resolve().parent.parent.parent.parent
sys.path.insert(0, str(project_root))

class DockerRunner:
    """Docker 运行器类，负责构建和运行 Docker 容器"""
    
    def __init__(self, output_dir: Optional[str] = None):
        """
        初始化 Docker 运行器
        
        Args:
            output_dir: 输出目录路径，默认为 dockerrun 目录
        """
        if output_dir is None:
            output_dir = Path(__file__).parent / "output"
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        
    def build_image(self, dockerfile_path: str, image_name: Optional[str] = None, build_context: Optional[str] = None) -> Tuple[bool, str, str]:
        """
        构建 Docker 镜像
        
        Args:
            dockerfile_path: Dockerfile 路径
            image_name: 镜像名称，默认自动生成
            build_context: 构建上下文路径，默认为当前工作目录
            
        Returns:
            tuple: (是否成功, 标准输出, 错误输出)
        """
        dockerfile_path = Path(dockerfile_path)
        if not dockerfile_path.exists():
            return False, "", f"Dockerfile 不存在: {dockerfile_path}"
        
        if image_name is None:
            timestamp = int(time.time())
            image_name = f"envgym_test_{timestamp}"
        
        # Use provided build context or default to current working directory
        if build_context is None:
            build_context = "."
        
        build_cmd = [
            "docker", "build", 
            "-t", image_name,
            "-f", str(dockerfile_path),
            str(build_context)
        ]
        
        try:
            result = subprocess.run(
                build_cmd,
                capture_output=True,
                text=True,
                timeout=1500  # 5分钟超时
            )
            
            success = result.returncode == 0
            return success, result.stdout, result.stderr
            
        except subprocess.TimeoutExpired:
            return False, "", "Docker build timeout (5 minutes)"
        except Exception as e:
            return False, "", f"Docker build exception: {str(e)}"
    
    def run_container(self, image_name: str, command: Optional[str] = None, 
                     timeout: int = 60) -> Tuple[bool, str, str]:
        """
        运行 Docker 容器
        
        Args:
            image_name: 镜像名称
            command: 要执行的命令，默认使用镜像的 CMD
            timeout: 运行超时时间（秒）
            
        Returns:
            tuple: (是否成功, 标准输出, 错误输出)
        """
        run_cmd = ["docker", "run", "--rm"]
        
        if command:
            run_cmd.extend([image_name, command])
        else:
            run_cmd.append(image_name)
        
        try:
            result = subprocess.run(
                run_cmd,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            
            success = result.returncode == 0
            return success, result.stdout, result.stderr
            
        except subprocess.TimeoutExpired:
            return False, "", f"Container runtime timeout ({timeout} seconds)"
        except Exception as e:
            return False, "", f"Container runtime exception: {str(e)}"
    
    def cleanup_image(self, image_name: str) -> bool:
        """
        清理 Docker 镜像
        
        Args:
            image_name: 要删除的镜像名称
            
        Returns:
            bool: 是否成功删除
        """
        try:
            result = subprocess.run(
                ["docker", "rmi", image_name],
                capture_output=True,
                text=True
            )
            return result.returncode == 0
        except Exception:
            return False
    
    def save_results(self, dockerfile_path: str, build_result: Tuple[bool, str, str], 
                    run_result: Tuple[bool, str, str], image_name: str) -> str:
        """
        保存执行结果到文件
        
        Args:
            dockerfile_path: Dockerfile 路径
            build_result: 构建结果
            run_result: 运行结果
            image_name: 镜像名称
            
        Returns:
            str: 结果文件路径
        """
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        dockerfile_name = Path(dockerfile_path).parent.name
        result_file = self.output_dir / f"docker_result_{dockerfile_name}_{timestamp}.json"
        
        result_data = {
            "timestamp": timestamp,
            "dockerfile_path": str(dockerfile_path),
            "image_name": image_name,
            "build": {
                "success": build_result[0],
                "stdout": build_result[1],
                "stderr": build_result[2]
            },
            "run": {
                "success": run_result[0],
                "stdout": run_result[1],
                "stderr": run_result[2]
            }
        }
        
        try:
            with open(result_file, 'w', encoding='utf-8') as f:
                json.dump(result_data, f, ensure_ascii=False, indent=2)
            
            # 同时保存日志到 envgym/log.txt (如果输出目录是envgym)
            if self.output_dir.name == "envgym" or str(self.output_dir).endswith("envgym"):
                log_file = self.output_dir / "log.txt"
                log_content = f"""=== Docker Execution Log - {timestamp} ===
Dockerfile: {dockerfile_path}
Image Name: {image_name}

=== Build Log ===
Build Status: {'Success' if build_result[0] else 'Failed'}
Build Output:
{build_result[1]}

Build Error:
{build_result[2]}

=== Runtime Log ===  
Runtime Status: {'Success' if run_result[0] else 'Failed'}
Runtime Output:
{run_result[1]}

Runtime Error:
{run_result[2]}

=== Execution End ===

"""
                try:
                    with open(log_file, 'w', encoding='utf-8') as f:
                        f.write(log_content)
                    print(f"Log saved to: {log_file}")
                except Exception as log_e:
                    print(f"Failed to save log file: {log_e}")
            
            return str(result_file)
        except Exception as e:
            print(f"Failed to save result file: {e}")
            return ""


def execute_dockerfile(dockerfile_path: str, output_dir: Optional[str] = None, 
                      cleanup: bool = True, verbose: bool = False) -> Dict:
    """
    执行 Dockerfile 的主函数
    
    Args:
        dockerfile_path: Dockerfile 路径
        output_dir: 输出目录路径
        cleanup: 是否在完成后清理镜像
        verbose: 是否启用详细输出
        
    Returns:
        dict: 执行结果详情
    """
    runner = DockerRunner(output_dir)
    
    if verbose:
        print(f"Starting to process Dockerfile: {dockerfile_path}")
    
    # Build image
    image_name = f"envgym_test_{int(time.time())}"
    build_success, build_stdout, build_stderr = runner.build_image(dockerfile_path, image_name, ".")
    
    if verbose:
        print(f"Build result: {'Success' if build_success else 'Failed'}")
        if build_stderr and verbose:
            print(f"Build error: {build_stderr}")
    
    # Run container
    run_success, run_stdout, run_stderr = False, "", ""
    if build_success:
        run_success, run_stdout, run_stderr = runner.run_container(image_name)
        if verbose:
            print(f"Runtime result: {'Success' if run_success else 'Failed'}")
            if run_stdout:
                print(f"Runtime output: {run_stdout}")
            if run_stderr:
                print(f"Runtime error: {run_stderr}")
    
    # Save results
    result_file = runner.save_results(
        dockerfile_path, 
        (build_success, build_stdout, build_stderr),
        (run_success, run_stdout, run_stderr),
        image_name
    )
    
    # Cleanup image
    if cleanup and build_success:
        cleanup_success = runner.cleanup_image(image_name)
        if verbose:
            print(f"Image cleanup: {'Success' if cleanup_success else 'Failed'}")
    
    return {
        "success": build_success and run_success,
        "build_success": build_success,
        "run_success": run_success,
        "build_output": build_stdout,
        "build_error": build_stderr,
        "run_output": run_stdout,
        "run_error": run_stderr,
        "result_file": result_file,
        "image_name": image_name
    }


def print_execution_result(result: Dict) -> None:
    """
    Print execution result summary
    
    Args:
        result: Execution result dictionary
    """
    print("\n" + "="*50)
    print("Docker Execution Result")
    print("="*50)
    print(f"Overall Status: {'Success' if result['success'] else 'Failed'}")
    print(f"Build Status: {'Success' if result['build_success'] else 'Failed'}")
    print(f"Runtime Status: {'Success' if result['run_success'] else 'Failed'}")
    print(f"Image Name: {result['image_name']}")
    print(f"Result File: {result['result_file']}")
    
    if result['run_output']:
        print(f"\nRuntime Output:\n{result['run_output']}")
    
    if result['build_error'] or result['run_error']:
        print(f"\nError Information:")
        if result['build_error']:
            print(f"Build Error: {result['build_error']}")
        if result['run_error']:
            print(f"Runtime Error: {result['run_error']}")


# 重新导出主要函数
__all__ = ['execute_dockerfile', 'print_execution_result', 'DockerRunner'] 