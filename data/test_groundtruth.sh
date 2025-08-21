#!/bin/bash

# test_groundtruth.sh - Test script for EnvGym groundtruth benchmarks
# Usage: ./test_groundtruth.sh <project_name>

# Check if exactly one argument is provided
if [ $# -ne 1 ]; then
    echo "Error: Expected exactly one argument (project name)"
    echo "Usage: $0 <project_name>"
    exit 1
fi

PROJECT_NAME="$1"

# Get absolute path of the script's directory (EnvGym root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVGYM_ROOT="$(dirname "$SCRIPT_DIR")"

# Define paths
ENVBENCH_SCRIPT="$ENVGYM_ROOT/EnvBench/scripts/$PROJECT_NAME/envbench.sh"
DATA_DIR="$ENVGYM_ROOT/data/$PROJECT_NAME"
DOCKERFILE_PATH="$ENVGYM_ROOT/tests/groundtruth/$PROJECT_NAME/envgym/envgym.dockerfile"

# 1. Check if EnvBench/scripts/xxx/envbench.sh exists
if [ ! -f "$ENVBENCH_SCRIPT" ]; then
    echo "Error: EnvBench/scripts/$PROJECT_NAME/envbench.sh does not exist"
    exit 1
fi

# 2. Check if data/xxx exists and is nonempty
if [ ! -d "$DATA_DIR" ]; then
    echo "Error: data/$PROJECT_NAME directory does not exist"
    exit 1
fi

# Check if directory is nonempty
if [ -z "$(ls -A "$DATA_DIR" 2>/dev/null)" ]; then
    echo "Error: data/$PROJECT_NAME directory is empty"
    exit 1
fi

# 3. Check if tests/groundtruth/xxx/envgym/envgym.dockerfile exists
if [ ! -f "$DOCKERFILE_PATH" ]; then
    echo "Error: tests/groundtruth/$PROJECT_NAME/envgym/envgym.dockerfile does not exist"
    exit 1
fi

# 4. Go into data/xxx, create envgym folder if not already there
cd "$DATA_DIR" || {
    echo "Error: Cannot change to data/$PROJECT_NAME directory"
    exit 1
}

# Create envgym directory if it doesn't exist
mkdir -p envgym

# 5. Copy envbench into data/xxx/envgym/envbench.sh, overwrite if already there
cp "$ENVBENCH_SCRIPT" envgym/envbench.sh || {
    echo "Error: Failed to copy envbench.sh"
    exit 1
}

# Make sure the copied script is executable
chmod +x envgym/envbench.sh

# 6. Copy envgym.dockerfile into data/xxx/envgym/envgym.dockerfile, overwrite if already there
cp "$DOCKERFILE_PATH" envgym/envgym.dockerfile || {
    echo "Error: Failed to copy envgym.dockerfile"
    exit 1
}

# 7. cd into data/xxx (already there), run envgym/envbench.sh, stream its output
# 8. Nothing, no need to clean up or say anything ended, the last line output of envbench.sh should also be last line output of this script
exec ./envgym/envbench.sh
