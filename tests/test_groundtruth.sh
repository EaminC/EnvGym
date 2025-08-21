#!/bin/bash

# test_groundtruth.sh - Test script for running envbench.sh from EnvBench on groundtruth test cases
# Usage: ./test_groundtruth.sh <test_name>
# Example: ./test_groundtruth.sh gluetest

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
TEST_NAME=""
ORIGINAL_DIR=""
TEST_DIR=""
ENVGYM_DIR=""
SOURCE_SCRIPT=""
TARGET_SCRIPT=""
BACKUP_SCRIPT=""
BACKUP_EXISTS=false

# Function to print colored status messages
print_status() {
    local status=$1
    local message=$2
    case $status in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
    esac
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <test_name>"
    echo ""
    echo "This script performs the following operations:"
    echo "1. Checks existence of tests/groundtruth/<test_name>"
    echo "2. Changes to tests/groundtruth/<test_name>"
    echo "3. Backs up existing envgym/envbench.sh (if present)"
    echo "4. Copies EnvBench/scripts/<test_name>/envbench.sh to envgym/envbench.sh"
    echo "5. Runs envgym/envbench.sh with real-time output streaming"
    echo "6. Cleans up: removes copied script and restores backup if it existed"
    echo ""
    echo "Example: $0 gluetest"
    echo ""
    echo "Available test names can be found in tests/groundtruth/ directory"
}

# Cleanup function - runs on script exit or interruption
cleanup() {
    local exit_code=$?
    
    if [[ -n "$ORIGINAL_DIR" ]]; then
        print_status "INFO" "Returning to original directory..."
        cd "$ORIGINAL_DIR"
    fi
    
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        print_status "INFO" "Starting cleanup process..."
        
        # Remove the copied envbench.sh if it exists
        if [[ -f "$TARGET_SCRIPT" ]]; then
            print_status "INFO" "Removing copied envbench.sh..."
            rm -f "$TARGET_SCRIPT"
            if [[ $? -eq 0 ]]; then
                print_status "SUCCESS" "Copied envbench.sh removed successfully"
            else
                print_status "WARNING" "Failed to remove copied envbench.sh"
            fi
        fi
        
        # Restore backup if it exists
        if [[ "$BACKUP_EXISTS" == "true" && -f "$BACKUP_SCRIPT" ]]; then
            print_status "INFO" "Restoring backup envbench.sh..."
            mv "$BACKUP_SCRIPT" "$TARGET_SCRIPT"
            if [[ $? -eq 0 ]]; then
                print_status "SUCCESS" "Backup envbench.sh restored successfully"
            else
                print_status "WARNING" "Failed to restore backup envbench.sh"
            fi
        fi
    fi
    
    if [[ $exit_code -ne 0 ]]; then
        print_status "ERROR" "Script exited with error code: $exit_code"
    else
        print_status "SUCCESS" "Script completed successfully"
    fi
    
    exit $exit_code
}

# Global variable for child process PID
ENVBENCH_PID=""

# Enhanced interrupt handler
handle_interrupt() {
    print_status "WARNING" "Received interrupt signal - stopping envbench.sh..."
    if [[ -n "$ENVBENCH_PID" ]]; then
        print_status "INFO" "Terminating envbench.sh process (PID: $ENVBENCH_PID)..."
        kill -TERM "$ENVBENCH_PID" 2>/dev/null
        sleep 2
        # Force kill if still running
        kill -KILL "$ENVBENCH_PID" 2>/dev/null
        wait "$ENVBENCH_PID" 2>/dev/null
        print_status "SUCCESS" "envbench.sh stopped successfully"
    fi
    print_status "INFO" "Proceeding with cleanup..."
    exit 130
}

# Set up signal handlers for cleanup
trap cleanup EXIT
trap handle_interrupt INT TERM

# Main function
main() {
    # Store original directory
    ORIGINAL_DIR=$(pwd)
    
    print_status "INFO" "Starting test_groundtruth.sh script..."
    
    # Check if argument is provided
    if [[ $# -ne 1 ]]; then
        print_status "ERROR" "Invalid number of arguments"
        show_usage
        exit 1
    fi
    
    TEST_NAME="$1"
    print_status "INFO" "Test name: $TEST_NAME"
    
    # Step 1: Check existence of tests/groundtruth/xxx
    TEST_DIR="tests/groundtruth/$TEST_NAME"
    if [[ ! -d "$TEST_DIR" ]]; then
        print_status "ERROR" "Test directory '$TEST_DIR' does not exist"
        print_status "INFO" "Available test directories:"
        if [[ -d "tests/groundtruth" ]]; then
            ls -1 tests/groundtruth/ | sed 's/^/  - /'
        else
            print_status "ERROR" "tests/groundtruth directory not found"
        fi
        exit 1
    fi
    print_status "SUCCESS" "Test directory '$TEST_DIR' found"
    
    # Step 2: Change to tests/groundtruth/xxx
    print_status "INFO" "Changing to directory: $TEST_DIR"
    cd "$TEST_DIR"
    if [[ $? -ne 0 ]]; then
        print_status "ERROR" "Failed to change to directory: $TEST_DIR"
        exit 1
    fi
    print_status "SUCCESS" "Changed to directory: $(pwd)"
    
    # Set up paths relative to the new working directory
    ENVGYM_DIR="envgym"
    TARGET_SCRIPT="$ENVGYM_DIR/envbench.sh"
    BACKUP_SCRIPT="$ENVGYM_DIR/envbench.sh.backup"
    SOURCE_SCRIPT="../../../EnvBench/scripts/$TEST_NAME/envbench.sh"
    
    # Create envgym directory if it doesn't exist
    if [[ ! -d "$ENVGYM_DIR" ]]; then
        print_status "INFO" "Creating envgym directory..."
        mkdir -p "$ENVGYM_DIR"
        if [[ $? -ne 0 ]]; then
            print_status "ERROR" "Failed to create envgym directory"
            exit 1
        fi
        print_status "SUCCESS" "Created envgym directory"
    fi
    
    # Step 3: Handle backup of existing envbench.sh
    if [[ -f "$TARGET_SCRIPT" ]]; then
        print_status "WARNING" "Existing envbench.sh found at: $TARGET_SCRIPT"
        if [[ -f "$BACKUP_SCRIPT" ]]; then
            print_status "WARNING" "Backup file already exists at: $BACKUP_SCRIPT"
            print_status "INFO" "Skipping backup creation to avoid overwriting existing backup"
        else
            print_status "INFO" "Creating backup: $BACKUP_SCRIPT"
            cp "$TARGET_SCRIPT" "$BACKUP_SCRIPT"
            if [[ $? -eq 0 ]]; then
                BACKUP_EXISTS=true
                print_status "SUCCESS" "Backup created successfully"
            else
                print_status "ERROR" "Failed to create backup"
                exit 1
            fi
        fi
    else
        print_status "INFO" "No existing envbench.sh found - no backup needed"
    fi
    
    # Check if source script exists
    if [[ ! -f "$SOURCE_SCRIPT" ]]; then
        print_status "ERROR" "Source script not found: $SOURCE_SCRIPT"
        print_status "INFO" "Expected source script location: $(pwd)/$SOURCE_SCRIPT"
        # Try to show available scripts
        SOURCE_DIR="../../../EnvBench/scripts/$TEST_NAME"
        if [[ -d "$SOURCE_DIR" ]]; then
            print_status "INFO" "Files in source directory:"
            ls -la "$SOURCE_DIR" | sed 's/^/  /'
        else
            print_status "WARNING" "Source directory not found: $SOURCE_DIR"
        fi
        exit 1
    fi
    print_status "SUCCESS" "Source script found: $SOURCE_SCRIPT"
    
    # Step 4: Copy the envbench.sh from EnvBench
    print_status "INFO" "Copying envbench.sh from: $SOURCE_SCRIPT"
    print_status "INFO" "                       to: $TARGET_SCRIPT"
    cp "$SOURCE_SCRIPT" "$TARGET_SCRIPT"
    if [[ $? -ne 0 ]]; then
        print_status "ERROR" "Failed to copy envbench.sh"
        exit 1
    fi
    print_status "SUCCESS" "envbench.sh copied successfully"
    
    # Make the script executable
    chmod +x "$TARGET_SCRIPT"
    if [[ $? -ne 0 ]]; then
        print_status "WARNING" "Failed to make envbench.sh executable, but continuing..."
    else
        print_status "SUCCESS" "envbench.sh made executable"
    fi
    
    # Step 5: Run envgym/envbench.sh with real-time output streaming
    print_status "INFO" "Starting execution of envbench.sh..."
    print_status "INFO" "Press Ctrl+C to gracefully stop envbench.sh execution"
    print_status "INFO" "========================================"
    print_status "INFO" "BEGIN ENVBENCH.SH OUTPUT"
    print_status "INFO" "========================================"
    
    # Execute the script in background for proper signal handling
    bash "$TARGET_SCRIPT" &
    ENVBENCH_PID=$!
    
    print_status "INFO" "envbench.sh running with PID: $ENVBENCH_PID"
    
    # Wait for the background process to complete
    wait $ENVBENCH_PID
    SCRIPT_EXIT_CODE=$?
    
    # Clear the PID since process is done
    ENVBENCH_PID=""
    
    print_status "INFO" "========================================"
    print_status "INFO" "END ENVBENCH.SH OUTPUT"
    print_status "INFO" "========================================"
    
    if [[ $SCRIPT_EXIT_CODE -eq 0 ]]; then
        print_status "SUCCESS" "envbench.sh completed successfully (exit code: $SCRIPT_EXIT_CODE)"
    else
        print_status "WARNING" "envbench.sh completed with exit code: $SCRIPT_EXIT_CODE"
    fi
    
    # Step 6: Cleanup is handled by the cleanup function via trap
    print_status "INFO" "Script execution completed, cleanup will be handled automatically"
    
    # Return the exit code from the envbench.sh script
    exit $SCRIPT_EXIT_CODE
}

# Run main function with all arguments
main "$@"
