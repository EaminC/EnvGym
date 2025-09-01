#!/bin/bash

# run_baseline_with_model.sh - Test baseline model artifacts against EnvBench scoring scripts
# Usage: ./run_baseline_with_model.sh <model_path>
# Example: ./run_baseline_with_model.sh ENVGYM-baseline/claude/claude35haiku

# Check if exactly one argument is provided
if [ $# -ne 1 ]; then
    echo "Error: Expected exactly one argument (model path)"
    echo "Usage: $0 <model_path>"
    echo "Example: $0 ENVGYM-baseline/claude/claude35haiku"
    exit 1
fi

MODEL_PATH="$1"

# Get absolute path of the script's directory (EnvGym root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENVGYM_ROOT="$(dirname "$SCRIPT_DIR")"

# Define absolute model path
ABS_MODEL_PATH="$ENVGYM_ROOT/$MODEL_PATH"

# Check if model path exists
if [ ! -d "$ABS_MODEL_PATH" ]; then
    echo "Error: Model path $MODEL_PATH does not exist"
    exit 1
fi

echo "=== Validating model path: $MODEL_PATH ==="

# Get list of all project directories under the model path
PROJECT_DIRS=()
for project_dir in "$ABS_MODEL_PATH"/*; do
    if [ -d "$project_dir" ]; then
        project_name=$(basename "$project_dir")
        PROJECT_DIRS+=("$project_name")
    fi
done

if [ ${#PROJECT_DIRS[@]} -eq 0 ]; then
    echo "Error: No project directories found under $MODEL_PATH"
    exit 1
fi

echo "Found ${#PROJECT_DIRS[@]} project directories"

# VALIDATION PHASE: Check ALL dependencies before running ANY scoring scripts
echo ""
echo "=== VALIDATION PHASE ==="
VALID_PROJECTS=()
VALIDATION_FAILED=false

for project_name in "${PROJECT_DIRS[@]}"; do
    echo "Validating project: $project_name"
    
    # Define paths for this project
    MODEL_DOCKERFILE="$ABS_MODEL_PATH/$project_name/envgym.dockerfile"
    ENVBENCH_SCRIPT="$ENVGYM_ROOT/EnvBench/scripts/$project_name/envbench.sh"
    DATA_DIR="$ENVGYM_ROOT/data/$project_name"
    
    # Check if model dockerfile exists
    if [ ! -f "$MODEL_DOCKERFILE" ]; then
        echo "  ❌ Missing: $MODEL_PATH/$project_name/envgym.dockerfile"
        VALIDATION_FAILED=true
        continue
    fi
    
    # Check if EnvBench script exists
    if [ ! -f "$ENVBENCH_SCRIPT" ]; then
        echo "  ❌ Missing: EnvBench/scripts/$project_name/envbench.sh"
        VALIDATION_FAILED=true
        continue
    fi
    
    # Check if data directory exists and is non-empty
    if [ ! -d "$DATA_DIR" ]; then
        echo "  ❌ Missing: data/$project_name directory"
        VALIDATION_FAILED=true
        continue
    fi
    
    if [ -z "$(ls -A "$DATA_DIR" 2>/dev/null)" ]; then
        echo "  ❌ Empty: data/$project_name directory is empty"
        VALIDATION_FAILED=true
        continue
    fi
    
    echo "  ✅ All dependencies found"
    VALID_PROJECTS+=("$project_name")
done

# Fail immediately if any validation failed
if [ "$VALIDATION_FAILED" = true ]; then
    echo ""
    echo "❌ VALIDATION FAILED: Missing dependencies detected"
    echo "Please ensure all required files exist before running the script"
    exit 1
fi

echo ""
echo "✅ VALIDATION PASSED: All ${#VALID_PROJECTS[@]} projects have required dependencies"
echo "Projects to process: ${VALID_PROJECTS[*]}"

# EXECUTION PHASE: Process each validated project
echo ""
echo "=== EXECUTION PHASE ==="

SUCCESSFUL_RUNS=0
FAILED_RUNS=0

for project_name in "${VALID_PROJECTS[@]}"; do
    echo ""
    echo ">>> Processing project: $project_name"
    
    # Define paths for this project
    MODEL_DOCKERFILE="$ABS_MODEL_PATH/$project_name/envgym.dockerfile"
    ENVBENCH_SCRIPT="$ENVGYM_ROOT/EnvBench/scripts/$project_name/envbench.sh"
    DATA_DIR="$ENVGYM_ROOT/data/$project_name"
    LOG_FILE="$ABS_MODEL_PATH/$project_name/scoring.log"
    
    # Change to data directory
    cd "$DATA_DIR" || {
        echo "Error: Cannot change to data/$project_name directory"
        ((FAILED_RUNS++))
        continue
    }
    
    # Create envgym directory if it doesn't exist
    mkdir -p envgym
    
    # Copy EnvBench script
    cp "$ENVBENCH_SCRIPT" envgym/envbench.sh || {
        echo "Error: Failed to copy envbench.sh for $project_name"
        ((FAILED_RUNS++))
        continue
    }
    
    # Make sure the copied script is executable
    chmod +x envgym/envbench.sh
    
    # Copy model dockerfile
    cp "$MODEL_DOCKERFILE" envgym/envgym.dockerfile || {
        echo "Error: Failed to copy envgym.dockerfile for $project_name"
        ((FAILED_RUNS++))
        continue
    }
    
    # Run envbench.sh and capture output to log file
    echo "Running scoring script for $project_name (output saved to: $MODEL_PATH/$project_name/scoring.log)"
    if ./envgym/envbench.sh > "$LOG_FILE" 2>&1; then
        echo "✅ Successfully completed: $project_name"
        ((SUCCESSFUL_RUNS++))
    else
        echo "❌ Failed: $project_name (check log for details)"
        ((FAILED_RUNS++))
    fi
done

# Final summary
echo ""
echo "=== EXECUTION SUMMARY ==="
echo "Total projects processed: ${#VALID_PROJECTS[@]}"
echo "Successful runs: $SUCCESSFUL_RUNS"
echo "Failed runs: $FAILED_RUNS"

if [ $FAILED_RUNS -eq 0 ]; then
    echo "🎉 All projects completed successfully!"
    exit 0
else
    echo "⚠️  Some projects failed. Check individual log files for details."
    exit 1
fi
