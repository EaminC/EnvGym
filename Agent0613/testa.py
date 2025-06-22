#!/usr/bin/env python3
"""
Simple Docker runner test - uses new default logic from entry.py
Now just calls run_dockerfile_with_logs() with no parameters to use defaults
"""

from tool.dockerrun.entry import run_dockerfile_with_logs

# Use the new default logic - automatically uses envgym/envgym.dockerfile and overwrites envgym/log.txt
result = run_dockerfile_with_logs()

# Display results
if result['success']:
    print("✅ Docker execution completed successfully!")
    if result['run_output']:
        print(f"Container output: {result['run_output']}")
else:
    print("❌ Docker execution failed!")
    if result['build_error']:
        print(f"Build error: {result['build_error']}")
    if result['run_error']:
        print(f"Run error: {result['run_error']}")