#!/bin/bash

# Auto-run EnvBench tests for all repos
# Usage: ./run_all_envbench_tests.sh

# Set paths
DATA_DIR="$(pwd)"
LOG_FILE="envbench_test_results.log"
SUMMARY_FILE="envbench_test_summary.csv"

echo "=== Auto-running EnvBench Tests for All Repos ==="
echo "Data directory: $DATA_DIR"
echo "Log file: $LOG_FILE"
echo "Summary file: $SUMMARY_FILE"
echo ""

# Initialize log and summary files
echo "EnvBench Test Results - $(date)" > "$LOG_FILE"
echo "Repo,PASS,FAIL,WARN,Time" > "$SUMMARY_FILE"

# Counters
total_repos=0
successful_tests=0
failed_tests=0
skipped_tests=0

# Function to extract values from JSON
extract_json_value() {
    local json_file="$1"
    local key="$2"
    if [ -f "$json_file" ]; then
        grep -o "\"$key\": [0-9]*" "$json_file" | grep -o "[0-9]*"
    else
        echo "0"
    fi
}

# Function to run test for a single repo
run_test_for_repo() {
    local repo_dir="$1"
    local repo_name="$2"
    local start_time=$(date +%s)
    
    echo "Testing repo: $repo_name"
    echo "Testing repo: $repo_name" >> "$LOG_FILE"
    
    # Check if envgym/envbench.sh exists
    local envbench_script="$repo_dir/envgym/envbench.sh"
            if [ ! -f "$envbench_script" ]; then
            echo "  ✗ Skipped: envbench.sh not found"
            echo "  ✗ Skipped: envbench.sh not found" >> "$LOG_FILE"
            echo "$repo_name,0,0,0,0s" >> "$SUMMARY_FILE"
            ((skipped_tests++))
            return
        fi
    
    # Check if script is executable
    if [ ! -x "$envbench_script" ]; then
        chmod +x "$envbench_script"
    fi
    
    # Run the test
    echo "  Running: bash $envbench_script"
    echo "  Running: bash $envbench_script" >> "$LOG_FILE"
    
    # Change to repo directory and run test
    cd "$repo_dir"
    
    # Capture output and exit code
    local output
    local exit_code
    output=$(bash ./envgym/envbench.sh 2>&1)
    exit_code=$?
    
    # Return to original directory
    cd "$DATA_DIR"
    
    # Record output
    echo "  Output:" >> "$LOG_FILE"
    echo "$output" >> "$LOG_FILE"
    echo "  Exit code: $exit_code" >> "$LOG_FILE"
    
    # Check if envbench.json was generated
    local json_file="$repo_dir/envgym/envbench.json"
    if [ -f "$json_file" ]; then
        # Extract values from JSON
        local pass_count=$(extract_json_value "$json_file" "PASS")
        local fail_count=$(extract_json_value "$json_file" "FAIL")
        local warn_count=$(extract_json_value "$json_file" "WARN")
        
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        # Print results
        echo "  ✓ Completed: PASS=$pass_count, FAIL=$fail_count, WARN=$warn_count (${duration}s)"
        echo "  ✓ Completed: PASS=$pass_count, FAIL=$fail_count, WARN=$warn_count (${duration}s)" >> "$LOG_FILE"
        
        # Add to summary
        echo "$repo_name,$pass_count,$fail_count,$warn_count,${duration}s" >> "$SUMMARY_FILE"
        
        if [ "$exit_code" -eq 0 ] && [ "$fail_count" -eq 0 ]; then
            ((successful_tests++))
        else
            ((failed_tests++))
        fi
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo "  ✗ Failed: envbench.json not generated"
        echo "  ✗ Failed: envbench.json not generated" >> "$LOG_FILE"
        echo "$repo_name,0,0,0,${duration}s" >> "$SUMMARY_FILE"
        ((failed_tests++))
    fi
    
    echo "" >> "$LOG_FILE"
}

# Main execution
echo "Starting tests at $(date)"
echo "Starting tests at $(date)" >> "$LOG_FILE"
echo ""

# Iterate through all repo directories
for repo_dir in "$DATA_DIR"/*/; do
    if [ -d "$repo_dir" ]; then
        repo_name=$(basename "$repo_dir")
        
        # Skip non-repo directories
        if [[ "$repo_name" =~ ^(collected_stats|collected_env_test_stats)$ ]]; then
            continue
        fi
        
        ((total_repos++))
        run_test_for_repo "$repo_dir" "$repo_name"
        
        # Add a small delay between tests
        sleep 1
    fi
done

# Print final summary
echo ""
echo "=== Test Summary ==="
echo "Total repos processed: $total_repos"
echo "Successful tests: $successful_tests"
echo "Failed tests: $failed_tests"
echo "Skipped tests: $skipped_tests"
echo ""
echo "Detailed results saved to: $LOG_FILE"
echo "Summary CSV saved to: $SUMMARY_FILE"
echo ""
echo "=== Quick Summary ==="
echo "Repo,PASS,FAIL,WARN,Time"
tail -n +2 "$SUMMARY_FILE" | head -10

if [ $total_repos -gt 10 ]; then
    echo "... (showing first 10 results, see $SUMMARY_FILE for complete list)"
fi

echo ""
echo "Tests completed at $(date)" 