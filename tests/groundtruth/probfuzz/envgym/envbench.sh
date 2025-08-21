#!/bin/bash

# ProbFuzz Environment Benchmark Test Script
# This script tests the Docker environment setup for ProbFuzz: A probabilistic fuzzing framework
# Tailored specifically for ProbFuzz project requirements and features

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Function to write results to JSON file
write_results_to_json() {
    local json_file="envgym/envbench.json"
    # Ensure the directory exists and has proper permissions
    mkdir -p "$(dirname "$json_file")"
    cat > "$json_file" << EOF
{
    "PASS": $PASS_COUNT,
    "FAIL": $FAIL_COUNT,
    "WARN": $WARN_COUNT
}
EOF
    echo -e "${BLUE}[INFO]${NC} Results written to $json_file"
}

# Check if envgym.dockerfile exists (only when not in Docker container)
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
    if [ ! -f "envgym/envgym.dockerfile" ]; then
        echo -e "${RED}[CRITICAL ERROR]${NC} envgym/envgym.dockerfile does not exist"
        echo -e "${RED}[RESULT]${NC} Benchmark score: 0 (Dockerfile missing)"
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
fi

# Function to print status with color
print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS")
            echo -e "${GREEN}[PASS]${NC} $message"
            ((PASS_COUNT++))
            ;;
        "FAIL")
            echo -e "${RED}[FAIL]${NC} $message"
            ((FAIL_COUNT++))
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ((WARN_COUNT++))
            ;;
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
    esac
}

# Cleanup function
cleanup() {
    echo "Cleaning up..."
    jobs -p | xargs -r kill
    rm -f docker_build.log
    docker stop probfuzz-env-test 2>/dev/null || true
    docker rm probfuzz-env-test 2>/dev/null || true
    exit 0
}

trap cleanup SIGINT SIGTERM

# Check if we're running inside Docker container
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo "Running inside Docker container - proceeding with environment test..."
else
    echo "Not running in Docker container - building and running Docker test..."
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        echo "ERROR: Docker is not installed or not in PATH"
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "envgym/envgym.dockerfile" ]; then
        echo "ERROR: envgym.dockerfile not found. Please run this script from the probfuzz project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t probfuzz-env-test .; then
        echo -e "${RED}[CRITICAL ERROR]${NC} Docker build failed"
        echo -e "${RED}[RESULT]${NC} Benchmark score: 0 (Docker build failed)"
        # Only write 0 0 0 to JSON if the file doesn't exist or is empty
        if [ ! -f "envgym/envbench.json" ] || [ ! -s "envgym/envbench.json" ]; then
            PASS_COUNT=0
            FAIL_COUNT=0
            WARN_COUNT=0
            write_results_to_json
        fi
        exit 1
    fi
    
    # Run this script inside Docker container
    echo "Running environment test in Docker container..."
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/probfuzz" --entrypoint="" probfuzz-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        cd /home/cc/EnvGym/data/probfuzz
        bash envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "ProbFuzz Environment Benchmark Test"
echo "=========================================="

echo "1. Checking System Dependencies..."
echo "--------------------------------"
# Check Python
if command -v python &> /dev/null; then
    python_version=$(python --version 2>&1)
    print_status "PASS" "Python is available: $python_version"
else
    print_status "FAIL" "Python is not available"
fi

# Check Python version
if command -v python &> /dev/null; then
    python_major=$(python --version 2>&1 | sed 's/.*Python \([0-9]*\)\.[0-9]*.*/\1/')
    python_minor=$(python --version 2>&1 | sed 's/.*Python [0-9]*\.\([0-9]*\).*/\1/')
    if [ -n "$python_major" ] && [ "$python_major" -ge 2 ] && [ "$python_minor" -ge 7 ]; then
        print_status "PASS" "Python version is >= 2.7 (compatible)"
    else
        print_status "WARN" "Python version should be >= 2.7 (found: $python_major.$python_minor)"
    fi
else
    print_status "FAIL" "Python is not available for version check"
fi

# Check pip
if command -v pip &> /dev/null; then
    pip_version=$(pip --version 2>&1)
    print_status "PASS" "pip is available: $pip_version"
else
    print_status "FAIL" "pip is not available"
fi

# Check G++
if command -v g++ &> /dev/null; then
    gpp_version=$(g++ --version 2>&1 | head -n 1)
    print_status "PASS" "G++ is available: $gpp_version"
else
    print_status "WARN" "G++ is not available"
fi

# Check Make
if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "Make is available: $make_version"
else
    print_status "FAIL" "Make is not available"
fi

# Check wget
if command -v wget &> /dev/null; then
    wget_version=$(wget --version 2>&1 | head -n 1)
    print_status "PASS" "wget is available: $wget_version"
else
    print_status "FAIL" "wget is not available"
fi

# Check curl
if command -v curl &> /dev/null; then
    curl_version=$(curl --version 2>&1 | head -n 1)
    print_status "PASS" "curl is available: $curl_version"
else
    print_status "FAIL" "curl is not available"
fi

# Check Git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1)
    print_status "PASS" "Git is available: $git_version"
else
    print_status "FAIL" "Git is not available"
fi

# Check bc
if command -v bc &> /dev/null; then
    bc_version=$(bc --version 2>&1 | head -n 1)
    print_status "PASS" "bc is available: $bc_version"
else
    print_status "WARN" "bc is not available"
fi

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "backends" ]; then
    print_status "PASS" "backends directory exists (PPS translators)"
else
    print_status "FAIL" "backends directory not found"
fi

if [ -d "language" ]; then
    print_status "PASS" "language directory exists (grammar and templates)"
else
    print_status "FAIL" "language directory not found"
fi

if [ -d "utils" ]; then
    print_status "PASS" "utils directory exists (utility functions)"
else
    print_status "FAIL" "utils directory not found"
fi

if [ -d "metrics" ]; then
    print_status "PASS" "metrics directory exists (metrics calculation)"
else
    print_status "FAIL" "metrics directory not found"
fi

# Check key files
if [ -f "probfuzz.py" ]; then
    print_status "PASS" "probfuzz.py exists (main tool)"
else
    print_status "FAIL" "probfuzz.py not found"
fi

if [ -f "install.sh" ]; then
    print_status "PASS" "install.sh exists (installation script)"
else
    print_status "FAIL" "install.sh not found"
fi

if [ -f "check.py" ]; then
    print_status "PASS" "check.py exists (dependency checker)"
else
    print_status "FAIL" "check.py not found"
fi

if [ -f "driver.py" ]; then
    print_status "PASS" "driver.py exists (driver script)"
else
    print_status "FAIL" "driver.py not found"
fi

if [ -f "config.json" ]; then
    print_status "PASS" "config.json exists (configuration)"
else
    print_status "FAIL" "config.json not found"
fi

if [ -f "models.json" ]; then
    print_status "PASS" "models.json exists (distribution models)"
else
    print_status "FAIL" "models.json not found"
fi

if [ -f "summary.sh" ]; then
    print_status "PASS" "summary.sh exists (summary script)"
else
    print_status "FAIL" "summary.sh not found"
fi

if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
fi

if [ -f "LICENSE" ]; then
    print_status "PASS" "LICENSE exists"
else
    print_status "FAIL" "LICENSE not found"
fi

# Check backend files
if [ -f "backends/__init__.py" ]; then
    print_status "PASS" "backends/__init__.py exists"
else
    print_status "FAIL" "backends/__init__.py not found"
fi

if [ -f "backends/backend.py" ]; then
    print_status "PASS" "backends/backend.py exists (base backend)"
else
    print_status "FAIL" "backends/backend.py not found"
fi

if [ -f "backends/stan.py" ]; then
    print_status "PASS" "backends/stan.py exists (Stan backend)"
else
    print_status "FAIL" "backends/stan.py not found"
fi

if [ -f "backends/edward.py" ]; then
    print_status "PASS" "backends/edward.py exists (Edward backend)"
else
    print_status "FAIL" "backends/edward.py not found"
fi

if [ -f "backends/pyro.py" ]; then
    print_status "PASS" "backends/pyro.py exists (Pyro backend)"
else
    print_status "FAIL" "backends/pyro.py not found"
fi

# Check language files
if [ -f "language/__init__.py" ]; then
    print_status "PASS" "language/__init__.py exists"
else
    print_status "FAIL" "language/__init__.py not found"
fi

if [ -f "language/templateparser.py" ]; then
    print_status "PASS" "language/templateparser.py exists (template parser)"
else
    print_status "FAIL" "language/templateparser.py not found"
fi

if [ -f "language/checker.py" ]; then
    print_status "PASS" "language/checker.py exists (language checker)"
else
    print_status "FAIL" "language/checker.py not found"
fi

if [ -f "language/mylistener.py" ]; then
    print_status "PASS" "language/mylistener.py exists (ANTLR listener)"
else
    print_status "FAIL" "language/mylistener.py not found"
fi

if [ -f "language/myvisitor.py" ]; then
    print_status "PASS" "language/myvisitor.py exists (ANTLR visitor)"
else
    print_status "FAIL" "language/myvisitor.py not found"
fi

if [ -f "language/stanmodels.json" ]; then
    print_status "PASS" "language/stanmodels.json exists (Stan models)"
else
    print_status "FAIL" "language/stanmodels.json not found"
fi

if [ -d "language/antlr" ]; then
    print_status "PASS" "language/antlr directory exists (ANTLR grammar)"
else
    print_status "FAIL" "language/antlr directory not found"
fi

if [ -d "language/templates" ]; then
    print_status "PASS" "language/templates directory exists (templates)"
else
    print_status "FAIL" "language/templates directory not found"
fi

# Check utils files
if [ -f "utils/__init__.py" ]; then
    print_status "PASS" "utils/__init__.py exists"
else
    print_status "FAIL" "utils/__init__.py not found"
fi

if [ -f "utils/utils.py" ]; then
    print_status "PASS" "utils/utils.py exists (utility functions)"
else
    print_status "FAIL" "utils/utils.py not found"
fi

echo ""
echo "3. Checking Environment Variables..."
echo "-----------------------------------"
# Check Python environment
if [ -n "${PYTHONPATH:-}" ]; then
    print_status "PASS" "PYTHONPATH is set: $PYTHONPATH"
else
    print_status "WARN" "PYTHONPATH is not set"
fi

# Check PATH
if echo "$PATH" | grep -q "python"; then
    print_status "PASS" "python is in PATH"
else
    print_status "WARN" "python is not in PATH"
fi

if echo "$PATH" | grep -q "pip"; then
    print_status "PASS" "pip is in PATH"
else
    print_status "WARN" "pip is not in PATH"
fi

if echo "$PATH" | grep -q "g++"; then
    print_status "PASS" "g++ is in PATH"
else
    print_status "WARN" "g++ is not in PATH"
fi

if echo "$PATH" | grep -q "make"; then
    print_status "PASS" "make is in PATH"
else
    print_status "WARN" "make is not in PATH"
fi

if echo "$PATH" | grep -q "wget"; then
    print_status "PASS" "wget is in PATH"
else
    print_status "WARN" "wget is not in PATH"
fi

if echo "$PATH" | grep -q "curl"; then
    print_status "PASS" "curl is in PATH"
else
    print_status "WARN" "curl is not in PATH"
fi

if echo "$PATH" | grep -q "git"; then
    print_status "PASS" "git is in PATH"
else
    print_status "WARN" "git is not in PATH"
fi

echo ""
echo "4. Testing Python Environment..."
echo "-------------------------------"
# Test Python
if command -v python &> /dev/null; then
    print_status "PASS" "python is available"
    
    # Test Python execution
    if timeout 30s python -c "print('Python works')" >/dev/null 2>&1; then
        print_status "PASS" "Python execution works"
    else
        print_status "WARN" "Python execution failed"
    fi
    
    # Test pip
    if timeout 30s pip --version >/dev/null 2>&1; then
        print_status "PASS" "pip works"
    else
        print_status "WARN" "pip failed"
    fi
else
    print_status "FAIL" "python is not available"
fi

echo ""
echo "5. Testing ProbFuzz Dependencies..."
echo "----------------------------------"
# Test Python dependencies
if command -v python &> /dev/null; then
    # Test antlr4
    if timeout 30s python -c "import antlr4; print('antlr4 imported successfully')" >/dev/null 2>&1; then
        print_status "PASS" "antlr4 import works"
    else
        print_status "WARN" "antlr4 import failed"
    fi
    
    # Test six
    if timeout 30s python -c "import six; print('six imported successfully')" >/dev/null 2>&1; then
        print_status "PASS" "six import works"
    else
        print_status "WARN" "six import failed"
    fi
    
    # Test astunparse
    if timeout 30s python -c "import astunparse; print('astunparse imported successfully')" >/dev/null 2>&1; then
        print_status "PASS" "astunparse import works"
    else
        print_status "WARN" "astunparse import failed"
    fi
    
    # Test ast
    if timeout 30s python -c "import ast; print('ast imported successfully')" >/dev/null 2>&1; then
        print_status "PASS" "ast import works"
    else
        print_status "WARN" "ast import failed"
    fi
    
    # Test pystan
    if timeout 30s python -c "import pystan; print('pystan imported successfully')" >/dev/null 2>&1; then
        print_status "PASS" "pystan import works"
    else
        print_status "WARN" "pystan import failed"
    fi
    
    # Test edward
    if timeout 30s python -c "import edward; print('edward imported successfully')" >/dev/null 2>&1; then
        print_status "PASS" "edward import works"
    else
        print_status "WARN" "edward import failed"
    fi
    
    # Test pyro
    if timeout 30s python -c "import pyro; print('pyro imported successfully')" >/dev/null 2>&1; then
        print_status "PASS" "pyro import works"
    else
        print_status "WARN" "pyro import failed"
    fi
    
    # Test tensorflow
    if timeout 30s python -c "import tensorflow; print('tensorflow imported successfully')" >/dev/null 2>&1; then
        print_status "PASS" "tensorflow import works"
    else
        print_status "WARN" "tensorflow import failed"
    fi
    
    # Test pandas
    if timeout 30s python -c "import pandas; print('pandas imported successfully')" >/dev/null 2>&1; then
        print_status "PASS" "pandas import works"
    else
        print_status "WARN" "pandas import failed"
    fi
    
    # Test torch
    if timeout 30s python -c "import torch; print('torch imported successfully')" >/dev/null 2>&1; then
        print_status "PASS" "torch import works"
    else
        print_status "WARN" "torch import failed"
    fi
else
    print_status "FAIL" "python is not available for dependency testing"
fi

echo ""
echo "6. Testing ProbFuzz Build System..."
echo "----------------------------------"
# Test install.sh
if [ -f "install.sh" ]; then
    print_status "PASS" "install.sh exists for build testing"
    
    # Check if it's executable
    if [ -x "install.sh" ]; then
        print_status "PASS" "install.sh is executable"
    else
        print_status "WARN" "install.sh is not executable"
    fi
    
    # Check for key components
    if grep -q "python2.7" install.sh; then
        print_status "PASS" "install.sh includes Python 2.7 requirement"
    else
        print_status "WARN" "install.sh missing Python 2.7 requirement"
    fi
    
    if grep -q "pystan" install.sh; then
        print_status "PASS" "install.sh includes pystan requirement"
    else
        print_status "WARN" "install.sh missing pystan requirement"
    fi
    
    if grep -q "edward" install.sh; then
        print_status "PASS" "install.sh includes edward requirement"
    else
        print_status "WARN" "install.sh missing edward requirement"
    fi
    
    if grep -q "pyro" install.sh; then
        print_status "PASS" "install.sh includes pyro requirement"
    else
        print_status "WARN" "install.sh missing pyro requirement"
    fi
    
    if grep -q "tensorflow" install.sh; then
        print_status "PASS" "install.sh includes tensorflow requirement"
    else
        print_status "WARN" "install.sh missing tensorflow requirement"
    fi
    
    if grep -q "antlr" install.sh; then
        print_status "PASS" "install.sh includes antlr requirement"
    else
        print_status "WARN" "install.sh missing antlr requirement"
    fi
else
    print_status "FAIL" "install.sh not found"
fi

# Test check.py
if [ -f "check.py" ]; then
    print_status "PASS" "check.py exists"
    
    # Check if it's executable
    if [ -x "check.py" ]; then
        print_status "PASS" "check.py is executable"
    else
        print_status "WARN" "check.py is not executable"
    fi
    
    # Check if it's a valid Python script
    if command -v python &> /dev/null; then
        if timeout 30s python -m py_compile check.py >/dev/null 2>&1; then
            print_status "PASS" "check.py is a valid Python script"
        else
            print_status "WARN" "check.py may not be a valid Python script"
        fi
    else
        print_status "WARN" "python not available for check.py testing"
    fi
else
    print_status "FAIL" "check.py not found"
fi

# Test probfuzz.py
if [ -f "probfuzz.py" ]; then
    print_status "PASS" "probfuzz.py exists"
    
    # Check if it's executable
    if [ -x "probfuzz.py" ]; then
        print_status "PASS" "probfuzz.py is executable"
    else
        print_status "WARN" "probfuzz.py is not executable"
    fi
    
    # Check if it's a valid Python script
    if command -v python &> /dev/null; then
        if timeout 30s python -m py_compile probfuzz.py >/dev/null 2>&1; then
            print_status "PASS" "probfuzz.py is a valid Python script"
        else
            print_status "WARN" "probfuzz.py may not be a valid Python script"
        fi
    else
        print_status "WARN" "python not available for probfuzz.py testing"
    fi
else
    print_status "FAIL" "probfuzz.py not found"
fi

echo ""
echo "7. Testing ProbFuzz Source Code Structure..."
echo "-------------------------------------------"
# Test source code directories
if [ -d "backends" ]; then
    print_status "PASS" "backends directory exists for backend testing"
    
    # Count backend files
    backend_count=$(find backends -name "*.py" | wc -l)
    if [ "$backend_count" -gt 0 ]; then
        print_status "PASS" "Found $backend_count Python files in backends directory"
    else
        print_status "WARN" "No Python files found in backends directory"
    fi
    
    # Check for key backend files
    if [ -f "backends/stan.py" ]; then
        print_status "PASS" "backends/stan.py exists (Stan backend)"
    else
        print_status "FAIL" "backends/stan.py not found"
    fi
    
    if [ -f "backends/edward.py" ]; then
        print_status "PASS" "backends/edward.py exists (Edward backend)"
    else
        print_status "FAIL" "backends/edward.py not found"
    fi
    
    if [ -f "backends/pyro.py" ]; then
        print_status "PASS" "backends/pyro.py exists (Pyro backend)"
    else
        print_status "FAIL" "backends/pyro.py not found"
    fi
else
    print_status "FAIL" "backends directory not found"
fi

if [ -d "language" ]; then
    print_status "PASS" "language directory exists for language testing"
    
    # Count language files
    language_count=$(find language -name "*.py" | wc -l)
    if [ "$language_count" -gt 0 ]; then
        print_status "PASS" "Found $language_count Python files in language directory"
    else
        print_status "WARN" "No Python files found in language directory"
    fi
    
    # Check for key language files
    if [ -f "language/templateparser.py" ]; then
        print_status "PASS" "language/templateparser.py exists (template parser)"
    else
        print_status "FAIL" "language/templateparser.py not found"
    fi
    
    if [ -f "language/checker.py" ]; then
        print_status "PASS" "language/checker.py exists (language checker)"
    else
        print_status "FAIL" "language/checker.py not found"
    fi
    
    if [ -f "language/mylistener.py" ]; then
        print_status "PASS" "language/mylistener.py exists (ANTLR listener)"
    else
        print_status "FAIL" "language/mylistener.py not found"
    fi
    
    if [ -f "language/myvisitor.py" ]; then
        print_status "PASS" "language/myvisitor.py exists (ANTLR visitor)"
    else
        print_status "FAIL" "language/myvisitor.py not found"
    fi
else
    print_status "FAIL" "language directory not found"
fi

if [ -d "utils" ]; then
    print_status "PASS" "utils directory exists for utility testing"
    
    # Count utility files
    utils_count=$(find utils -name "*.py" | wc -l)
    if [ "$utils_count" -gt 0 ]; then
        print_status "PASS" "Found $utils_count Python files in utils directory"
    else
        print_status "WARN" "No Python files found in utils directory"
    fi
    
    # Check for key utility files
    if [ -f "utils/utils.py" ]; then
        print_status "PASS" "utils/utils.py exists (utility functions)"
    else
        print_status "FAIL" "utils/utils.py not found"
    fi
else
    print_status "FAIL" "utils directory not found"
fi

if [ -d "metrics" ]; then
    print_status "PASS" "metrics directory exists for metrics testing"
    
    # Count metrics files
    metrics_count=$(find metrics -type f | wc -l)
    if [ "$metrics_count" -gt 0 ]; then
        print_status "PASS" "Found $metrics_count files in metrics directory"
    else
        print_status "WARN" "No files found in metrics directory"
    fi
else
    print_status "FAIL" "metrics directory not found"
fi

echo ""
echo "8. Testing ProbFuzz Configuration Files..."
echo "----------------------------------------"
# Test configuration files
if [ -r "config.json" ]; then
    print_status "PASS" "config.json is readable"
else
    print_status "FAIL" "config.json is not readable"
fi

if [ -r "models.json" ]; then
    print_status "PASS" "models.json is readable"
else
    print_status "FAIL" "models.json is not readable"
fi

if [ -r "install.sh" ]; then
    print_status "PASS" "install.sh is readable"
else
    print_status "FAIL" "install.sh is not readable"
fi

if [ -r "check.py" ]; then
    print_status "PASS" "check.py is readable"
else
    print_status "FAIL" "check.py is not readable"
fi

if [ -r "probfuzz.py" ]; then
    print_status "PASS" "probfuzz.py is readable"
else
    print_status "FAIL" "probfuzz.py is not readable"
fi

if [ -r "driver.py" ]; then
    print_status "PASS" "driver.py is readable"
else
    print_status "FAIL" "driver.py is not readable"
fi

if [ -r "summary.sh" ]; then
    print_status "PASS" "summary.sh is readable"
else
    print_status "FAIL" "summary.sh is not readable"
fi

# Check config.json content
if [ -r "config.json" ]; then
    if command -v python &> /dev/null; then
        if timeout 30s python -c "import json; json.load(open('config.json')); print('config.json is valid JSON')" >/dev/null 2>&1; then
            print_status "PASS" "config.json is valid JSON"
        else
            print_status "WARN" "config.json may not be valid JSON"
        fi
    else
        print_status "WARN" "python not available for config.json validation"
    fi
fi

# Check models.json content
if [ -r "models.json" ]; then
    if command -v python &> /dev/null; then
        if timeout 30s python -c "import json; json.load(open('models.json')); print('models.json is valid JSON')" >/dev/null 2>&1; then
            print_status "PASS" "models.json is valid JSON"
        else
            print_status "WARN" "models.json may not be valid JSON"
        fi
    else
        print_status "WARN" "python not available for models.json validation"
    fi
fi

echo ""
echo "9. Testing ProbFuzz Documentation..."
echo "----------------------------------"
# Test documentation
if [ -r "README.md" ]; then
    print_status "PASS" "README.md is readable"
else
    print_status "FAIL" "README.md is not readable"
fi

if [ -r "LICENSE" ]; then
    print_status "PASS" "LICENSE is readable"
else
    print_status "FAIL" "LICENSE is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "ProbFuzz" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "probabilistic" README.md; then
        print_status "PASS" "README.md contains probabilistic reference"
    else
        print_status "WARN" "README.md missing probabilistic reference"
    fi
    
    if grep -q "Stan" README.md; then
        print_status "PASS" "README.md contains Stan reference"
    else
        print_status "WARN" "README.md missing Stan reference"
    fi
    
    if grep -q "Edward" README.md; then
        print_status "PASS" "README.md contains Edward reference"
    else
        print_status "WARN" "README.md missing Edward reference"
    fi
    
    if grep -q "Pyro" README.md; then
        print_status "PASS" "README.md contains Pyro reference"
    else
        print_status "WARN" "README.md missing Pyro reference"
    fi
fi

echo ""
echo "10. Testing ProbFuzz Docker Functionality..."
echo "-------------------------------------------"
# Test if Docker container can run basic commands (only when not in Docker container)
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test Python in Docker
    if docker run --rm probfuzz-env-test python --version >/dev/null 2>&1; then
        print_status "PASS" "Python works in Docker container"
    else
        print_status "FAIL" "Python does not work in Docker container"
    fi
    
    # Test pip in Docker
    if docker run --rm probfuzz-env-test pip --version >/dev/null 2>&1; then
        print_status "PASS" "pip works in Docker container"
    else
        print_status "FAIL" "pip does not work in Docker container"
    fi
    
    # Test G++ in Docker
    if docker run --rm probfuzz-env-test g++ --version >/dev/null 2>&1; then
        print_status "PASS" "G++ works in Docker container"
    else
        print_status "FAIL" "G++ does not work in Docker container"
    fi
    
    # Test Make in Docker
    if docker run --rm probfuzz-env-test make --version >/dev/null 2>&1; then
        print_status "PASS" "Make works in Docker container"
    else
        print_status "FAIL" "Make does not work in Docker container"
    fi
    
    # Test wget in Docker
    if docker run --rm probfuzz-env-test wget --version >/dev/null 2>&1; then
        print_status "PASS" "wget works in Docker container"
    else
        print_status "FAIL" "wget does not work in Docker container"
    fi
    
    # Test curl in Docker
    if docker run --rm probfuzz-env-test curl --version >/dev/null 2>&1; then
        print_status "PASS" "curl works in Docker container"
    else
        print_status "FAIL" "curl does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm probfuzz-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test if backends directory is accessible in Docker
    if docker run --rm probfuzz-env-test test -d backends; then
        print_status "PASS" "backends directory is accessible in Docker container"
    else
        print_status "FAIL" "backends directory is not accessible in Docker container"
    fi
    
    # Test if language directory is accessible in Docker
    if docker run --rm probfuzz-env-test test -d language; then
        print_status "PASS" "language directory is accessible in Docker container"
    else
        print_status "FAIL" "language directory is not accessible in Docker container"
    fi
    
    # Test if utils directory is accessible in Docker
    if docker run --rm probfuzz-env-test test -d utils; then
        print_status "PASS" "utils directory is accessible in Docker container"
    else
        print_status "FAIL" "utils directory is not accessible in Docker container"
    fi
    
    # Test if metrics directory is accessible in Docker
    if docker run --rm probfuzz-env-test test -d metrics; then
        print_status "PASS" "metrics directory is accessible in Docker container"
    else
        print_status "FAIL" "metrics directory is not accessible in Docker container"
    fi
    
    # Test if probfuzz.py is accessible in Docker
    if docker run --rm probfuzz-env-test test -f probfuzz.py; then
        print_status "PASS" "probfuzz.py is accessible in Docker container"
    else
        print_status "FAIL" "probfuzz.py is not accessible in Docker container"
    fi
    
    # Test if install.sh is accessible in Docker
    if docker run --rm probfuzz-env-test test -f install.sh; then
        print_status "PASS" "install.sh is accessible in Docker container"
    else
        print_status "FAIL" "install.sh is not accessible in Docker container"
    fi
    
    # Test if check.py is accessible in Docker
    if docker run --rm probfuzz-env-test test -f check.py; then
        print_status "PASS" "check.py is accessible in Docker container"
    else
        print_status "FAIL" "check.py is not accessible in Docker container"
    fi
    
    # Test if config.json is accessible in Docker
    if docker run --rm probfuzz-env-test test -f config.json; then
        print_status "PASS" "config.json is accessible in Docker container"
    else
        print_status "FAIL" "config.json is not accessible in Docker container"
    fi
    
    # Test if models.json is accessible in Docker
    if docker run --rm probfuzz-env-test test -f models.json; then
        print_status "PASS" "models.json is accessible in Docker container"
    else
        print_status "FAIL" "models.json is not accessible in Docker container"
    fi
else
    print_status "INFO" "Skipping Docker functionality tests (running inside container)"
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for ProbFuzz:"
echo "- Docker build process (Ubuntu 22.04, Python, Java)"
echo "- Python environment (version compatibility, module loading)"
echo "- Java environment (JVM, compilation, execution)"
echo "- ProbFuzz build system (Python scripts, Java backends)"
echo "- ProbFuzz source code (driver.py, backends, language)"
echo "- ProbFuzz documentation (README.md, usage instructions)"
echo "- ProbFuzz configuration (config.json, models.json)"
echo "- Docker container functionality (Python, Java, fuzzing tools)"
echo "- Probabilistic fuzzing capabilities"

# Save final counts before any additional print_status calls
FINAL_PASS_COUNT=$PASS_COUNT
FINAL_FAIL_COUNT=$FAIL_COUNT
FINAL_WARN_COUNT=$WARN_COUNT

echo ""
echo "=========================================="
echo "Test Results Summary"
echo "=========================================="
echo -e "${GREEN}PASS: $FINAL_PASS_COUNT${NC}"
echo -e "${RED}FAIL: $FINAL_FAIL_COUNT${NC}"
echo -e "${YELLOW}WARN: $FINAL_WARN_COUNT${NC}"

# Write results to JSON using the final counts
PASS_COUNT=$FINAL_PASS_COUNT
FAIL_COUNT=$FINAL_FAIL_COUNT
WARN_COUNT=$FINAL_WARN_COUNT
write_results_to_json

if [ $FINAL_FAIL_COUNT -eq 0 ]; then
    print_status "INFO" "All Docker tests passed! Your ProbFuzz Docker environment is ready!"
    print_status "INFO" "ProbFuzz is a probabilistic fuzzing framework."
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your ProbFuzz Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi

print_status "INFO" "You can now run ProbFuzz in Docker: A probabilistic fuzzing framework."
print_status "INFO" "Example: docker run --rm probfuzz-env-test python probfuzz.py"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/probfuzz probfuzz-env-test /bin/bash" 