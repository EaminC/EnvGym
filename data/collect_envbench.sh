#!/bin/bash

# Collection script: Collect envbench.sh files from data directory to EnvBench/scripts directory
# Usage: ./collect_envbench.sh

# Set paths
DATA_DIR="$(pwd)"
ENVBENCH_SCRIPTS_DIR="$(dirname "$(pwd)")/EnvBench/scripts"

echo "Starting to collect envbench.sh files..."
echo "Data directory: $DATA_DIR"
echo "Target directory: $ENVBENCH_SCRIPTS_DIR"

# Ensure target directory exists
mkdir -p "$ENVBENCH_SCRIPTS_DIR"

# Counters
collected_count=0
skipped_count=0

# Iterate through all subdirectories in data directory
for repo_dir in "$DATA_DIR"/*/; do
    if [ -d "$repo_dir" ]; then
        repo_name=$(basename "$repo_dir")
        
        # Check if envgym/envbench.sh exists
        envbench_path="$repo_dir/envgym/envbench.sh"
        
        if [ -f "$envbench_path" ]; then
            # Create target directory
            target_dir="$ENVBENCH_SCRIPTS_DIR/$repo_name"
            mkdir -p "$target_dir"
            
            # Copy file
            target_file="$target_dir/envbench.sh"
            
            if [ ! -f "$target_file" ]; then
                cp "$envbench_path" "$target_file"
                echo "✓ Collected: $repo_name/envgym/envbench.sh -> EnvBench/scripts/$repo_name/envbench.sh"
                ((collected_count++))
            else
                echo "⚠ Skipped: $repo_name (target file already exists)"
                ((skipped_count++))
            fi
        else
            echo "✗ Skipped: $repo_name (envbench.sh not found)"
            ((skipped_count++))
        fi
    fi
done

echo ""
echo "Collection completed!"
echo "Successfully collected: $collected_count files"
echo "Skipped: $skipped_count directories" 