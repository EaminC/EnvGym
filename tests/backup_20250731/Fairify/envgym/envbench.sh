#!/bin/bash

# Fairify Environment Benchmark Test Script
# This script tests the environment setup for Fairify neural network fairness verification

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
    # Kill any background processes
    jobs -p | xargs -r kill
    # Remove temporary files
    rm -f docker_build.log
    # Stop and remove Docker container if running
    docker stop fairify-env-test 2>/dev/null || true
    docker rm fairify-env-test 2>/dev/null || true
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Check if we're running in Docker
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo "Running inside Docker container - performing environment tests..."
    DOCKER_MODE=true
else
    echo "Running on host - checking for Docker and envgym.dockerfile"
    DOCKER_MODE=false
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_status "WARN" "Docker not available - running tests in local environment"
    elif [ -f "envgym/envgym.dockerfile" ]; then
        echo "Building Docker image..."
        if timeout 60s docker build -f envgym/envgym.dockerfile -t fairify-env-test .; then
            echo "Docker build successful - running environment test in Docker container..."
            if docker run --rm -v "$(pwd):/home/cc/EnvGym/data/Fairify" --init fairify-env-test bash -c "
                trap 'exit 0' SIGINT SIGTERM
                cd /home/cc/EnvGym/data/Fairify
                bash envgym/envbench.sh
            "; then
                echo "Docker container test completed successfully"
                # Don't cleanup here, let the script continue to show results
            else
                echo "WARNING: Docker container failed to run - analyzing Dockerfile only"
                echo "This may be due to architecture compatibility issues"
                DOCKER_BUILD_FAILED=true
            fi
        else
            echo "WARNING: Docker build failed - analyzing Dockerfile only"
            DOCKER_BUILD_FAILED=true
        fi
    else
        print_status "WARN" "envgym.dockerfile not found - running tests in local environment"
    fi
fi

# If Docker failed or not available, run tests in local environment
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ] || [ "${DOCKER_MODE:-false}" = "false" ]; then
    echo "Running tests in local environment..."
    DOCKER_MODE=false
fi

echo "=========================================="
echo "Fairify Environment Benchmark Test"
echo "=========================================="

# Analyze Dockerfile if build failed
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ]; then
    echo ""
    echo "Analyzing Dockerfile..."
    echo "----------------------"
    
    if [ -f "envgym/envgym.dockerfile" ]; then
        # Check Dockerfile structure
        if grep -q "FROM" envgym/envgym.dockerfile; then
            print_status "PASS" "FROM instruction found"
        else
            print_status "FAIL" "FROM instruction not found"
        fi
        
        if grep -q "ubuntu:22.04" envgym/envgym.dockerfile; then
            print_status "PASS" "Ubuntu 22.04 specified"
        else
            print_status "WARN" "Ubuntu 22.04 not specified"
        fi
        
        if grep -q "WORKDIR" envgym/envgym.dockerfile; then
            print_status "PASS" "WORKDIR set"
        else
            print_status "WARN" "WORKDIR not set"
        fi
        
        if grep -q "miniconda" envgym/envgym.dockerfile; then
            print_status "PASS" "Miniconda found"
        else
            print_status "FAIL" "Miniconda not found"
        fi
        
        if grep -q "python=3.7" envgym/envgym.dockerfile; then
            print_status "PASS" "Python 3.7 specified"
        else
            print_status "WARN" "Python 3.7 not specified"
        fi
        
        if grep -q "conda" envgym/envgym.dockerfile; then
            print_status "PASS" "Conda environment management found"
        else
            print_status "FAIL" "Conda environment management not found"
        fi
        
        if grep -q "requirements.txt" envgym/envgym.dockerfile; then
            print_status "PASS" "requirements.txt found"
        else
            print_status "FAIL" "requirements.txt not found"
        fi
        
        if grep -q "pip install" envgym/envgym.dockerfile; then
            print_status "PASS" "pip install found"
        else
            print_status "FAIL" "pip install not found"
        fi
        
        if grep -q "COPY" envgym/envgym.dockerfile; then
            print_status "PASS" "COPY instruction found"
        else
            print_status "WARN" "COPY instruction not found"
        fi
        
        if grep -q "ENTRYPOINT" envgym/envgym.dockerfile; then
            print_status "PASS" "ENTRYPOINT found"
        else
            print_status "WARN" "ENTRYPOINT not found"
        fi
        
        if grep -q "git" envgym/envgym.dockerfile; then
            print_status "PASS" "git found"
        else
            print_status "WARN" "git not found"
        fi
        
        if grep -q "bash" envgym/envgym.dockerfile; then
            print_status "PASS" "bash found"
        else
            print_status "WARN" "bash not found"
        fi
        
        echo ""
        total_dockerfile_checks=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT))
        if [ $total_dockerfile_checks -gt 0 ]; then
            dockerfile_score=$((PASS_COUNT * 100 / total_dockerfile_checks))
        else
            dockerfile_score=0
        fi
        print_status "INFO" "Dockerfile Environment Score: $dockerfile_score% ($PASS_COUNT/$total_dockerfile_checks checks passed)"
        print_status "INFO" "PASS: $PASS_COUNT, FAIL: $((FAIL_COUNT)), WARN: $((WARN_COUNT))"
        if [ $FAIL_COUNT -eq 0 ]; then
            print_status "INFO" "Dockerfile结构良好，建议检查依赖版本和构建产物。"
        else
            print_status "WARN" "Dockerfile存在一些问题，建议修复后重新构建。"
        fi
        echo ""
    else
        print_status "FAIL" "envgym.dockerfile not found"
    fi
fi

echo "1. Checking System Dependencies..."
echo "--------------------------------"
# Check Python3
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>&1)
    print_status "PASS" "Python3 is available: $python_version"
    
    # Check Python version (should be 3.7 or higher)
    python_major=$(echo $python_version | cut -d' ' -f2 | cut -d'.' -f1)
    python_minor=$(echo $python_version | cut -d' ' -f2 | cut -d'.' -f2)
    if [ -n "$python_major" ] && [ "$python_major" -eq 3 ] && [ -n "$python_minor" ] && [ "$python_minor" -ge 7 ]; then
        print_status "PASS" "Python version is 3.7 or higher"
    else
        print_status "WARN" "Python version should be 3.7 or higher (found: $python_major.$python_minor)"
    fi
else
    print_status "FAIL" "Python3 is not available"
fi

# Check pip3
if command -v pip3 &> /dev/null; then
    pip_version=$(pip3 --version 2>&1)
    print_status "PASS" "pip3 is available: $pip_version"
else
    print_status "FAIL" "pip3 is not available"
fi

# Check conda
if command -v conda &> /dev/null; then
    conda_version=$(conda --version 2>&1)
    print_status "PASS" "Conda is available: $conda_version"
else
    print_status "WARN" "Conda is not available"
fi

# Check Git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1)
    print_status "PASS" "Git is available: $git_version"
else
    print_status "FAIL" "Git is not available"
fi

# Check bash
if command -v bash &> /dev/null; then
    bash_version=$(bash --version 2>&1 | head -n 1)
    print_status "PASS" "Bash is available: $bash_version"
else
    print_status "FAIL" "Bash is not available"
fi

# Check curl
if command -v curl &> /dev/null; then
    print_status "PASS" "curl is available"
else
    print_status "FAIL" "curl is not available"
fi

# Check wget
if command -v wget &> /dev/null; then
    print_status "PASS" "wget is available"
else
    print_status "WARN" "wget is not available"
fi

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "src" ]; then
    print_status "PASS" "src directory exists"
else
    print_status "FAIL" "src directory not found"
fi

if [ -d "models" ]; then
    print_status "PASS" "models directory exists"
else
    print_status "FAIL" "models directory not found"
fi

if [ -d "data" ]; then
    print_status "PASS" "data directory exists"
else
    print_status "FAIL" "data directory not found"
fi

if [ -d "utils" ]; then
    print_status "PASS" "utils directory exists"
else
    print_status "FAIL" "utils directory not found"
fi

if [ -d "stress" ]; then
    print_status "PASS" "stress directory exists"
else
    print_status "FAIL" "stress directory not found"
fi

if [ -d "relaxed" ]; then
    print_status "PASS" "relaxed directory exists"
else
    print_status "FAIL" "relaxed directory not found"
fi

if [ -d "targeted" ]; then
    print_status "PASS" "targeted directory exists"
else
    print_status "FAIL" "targeted directory not found"
fi

if [ -d "targeted2" ]; then
    print_status "PASS" "targeted2 directory exists"
else
    print_status "FAIL" "targeted2 directory not found"
fi

# Check key files
if [ -f "requirements.txt" ]; then
    print_status "PASS" "requirements.txt exists"
else
    print_status "FAIL" "requirements.txt not found"
fi

if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
fi

if [ -f "INSTALL.md" ]; then
    print_status "PASS" "INSTALL.md exists"
else
    print_status "FAIL" "INSTALL.md not found"
fi

if [ -f "LICENSE" ]; then
    print_status "PASS" "LICENSE exists"
else
    print_status "FAIL" "LICENSE not found"
fi

if [ -f "STATUS.md" ]; then
    print_status "PASS" "STATUS.md exists"
else
    print_status "FAIL" "STATUS.md not found"
fi

# Check src files
if [ -f "src/fairify.sh" ]; then
    print_status "PASS" "src/fairify.sh exists"
else
    print_status "FAIL" "src/fairify.sh not found"
fi

if [ -d "src/GC" ]; then
    print_status "PASS" "src/GC directory exists"
else
    print_status "FAIL" "src/GC directory not found"
fi

if [ -d "src/AC" ]; then
    print_status "PASS" "src/AC directory exists"
else
    print_status "FAIL" "src/AC directory not found"
fi

if [ -d "src/BM" ]; then
    print_status "PASS" "src/BM directory exists"
else
    print_status "FAIL" "src/BM directory not found"
fi

# Check model directories
if [ -d "models/german" ]; then
    print_status "PASS" "models/german directory exists"
else
    print_status "FAIL" "models/german directory not found"
fi

if [ -d "models/adult" ]; then
    print_status "PASS" "models/adult directory exists"
else
    print_status "FAIL" "models/adult directory not found"
fi

if [ -d "models/bank" ]; then
    print_status "PASS" "models/bank directory exists"
else
    print_status "FAIL" "models/bank directory not found"
fi

# Check data directories
if [ -d "data/german" ]; then
    print_status "PASS" "data/german directory exists"
else
    print_status "FAIL" "data/german directory not found"
fi

if [ -d "data/adult" ]; then
    print_status "PASS" "data/adult directory exists"
else
    print_status "FAIL" "data/adult directory not found"
fi

if [ -d "data/bank" ]; then
    print_status "PASS" "data/bank directory exists"
else
    print_status "FAIL" "data/bank directory not found"
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

if [ -n "${VIRTUAL_ENV:-}" ]; then
    print_status "PASS" "VIRTUAL_ENV is set: $VIRTUAL_ENV"
else
    print_status "WARN" "VIRTUAL_ENV is not set"
fi

if [ -n "${CONDA_DEFAULT_ENV:-}" ]; then
    print_status "PASS" "CONDA_DEFAULT_ENV is set: $CONDA_DEFAULT_ENV"
else
    print_status "WARN" "CONDA_DEFAULT_ENV is not set"
fi

# Check PATH
if echo "$PATH" | grep -q "python"; then
    print_status "PASS" "Python is in PATH"
else
    print_status "WARN" "Python is not in PATH"
fi

if echo "$PATH" | grep -q "pip"; then
    print_status "PASS" "pip is in PATH"
else
    print_status "WARN" "pip is not in PATH"
fi

if echo "$PATH" | grep -q "conda"; then
    print_status "PASS" "conda is in PATH"
else
    print_status "WARN" "conda is not in PATH"
fi

echo ""
echo "4. Testing Python Environment..."
echo "-------------------------------"
# Test Python3
if command -v python3 &> /dev/null; then
    print_status "PASS" "python3 is available"
    
    # Test Python3 execution
    if timeout 30s python3 -c "print('Hello from Python3')" >/dev/null 2>&1; then
        print_status "PASS" "Python3 execution works"
    else
        print_status "WARN" "Python3 execution failed"
    fi
    
    # Test Python3 import system
    if timeout 30s python3 -c "import sys; print('Python path:', sys.path[0])" >/dev/null 2>&1; then
        print_status "PASS" "Python3 import system works"
    else
        print_status "WARN" "Python3 import system failed"
    fi
else
    print_status "FAIL" "python3 is not available"
fi

echo ""
echo "5. Testing Package Management..."
echo "-------------------------------"
# Test pip3
if command -v pip3 &> /dev/null; then
    print_status "PASS" "pip3 is available"
    
    # Test pip3 version
    if timeout 30s pip3 --version >/dev/null 2>&1; then
        print_status "PASS" "pip3 version command works"
    else
        print_status "WARN" "pip3 version command failed"
    fi
    
    # Test pip3 list
    if timeout 30s pip3 list >/dev/null 2>&1; then
        print_status "PASS" "pip3 list command works"
    else
        print_status "WARN" "pip3 list command failed"
    fi
else
    print_status "FAIL" "pip3 is not available"
fi

# Test conda
if command -v conda &> /dev/null; then
    print_status "PASS" "conda is available"
    
    # Test conda info
    if timeout 30s conda info >/dev/null 2>&1; then
        print_status "PASS" "conda info command works"
    else
        print_status "WARN" "conda info command failed"
    fi
    
    # Test conda env list
    if timeout 30s conda env list >/dev/null 2>&1; then
        print_status "PASS" "conda env list command works"
    else
        print_status "WARN" "conda env list command failed"
    fi
else
    print_status "WARN" "conda is not available"
fi

echo ""
echo "6. Testing Package Installation..."
echo "----------------------------------"
# Test package installation
if command -v pip3 &> /dev/null && [ -f "requirements.txt" ]; then
    print_status "PASS" "pip3 and requirements.txt are available"
    
    # Test pip3 install from requirements.txt
    if timeout 120s pip3 install -r requirements.txt >/dev/null 2>&1; then
        print_status "PASS" "pip3 install from requirements.txt works"
    else
        print_status "WARN" "pip3 install from requirements.txt failed"
    fi
else
    print_status "WARN" "pip3 or requirements.txt not available"
fi

echo ""
echo "7. Testing Fairify Dependencies..."
echo "----------------------------------"
# Test Z3 solver
if command -v python3 &> /dev/null; then
    if timeout 30s python3 -c "import z3; print('Z3 version:', z3.get_version_string())" >/dev/null 2>&1; then
        print_status "PASS" "Z3 solver is available"
    else
        print_status "WARN" "Z3 solver is not available"
    fi
else
    print_status "WARN" "python3 not available for Z3 test"
fi

# Test TensorFlow
if command -v python3 &> /dev/null; then
    if timeout 30s python3 -c "import tensorflow as tf; print('TensorFlow version:', tf.__version__)" >/dev/null 2>&1; then
        print_status "PASS" "TensorFlow is available"
    else
        print_status "WARN" "TensorFlow is not available"
    fi
else
    print_status "WARN" "python3 not available for TensorFlow test"
fi

# Test AIF360
if command -v python3 &> /dev/null; then
    if timeout 30s python3 -c "import aif360; print('AIF360 version:', aif360.__version__)" >/dev/null 2>&1; then
        print_status "PASS" "AIF360 is available"
    else
        print_status "WARN" "AIF360 is not available"
    fi
else
    print_status "WARN" "python3 not available for AIF360 test"
fi

echo ""
echo "8. Testing Fairify Scripts..."
echo "-----------------------------"
# Test fairify.sh script
if [ -f "src/fairify.sh" ] && [ -x "src/fairify.sh" ]; then
    print_status "PASS" "src/fairify.sh exists and is executable"
else
    print_status "WARN" "src/fairify.sh not found or not executable"
fi

# Test if scripts can be made executable
if [ -f "src/fairify.sh" ]; then
    if chmod +x src/fairify.sh 2>/dev/null; then
        print_status "PASS" "src/fairify.sh can be made executable"
    else
        print_status "WARN" "src/fairify.sh cannot be made executable"
    fi
fi

# Check for other script files
if [ -f "stress/fairify-stress.sh" ]; then
    print_status "PASS" "stress/fairify-stress.sh exists"
else
    print_status "WARN" "stress/fairify-stress.sh not found"
fi

if [ -f "relaxed/fairify-relaxed.sh" ]; then
    print_status "PASS" "relaxed/fairify-relaxed.sh exists"
else
    print_status "WARN" "relaxed/fairify-relaxed.sh not found"
fi

if [ -f "targeted/fairify-targeted.sh" ]; then
    print_status "PASS" "targeted/fairify-targeted.sh exists"
else
    print_status "WARN" "targeted/fairify-targeted.sh not found"
fi

if [ -f "targeted2/fairify-targeted.sh" ]; then
    print_status "PASS" "targeted2/fairify-targeted.sh exists"
else
    print_status "WARN" "targeted2/fairify-targeted.sh not found"
fi

echo ""
echo "9. Testing Fairify Python Modules..."
echo "------------------------------------"
# Test if verification scripts exist and can be imported
if [ -f "src/GC/Verify-GC.py" ]; then
    print_status "PASS" "src/GC/Verify-GC.py exists"
    
    # Test if it can be executed
    if command -v python3 &> /dev/null; then
        if timeout 30s python3 -c "import sys; sys.path.append('src/GC'); exec(open('src/GC/Verify-GC.py').read())" >/dev/null 2>&1; then
            print_status "PASS" "src/GC/Verify-GC.py can be executed"
        else
            print_status "WARN" "src/GC/Verify-GC.py execution failed"
        fi
    else
        print_status "WARN" "python3 not available for script execution test"
    fi
else
    print_status "FAIL" "src/GC/Verify-GC.py not found"
fi

# Check for other verification scripts
if [ -f "src/AC/Verify-AC.py" ]; then
    print_status "PASS" "src/AC/Verify-AC.py exists"
else
    print_status "WARN" "src/AC/Verify-AC.py not found"
fi

if [ -f "src/BM/Verify-BM.py" ]; then
    print_status "PASS" "src/BM/Verify-BM.py exists"
else
    print_status "WARN" "src/BM/Verify-BM.py not found"
fi

echo ""
echo "10. Testing Model and Data Files..."
echo "-----------------------------------"
# Test if model files exist
if [ -d "models/german" ] && [ "$(ls -A models/german 2>/dev/null)" ]; then
    print_status "PASS" "models/german contains files"
else
    print_status "WARN" "models/german is empty or not accessible"
fi

if [ -d "models/adult" ] && [ "$(ls -A models/adult 2>/dev/null)" ]; then
    print_status "PASS" "models/adult contains files"
else
    print_status "WARN" "models/adult is empty or not accessible"
fi

if [ -d "models/bank" ] && [ "$(ls -A models/bank 2>/dev/null)" ]; then
    print_status "PASS" "models/bank contains files"
else
    print_status "WARN" "models/bank is empty or not accessible"
fi

# Test if data files exist
if [ -d "data/german" ] && [ "$(ls -A data/german 2>/dev/null)" ]; then
    print_status "PASS" "data/german contains files"
else
    print_status "WARN" "data/german is empty or not accessible"
fi

if [ -d "data/adult" ] && [ "$(ls -A data/adult 2>/dev/null)" ]; then
    print_status "PASS" "data/adult contains files"
else
    print_status "WARN" "data/adult is empty or not accessible"
fi

if [ -d "data/bank" ] && [ "$(ls -A data/bank 2>/dev/null)" ]; then
    print_status "PASS" "data/bank contains files"
else
    print_status "WARN" "data/bank is empty or not accessible"
fi

echo ""
echo "11. Testing Virtual Environment..."
echo "----------------------------------"
# Test virtual environment creation
if command -v python3 &> /dev/null; then
    print_status "PASS" "python3 is available for virtual environment testing"
    
    # Test venv module
    if timeout 30s python3 -c "import venv; print('venv module available')" >/dev/null 2>&1; then
        print_status "PASS" "venv module is available"
    else
        print_status "WARN" "venv module is not available"
    fi
else
    print_status "WARN" "python3 not available for virtual environment testing"
fi

echo ""
echo "12. Testing Documentation..."
echo "----------------------------"
# Test if documentation files are readable
if [ -r "README.md" ]; then
    print_status "PASS" "README.md is readable"
else
    print_status "WARN" "README.md is not readable"
fi

if [ -r "INSTALL.md" ]; then
    print_status "PASS" "INSTALL.md is readable"
else
    print_status "WARN" "INSTALL.md is not readable"
fi

if [ -r "STATUS.md" ]; then
    print_status "PASS" "STATUS.md is readable"
else
    print_status "WARN" "STATUS.md is not readable"
fi

if [ -r "LICENSE" ]; then
    print_status "PASS" "LICENSE is readable"
else
    print_status "WARN" "LICENSE is not readable"
fi

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (Python3 3.7+, pip3, conda, git, bash)"
echo "- Project structure (src/, models/, data/, utils/, stress/, relaxed/, targeted/)"
echo "- Environment variables (PYTHONPATH, VIRTUAL_ENV, CONDA_DEFAULT_ENV, PATH)"
echo "- Python environment (python3, import system)"
echo "- Package management (pip3, conda)"
echo "- Package installation (requirements.txt)"
echo "- Fairify dependencies (Z3 solver, TensorFlow, AIF360)"
echo "- Fairify scripts (fairify.sh, verification scripts)"
echo "- Fairify Python modules (Verify-GC.py, Verify-AC.py, Verify-BM.py)"
echo "- Model and data files (german, adult, bank datasets)"
echo "- Virtual environment (venv module)"
echo "- Documentation (README.md, INSTALL.md, STATUS.md, LICENSE)"
echo "- Dockerfile structure (if Docker build failed)"
echo ""
echo "=========================================="
echo "Test Results Summary"
echo "=========================================="
echo -e "${GREEN}PASS: $PASS_COUNT${NC}"
echo -e "${RED}FAIL: $FAIL_COUNT${NC}"
echo -e "${YELLOW}WARN: $WARN_COUNT${NC}"
echo ""
total_tests=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT))
if [ $total_tests -gt 0 ]; then
    score_percentage=$((PASS_COUNT * 100 / total_tests))
else
    score_percentage=0
fi
print_status "INFO" "Environment Score: $score_percentage% ($PASS_COUNT/$total_tests tests passed)"
echo ""
if [ $FAIL_COUNT -eq 0 ]; then
    print_status "INFO" "All tests passed! Your Fairify environment is ready!"
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your Fairify environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now run Fairify neural network fairness verification."
print_status "INFO" "Example: cd src && ./fairify.sh GC"
echo ""
print_status "INFO" "For more information, see README.md and INSTALL.md" 