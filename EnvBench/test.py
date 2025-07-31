#!/usr/bin/env python3
"""
EnvBench - Generic Environment Test Runner
This script runs repo-specific test scripts based on the current directory structure.
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path


def find_repo_name():
    """Find the current repository name based on directory structure."""
    current_path = Path.cwd()
    
    # Look for common patterns in the path
    path_parts = current_path.parts
    
    # Check if we're in a data subdirectory (like /home/cc/EnvGym/data/acto)
    if 'data' in path_parts:
        data_index = path_parts.index('data')
        if data_index + 1 < len(path_parts):
            return path_parts[data_index + 1]
    
    # Check if we're in a repo root directory
    if current_path.name not in ['data', 'scripts', 'test', 'tests']:
        return current_path.name
    
    # Fallback: use parent directory name
    return current_path.parent.name


def find_test_script(repo_name):
    """Find the test script for the given repository."""
    # Get the path to EnvBench
    current_path = Path.cwd()
    envbench_path = None
    
    # Look for EnvBench in parent directories
    for parent in current_path.parents:
        if parent.name == 'EnvGym':
            envbench_path = parent / 'EnvBench'
            break
    
    if not envbench_path:
        # Try to find EnvBench relative to current path
        envbench_path = current_path / '..' / '..' / 'EnvBench'
        envbench_path = envbench_path.resolve()
    
    if not envbench_path.exists():
        raise FileNotFoundError(f"EnvBench directory not found: {envbench_path}")
    
    # Look for the test script
    test_script = envbench_path / 'scripts' / f'{repo_name}.sh'
    
    if not test_script.exists():
        raise FileNotFoundError(f"Test script not found: {test_script}")
    
    return test_script


def run_test_script(test_script_path, args=None):
    """Run the test script with optional arguments."""
    cmd = [str(test_script_path)]
    
    if args:
        cmd.extend(args)
    
    print(f"Running test script: {test_script_path}")
    print(f"Command: {' '.join(cmd)}")
    print("=" * 60)
    
    try:
        result = subprocess.run(cmd, check=False)
        return result.returncode
    except Exception as e:
        print(f"Error running test script: {e}")
        return 1


def main():
    parser = argparse.ArgumentParser(description='EnvBench - Generic Environment Test Runner')
    parser.add_argument('args', nargs=argparse.REMAINDER, help='Arguments to pass to the test script')
    
    args = parser.parse_args()
    
    try:
        # Find the repository name
        repo_name = find_repo_name()
        print(f"Detected repository: {repo_name}")
        
        # Find the test script
        test_script = find_test_script(repo_name)
        print(f"Found test script: {test_script}")
        
        # Run the test script
        exit_code = run_test_script(test_script, args.args)
        
        sys.exit(exit_code)
        
    except FileNotFoundError as e:
        print(f"Error: {e}")
        print("\nAvailable test scripts:")
        
        # List available test scripts
        try:
            envbench_path = Path(__file__).parent
            scripts_dir = envbench_path / 'scripts'
            
            if scripts_dir.exists():
                for script in scripts_dir.glob('*.sh'):
                    print(f"  - {script.stem}")
            else:
                print("  No scripts directory found")
        except Exception:
            print("  Could not list available scripts")
        
        sys.exit(1)
    
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main() 