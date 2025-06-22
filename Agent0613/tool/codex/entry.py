"""
Entry point for codex-based command execution functionality.
This module provides the interface to our custom codex CLI tool.
"""

import sys
import os
import subprocess
from pathlib import Path

# Set up codex path
codex_path = os.path.join(os.path.dirname(__file__), '..', 'Agent0613', 'tool', 'codex')
sys.path.insert(0, codex_path)

# Add project root directory to Python path
project_root = Path(__file__).resolve().parent.parent.parent.parent
tool_tests_path = project_root / "tool_tests"
sys.path.insert(0, str(tool_tests_path))

# Import our codex tool
try:
    from test_codex import run_codex_command as _run_codex_command
except ImportError:
    _run_codex_command = None

def run_codex_command(query, approval_mode='full-auto', verbose=False):
    """
    Run codex command and return result
    
    Args:
        query: Query string to execute
        approval_mode: Approval mode, options: 'full-auto', 'semi-auto', 'manual'
        verbose: Whether to show verbose information
    
    Returns:
        str: Command execution result
    """
    # If external run_codex_command is available, use it first
    if _run_codex_command:
        return _run_codex_command(query, approval_mode, verbose)
    
    # Otherwise use local implementation
    try:
        # Build codex cli path
        cli_path = os.path.join(codex_path, 'codex-cli', 'dist', 'cli.js')
        
        if not os.path.exists(cli_path):
            raise FileNotFoundError(f"Cannot find codex cli: {cli_path}")
        
        # Build command
        cmd = [
            'node',
            cli_path,
            '-q',  # quiet mode
            f'--approval-mode={approval_mode}',
            query
        ]
        
        if verbose:
            print(f"Executing command: {' '.join(cmd)}")
        
        # Execute command
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True
        )
        
        return result.stdout.strip()
        
    except subprocess.CalledProcessError as e:
        error_msg = f"Command execution failed: {e.stderr}"
        if verbose:
            print(error_msg)
        return error_msg
    except Exception as e:
        error_msg = f"Error occurred: {str(e)}"
        if verbose:
            print(error_msg)
        return error_msg

def execute_codex_query(query, approval_mode='full-auto', verbose=True):
    """
    Wrapper function for run_codex_command with more descriptive name.
    
    Args:
        query: The query string to execute
        approval_mode: Approval mode for command execution ('full-auto', 'semi-auto', 'manual')
        verbose: Enable verbose output
        
    Returns:
        str: Command execution result
    """
    return run_codex_command(
        query=query,
        approval_mode=approval_mode,
        verbose=verbose
    )

def simple_codex_agent(task_description):
    """
    Simplified codex agent interface function - designed for agent.py
    
    Args:
        task_description (str): Description of the task for the agent to perform
        
    Returns:
        str: Command execution result
    """
    try:
        # Use absolute path to ensure correct CLI tool location
        cli_path = "/zp_goku/scratch_lb/eamin/envgym0618/EnvGym/Agent0613/tool/codex/codex-cli/dist/cli.js"
        
        # Check if CLI file exists
        if not os.path.exists(cli_path):
            # If absolute path doesn't exist, try relative path
            current_dir = os.path.dirname(os.path.abspath(__file__))
            project_root = os.path.join(current_dir, '..', '..', '..')
            cli_path = os.path.join(project_root, 'Agent0613', 'tool', 'codex', 'codex-cli', 'dist', 'cli.js')
            
            if not os.path.exists(cli_path):
                return f"Error: Cannot find codex CLI tool at path: {cli_path}"
        
        # Build command - using same parameters as user example
        cmd = [
            'node',
            cli_path,
            '-q',  # quiet mode
            '--approval-mode', 'full-auto',
            task_description
        ]
        
        # Execute command
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True,
            cwd=os.getcwd()  # Execute in current working directory
        )
        
        return result.stdout.strip() if result.stdout.strip() else "Command executed successfully, no output"
        
    except subprocess.CalledProcessError as e:
        error_msg = f"Command execution failed: {e.stderr if e.stderr else e.stdout}"
        return error_msg
    except Exception as e:
        error_msg = f"Error occurred: {str(e)}"
        return error_msg

def test_codex_basic():
    """Test basic codex functionality"""
    print("Testing file creation...")
    result = run_codex_command("create a hello.txt file with content 'Hello, World!'", verbose=True)
    print(f"Result: {result}")
    
    print("\nTesting file reading...")
    result = run_codex_command("read the content of hello.txt", verbose=True)
    print(f"Result: {result}")

def test_codex_with_different_modes():
    """Test different approval modes"""
    modes = ['full-auto', 'semi-auto', 'manual']
    for mode in modes:
        print(f"\nTesting {mode} mode...")
        result = run_codex_command(
            "list files in current directory",
            approval_mode=mode,
            verbose=True
        )
        print(f"Result: {result}")

# Export main functions for use by other modules
__all__ = ['run_codex_command', 'execute_codex_query', 'simple_codex_agent']

if __name__ == "__main__":
    print("=== Testing simplified interface ===")
    test_result = simple_codex_agent("create a test.txt file in current directory")
    print(f"Simplified interface test result: {test_result}")
    
    print("\n=== Running basic tests ===")
    test_codex_basic()
    
    print("\n=== Running different mode tests ===")
    test_codex_with_different_modes()
    
    print("\nAll tests completed")

# Usage examples:
"""
Simplified usage examples:

# Simplest usage - designed for agent.py
from Agent0613.tool.codex.entry import simple_codex_agent

# Just pass the task description
result = simple_codex_agent("create a hello.txt file with content 'Hello World'")
print(result)

result = simple_codex_agent("list all python files in current directory")
print(result)

result = simple_codex_agent("show current directory structure")
print(result)

# Original full functionality is still available
from Agent0613.tool.codex.entry import execute_codex_query
result = execute_codex_query("analyze this codebase", approval_mode='semi-auto', verbose=True)
print(result)
"""
