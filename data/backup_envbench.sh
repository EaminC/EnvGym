#!/bin/bash

# Backup script: Backup envbench.sh files from EnvBench/scripts directory to data directory
# Usage: ./backup_envbench.sh

# Set paths
DATA_DIR="$(pwd)"
ENVBENCH_SCRIPTS_DIR="$(dirname "$(pwd)")/EnvBench/scripts"

echo "Starting to backup envbench.sh files..."
echo "Data directory: $DATA_DIR"
echo "Source directory: $ENVBENCH_SCRIPTS_DIR"

# Check if source directory exists
if [ ! -d "$ENVBENCH_SCRIPTS_DIR" ]; then
    echo "Error: Source directory does not exist: $ENVBENCH_SCRIPTS_DIR"
    exit 1
fi

# Counters
backed_up_count=0
skipped_count=0

# Iterate through all subdirectories in EnvBench/scripts directory
for script_dir in "$ENVBENCH_SCRIPTS_DIR"/*/; do
    if [ -d "$script_dir" ]; then
        repo_name=$(basename "$script_dir")
        
        # Check if envbench.sh exists
        script_file="$script_dir/envbench.sh"
        
        if [ -f "$script_file" ]; then
            # Check if target repo directory exists
            target_repo_dir="$DATA_DIR/$repo_name"
            
            if [ -d "$target_repo_dir" ]; then
                # Create envgym directory
                target_envgym_dir="$target_repo_dir/envgym"
                mkdir -p "$target_envgym_dir"
                
                # Copy file
                target_file="$target_envgym_dir/envbench.sh"
                
                if [ ! -f "$target_file" ]; then
                    cp "$script_file" "$target_file"
                    echo "✓ Backed up: EnvBench/scripts/$repo_name/envbench.sh -> $repo_name/envgym/envbench.sh"
                    ((backed_up_count++))
                else
                    echo "⚠ Skipped: $repo_name (target file already exists)"
                    ((skipped_count++))
                fi
            else
                echo "✗ Skipped: $repo_name (target repo directory does not exist)"
                ((skipped_count++))
            fi
        else
            echo "✗ Skipped: $repo_name (envbench.sh not found)"
            ((skipped_count++))
        fi
    fi
done

echo ""
echo "Backup completed!"
echo "Successfully backed up: $backed_up_count files"
echo "Skipped: $skipped_count directories" 