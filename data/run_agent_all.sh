#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_SCRIPT="$SCRIPT_DIR/../../Agent/agent.py"

# Check if agent.py exists
if [ ! -f "$AGENT_SCRIPT" ]; then
    echo "Error: Cannot find $AGENT_SCRIPT"
    echo "Please ensure Agent/agent.py file exists"
    exit 1
fi

echo "Starting to iterate through all repositories and execute agent.py..."
echo "Agent script path: $AGENT_SCRIPT"
echo "=================================="

# Iterate through all subdirectories in current directory
for repo_dir in */; do
    # Skip non-directory items
    if [ ! -d "$repo_dir" ]; then
        continue
    fi
    
    # Remove trailing slash from directory name
    repo_name="${repo_dir%/}"
    
    echo "=================================="
    echo "Processing repository: $repo_name"
    echo "=================================="
    
    # Enter repository directory
    cd "$repo_dir"
    
    # Check if successfully entered directory
    if [ $? -ne 0 ]; then
        echo "Error: Cannot enter directory $repo_name"
        cd "$SCRIPT_DIR"
        continue
    fi
    
    # Execute agent.py script
    echo "Executing: python $AGENT_SCRIPT"
    python "$AGENT_SCRIPT"
    
    # Check execution result
    if [ $? -eq 0 ]; then
        echo "✓ $repo_name executed successfully"
    else
        echo "✗ $repo_name execution failed"
    fi
    
    # Return to original directory
    cd "$SCRIPT_DIR"
    
    echo ""
done

echo "=================================="
echo "All repositories processed!"
echo "==================================" 