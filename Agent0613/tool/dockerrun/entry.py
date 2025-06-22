"""
Docker executor entry point module.
This module provides interfaces for Docker build and run functionality.
"""

import sys
import os
from pathlib import Path

# Add project root directory to Python path
project_root = Path(__file__).resolve().parent.parent.parent.parent
sys.path.insert(0, str(project_root))

# Import our Docker execution tools
try:
    from .docker_runner import execute_dockerfile, print_execution_result, DockerRunner
except ImportError:
    from docker_runner import execute_dockerfile, print_execution_result, DockerRunner

# Re-export main functions for use by other modules
__all__ = ['execute_dockerfile', 'print_execution_result', 'DockerRunner', 'run_dockerfile_with_logs']

def run_dockerfile_with_logs(dockerfile_path=None, output_dir=None, verbose=True, cleanup=True):
    """
    Execute Dockerfile and record complete logs convenience function
    Defaults to using envgym/envgym.dockerfile and overwrites envgym/log.txt
    
    Args:
        dockerfile_path: Path to Dockerfile (default: 'envgym/envgym.dockerfile' relative to current working directory)
        output_dir: Output directory path (default: same as dockerfile directory to save log.txt there)
        verbose: Whether to show detailed output
        cleanup: Whether to cleanup images after completion
        
    Returns:
        dict: Execution result details
    """
    # Set default paths relative to current working directory
    if dockerfile_path is None:
        dockerfile_path = 'envgym/envgym.dockerfile'
    
    # Determine the working directory (parent of dockerfile directory)
    dockerfile_path_obj = Path(dockerfile_path)
    dockerfile_dir = dockerfile_path_obj.parent  # envgym directory
    
    # Calculate working directory properly
    if dockerfile_path_obj.is_absolute():
        working_dir = dockerfile_dir.parent
    else:
        # For relative paths like 'envgym/envgym.dockerfile'
        # Working directory should be current directory (where envgym folder is)
        working_dir = Path.cwd()
    
    # Set output directory to dockerfile directory if not specified
    if output_dir is None:
        output_dir = str(dockerfile_dir)
    
    # Verify paths exist relative to working directory
    dockerfile_full_path = working_dir / dockerfile_path if not dockerfile_path_obj.is_absolute() else dockerfile_path_obj
    output_full_path = working_dir / output_dir if not Path(output_dir).is_absolute() else Path(output_dir)
    
    if not dockerfile_full_path.exists():
        return {
            'success': False,
            'build_success': False,
            'run_success': False,
            'build_output': '',
            'build_error': f'Dockerfile not found: {dockerfile_full_path} (working dir: {working_dir})',
            'run_output': '',
            'run_error': '',
            'result_file': '',
            'image_name': ''
        }
    
    if not output_full_path.exists():
        return {
            'success': False,
            'build_success': False,
            'run_success': False,
            'build_output': '',
            'build_error': f'Output directory not found: {output_full_path} (working dir: {working_dir})',
            'run_output': '',
            'run_error': '',
            'result_file': '',
            'image_name': ''
        }
    
    if verbose:
        print(f"Working directory: {working_dir}")
        print(f"Using Dockerfile: {dockerfile_full_path}")
        print(f"Output directory: {output_full_path}")
        print(f"Will overwrite: {output_full_path}/log.txt")
    
    # Change to working directory for Docker execution
    original_cwd = Path.cwd()
    try:
        os.chdir(working_dir)
        # Use relative paths for Docker execution
        relative_dockerfile = dockerfile_full_path.relative_to(working_dir)
        relative_output = output_full_path.relative_to(working_dir)
        
        return execute_dockerfile(
            dockerfile_path=str(relative_dockerfile),
            output_dir=str(relative_output),
            cleanup=cleanup,
            verbose=verbose
        )
    finally:
        # Always restore original working directory
        os.chdir(original_cwd)

def execute_dockerfile_simple(dockerfile_path=None):
    """
    Simplified version of Dockerfile execution function
    Defaults to using envgym/envgym.dockerfile
    
    Args:
        dockerfile_path: Path to Dockerfile (default: 'envgym/envgym.dockerfile' relative to current working directory)
        
    Returns:
        str: Run output, returns error message if failed
    """
    result = run_dockerfile_with_logs(dockerfile_path=dockerfile_path, verbose=False)
    
    if result['success']:
        return result['run_output'] or "Execution successful, no output"
    else:
        error_msg = []
        if result['build_error']:
            error_msg.append(f"Build error: {result['build_error']}")
        if result['run_error']:
            error_msg.append(f"Runtime error: {result['run_error']}")
        return "\n".join(error_msg) if error_msg else "Execution failed, unknown error" 