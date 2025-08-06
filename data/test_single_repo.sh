#!/bin/bash

# Test a single repo's EnvBench
# Usage: ./test_single_repo.sh <repo_name>

if [ $# -eq 0 ]; then
    echo "Usage: $0 <repo_name>"
    echo "Example: $0 acto"
    exit 1
fi

REPO_NAME="$1"
REPO_DIR="$(pwd)/$REPO_NAME"

echo "=== Testing Single Repo: $REPO_NAME ==="

# Check if repo directory exists
if [ ! -d "$REPO_DIR" ]; then
    echo "Error: Repo directory not found: $REPO_DIR"
    exit 1
fi

# Check if envgym/envbench.sh exists
ENVBENCH_SCRIPT="$REPO_DIR/envgym/envbench.sh"
if [ ! -f "$ENVBENCH_SCRIPT" ]; then
    echo "Error: envbench.sh not found: $ENVBENCH_SCRIPT"
    exit 1
fi

# Make script executable if needed
if [ ! -x "$ENVBENCH_SCRIPT" ]; then
    chmod +x "$ENVBENCH_SCRIPT"
fi

echo "Repo directory: $REPO_DIR"
echo "EnvBench script: $ENVBENCH_SCRIPT"
echo ""

# Change to repo directory
cd "$REPO_DIR"

echo "Running: bash ./envgym/envbench.sh"
echo "----------------------------------------"

# Run the test
start_time=$(date +%s)
bash ./envgym/envbench.sh
exit_code=$?
end_time=$(date +%s)
duration=$((end_time - start_time))

echo "----------------------------------------"
echo "Exit code: $exit_code"
echo "Duration: ${duration}s"

# Check if envbench.json was generated
JSON_FILE="./envgym/envbench.json"
if [ -f "$JSON_FILE" ]; then
    echo ""
    echo "=== Test Results ==="
    echo "Generated file: $JSON_FILE"
    echo "Content:"
    cat "$JSON_FILE"
    
    # Extract values
    PASS=$(grep -o '"PASS": [0-9]*' "$JSON_FILE" | grep -o '[0-9]*')
    FAIL=$(grep -o '"FAIL": [0-9]*' "$JSON_FILE" | grep -o '[0-9]*')
    WARN=$(grep -o '"WARN": [0-9]*' "$JSON_FILE" | grep -o '[0-9]*')
    
    echo ""
    echo "Summary: PASS=$PASS, FAIL=$FAIL, WARN=$WARN"
    
    if [ "$exit_code" -eq 0 ] && [ "$FAIL" -eq 0 ]; then
        echo "Status: ✓ SUCCESS"
    else
        echo "Status: ✗ FAILED"
    fi
else
    echo ""
    echo "Error: envbench.json was not generated"
    echo "Status: ✗ FAILED"
fi

# Return to original directory
cd "$(dirname "$0")" 