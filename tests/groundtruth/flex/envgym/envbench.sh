#!/bin/bash

# FLEX Environment Benchmark Test Script
# This script tests the environment setup for FLEX: Fixing Flaky tests in Machine Learning Projects

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
    # Kill any background processes
    jobs -p | xargs -r kill
    # Remove temporary files
    rm -f docker_build.log
    # Stop and remove Docker container if running
    docker stop flex-env-test 2>/dev/null || true
    docker rm flex-env-test 2>/dev/null || true
    exit 0
}

# Set up signal handlers
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the flex project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t flex-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/flex" --entrypoint="" flex-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        # Source conda environment
        source /etc/profile
        # Use base environment since flex-env doesn't exist
        conda activate base
        cd /home/cc/EnvGym/data/flex
        bash envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "FLEX Environment Benchmark Test"
echo "=========================================="



echo "1. Checking System Dependencies..."
echo "--------------------------------"
# Check Python3
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>&1)
    print_status "PASS" "Python3 is available: $python_version"
    
    # Check Python version (should be 3.6-3.8)
    python_major=$(echo $python_version | cut -d' ' -f2 | cut -d'.' -f1)
    python_minor=$(echo $python_version | cut -d' ' -f2 | cut -d'.' -f2)
    if [ -n "$python_major" ] && [ "$python_major" -eq 3 ] && [ -n "$python_minor" ] && [ "$python_minor" -ge 6 ] && [ "$python_minor" -le 8 ]; then
        print_status "PASS" "Python version is 3.6-3.8 (compatible)"
    else
        print_status "WARN" "Python version should be 3.6-3.8 (found: $python_major.$python_minor)"
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

# Check R
if command -v R &> /dev/null; then
    r_version=$(R --version 2>&1 | head -n 1)
    print_status "PASS" "R is available: $r_version"
else
    print_status "WARN" "R is not available"
fi

# Check Rscript
if command -v Rscript &> /dev/null; then
    print_status "PASS" "Rscript is available"
else
    print_status "WARN" "Rscript is not available"
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

# Check build tools
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version 2>&1 | head -n 1)
    print_status "PASS" "GCC is available: $gcc_version"
else
    print_status "WARN" "GCC is not available"
fi

if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "Make is available: $make_version"
else
    print_status "WARN" "Make is not available"
fi

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "tool" ]; then
    print_status "PASS" "tool directory exists"
else
    print_status "FAIL" "tool directory not found"
fi

if [ -d "tool/src" ]; then
    print_status "PASS" "tool/src directory exists"
else
    print_status "FAIL" "tool/src directory not found"
fi

if [ -d "tool/scripts" ]; then
    print_status "PASS" "tool/scripts directory exists"
else
    print_status "FAIL" "tool/scripts directory not found"
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

if [ -f ".gitignore" ]; then
    print_status "PASS" ".gitignore exists"
else
    print_status "FAIL" ".gitignore not found"
fi

# Check tool files
if [ -f "tool/boundschecker.py" ]; then
    print_status "PASS" "tool/boundschecker.py exists"
else
    print_status "FAIL" "tool/boundschecker.py not found"
fi

if [ -f "tool/assertscraper.py" ]; then
    print_status "PASS" "tool/assertscraper.py exists"
else
    print_status "FAIL" "tool/assertscraper.py not found"
fi

if [ -f "tool/CompareDistribution.py" ]; then
    print_status "PASS" "tool/CompareDistribution.py exists"
else
    print_status "FAIL" "tool/CompareDistribution.py not found"
fi

if [ -f "tool/newbugs.csv" ]; then
    print_status "PASS" "tool/newbugs.csv exists"
else
    print_status "FAIL" "tool/newbugs.csv not found"
fi

# Check src files
if [ -f "tool/src/Config.py" ]; then
    print_status "PASS" "tool/src/Config.py exists"
else
    print_status "FAIL" "tool/src/Config.py not found"
fi

if [ -f "tool/src/TestDriver.py" ]; then
    print_status "PASS" "tool/src/TestDriver.py exists"
else
    print_status "FAIL" "tool/src/TestDriver.py not found"
fi

if [ -f "tool/src/TestInstrumentor.py" ]; then
    print_status "PASS" "tool/src/TestInstrumentor.py exists"
else
    print_status "FAIL" "tool/src/TestInstrumentor.py not found"
fi

if [ -f "tool/src/Util.py" ]; then
    print_status "PASS" "tool/src/Util.py exists"
else
    print_status "FAIL" "tool/src/Util.py not found"
fi

# Check script files
if [ -f "tool/scripts/general_setup.sh" ]; then
    print_status "PASS" "tool/scripts/general_setup.sh exists"
else
    print_status "FAIL" "tool/scripts/general_setup.sh not found"
fi

if [ -f "tool/scripts/get_setup_extras.py" ]; then
    print_status "PASS" "tool/scripts/get_setup_extras.py exists"
else
    print_status "FAIL" "tool/scripts/get_setup_extras.py not found"
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

# Check R environment
if [ -n "${R_HOME:-}" ]; then
    print_status "PASS" "R_HOME is set: $R_HOME"
else
    print_status "WARN" "R_HOME is not set"
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

if echo "$PATH" | grep -q "R"; then
    print_status "PASS" "R is in PATH"
else
    print_status "WARN" "R is not in PATH"
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
echo "6. Testing R Environment..."
echo "---------------------------"
# Test R
if command -v R &> /dev/null; then
    print_status "PASS" "R is available"
    
    # Test R execution
    if timeout 30s R --version >/dev/null 2>&1; then
        print_status "PASS" "R version command works"
    else
        print_status "WARN" "R version command failed"
    fi
    
    # Test Rscript
    if command -v Rscript &> /dev/null; then
        print_status "PASS" "Rscript is available"
        
        # Test Rscript execution
        if timeout 30s Rscript -e "print('Hello from R')" >/dev/null 2>&1; then
            print_status "PASS" "Rscript execution works"
        else
            print_status "WARN" "Rscript execution failed"
        fi
    else
        print_status "WARN" "Rscript is not available"
    fi
else
    print_status "WARN" "R is not available"
fi

echo ""
echo "7. Testing Package Installation..."
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
echo "8. Testing FLEX Dependencies..."
echo "-------------------------------"
# Test Python dependencies
if command -v python3 &> /dev/null; then
    # Test numpy
    if timeout 30s python3 -c "import numpy; print('NumPy version:', numpy.__version__)" >/dev/null 2>&1; then
        print_status "PASS" "NumPy is available"
    else
        print_status "WARN" "NumPy is not available"
    fi
    
    # Test scipy
    if timeout 30s python3 -c "import scipy; print('SciPy version:', scipy.__version__)" >/dev/null 2>&1; then
        print_status "PASS" "SciPy is available"
    else
        print_status "WARN" "SciPy is not available"
    fi
    
    # Test pandas
    if timeout 30s python3 -c "import pandas; print('Pandas version:', pandas.__version__)" >/dev/null 2>&1; then
        print_status "PASS" "Pandas is available"
    else
        print_status "WARN" "Pandas is not available"
    fi
    
    # Test statsmodels
    if timeout 30s python3 -c "import statsmodels; print('Statsmodels available')" >/dev/null 2>&1; then
        print_status "PASS" "Statsmodels is available"
    else
        print_status "WARN" "Statsmodels is not available"
    fi
    
    # Test hyperopt
    if timeout 30s python3 -c "import hyperopt; print('Hyperopt available')" >/dev/null 2>&1; then
        print_status "PASS" "Hyperopt is available"
    else
        print_status "WARN" "Hyperopt is not available"
    fi
    
    # Test arviz
    if timeout 30s python3 -c "import arviz; print('ArviZ available')" >/dev/null 2>&1; then
        print_status "PASS" "ArviZ is available"
    else
        print_status "WARN" "ArviZ is not available"
    fi
    
    # Test astunparse
    if timeout 30s python3 -c "import astunparse; print('Astunparse available')" >/dev/null 2>&1; then
        print_status "PASS" "Astunparse is available"
    else
        print_status "WARN" "Astunparse is not available"
    fi
    
    # Test rpy2
    if timeout 30s python3 -c "import rpy2; print('Rpy2 available')" >/dev/null 2>&1; then
        print_status "PASS" "Rpy2 is available"
    else
        print_status "WARN" "Rpy2 is not available"
    fi
else
    print_status "WARN" "python3 not available for dependency testing"
fi

# Test R packages
if command -v Rscript &> /dev/null; then
    # Test R base
    if timeout 30s Rscript -e "print('R base available')" >/dev/null 2>&1; then
        print_status "PASS" "R base is available"
    else
        print_status "WARN" "R base is not available"
    fi
    
    # Test eva package
    if timeout 30s Rscript -e "library(eva); print('eva package available')" >/dev/null 2>&1; then
        print_status "PASS" "eva package is available"
    else
        print_status "WARN" "eva package is not available"
    fi
else
    print_status "WARN" "Rscript not available for R package testing"
fi

echo ""
echo "9. Testing FLEX Scripts..."
echo "---------------------------"
# Test general_setup.sh script
if [ -f "tool/scripts/general_setup.sh" ] && [ -x "tool/scripts/general_setup.sh" ]; then
    print_status "PASS" "tool/scripts/general_setup.sh exists and is executable"
else
    print_status "WARN" "tool/scripts/general_setup.sh not found or not executable"
fi

# Test if scripts can be made executable
if [ -f "tool/scripts/general_setup.sh" ]; then
    if chmod +x tool/scripts/general_setup.sh 2>/dev/null; then
        print_status "PASS" "tool/scripts/general_setup.sh can be made executable"
    else
        print_status "WARN" "tool/scripts/general_setup.sh cannot be made executable"
    fi
fi

# Test boundschecker.py
if [ -f "tool/boundschecker.py" ]; then
    print_status "PASS" "tool/boundschecker.py exists"
    
    # Test if it can be executed
    if command -v python3 &> /dev/null; then
        if timeout 30s python3 -c "import sys; sys.path.append('tool'); exec(open('tool/boundschecker.py').read())" >/dev/null 2>&1; then
            print_status "PASS" "tool/boundschecker.py can be executed"
        else
            print_status "WARN" "tool/boundschecker.py execution failed"
        fi
    else
        print_status "WARN" "python3 not available for script execution test"
    fi
else
    print_status "FAIL" "tool/boundschecker.py not found"
fi

# Test assertscraper.py
if [ -f "tool/assertscraper.py" ]; then
    print_status "PASS" "tool/assertscraper.py exists"
else
    print_status "FAIL" "tool/assertscraper.py not found"
fi

# Test CompareDistribution.py
if [ -f "tool/CompareDistribution.py" ]; then
    print_status "PASS" "tool/CompareDistribution.py exists"
else
    print_status "FAIL" "tool/CompareDistribution.py not found"
fi

echo ""
echo "10. Testing FLEX Python Modules..."
echo "-----------------------------------"
# Test if FLEX modules can be imported
if command -v python3 &> /dev/null; then
    # Test Config.py
    if [ -f "tool/src/Config.py" ]; then
        if timeout 30s python3 -c "import sys; sys.path.append('tool/src'); import Config; print('Config module imported')" >/dev/null 2>&1; then
            print_status "PASS" "Config module can be imported"
        else
            print_status "WARN" "Config module import failed"
        fi
    else
        print_status "FAIL" "Config.py not found"
    fi
    
    # Test TestDriver.py
    if [ -f "tool/src/TestDriver.py" ]; then
        if timeout 30s python3 -c "import sys; sys.path.append('tool/src'); import TestDriver; print('TestDriver module imported')" >/dev/null 2>&1; then
            print_status "PASS" "TestDriver module can be imported"
        else
            print_status "WARN" "TestDriver module import failed"
        fi
    else
        print_status "FAIL" "TestDriver.py not found"
    fi
    
    # Test TestInstrumentor.py
    if [ -f "tool/src/TestInstrumentor.py" ]; then
        if timeout 30s python3 -c "import sys; sys.path.append('tool/src'); import TestInstrumentor; print('TestInstrumentor module imported')" >/dev/null 2>&1; then
            print_status "PASS" "TestInstrumentor module can be imported"
        else
            print_status "WARN" "TestInstrumentor module import failed"
        fi
    else
        print_status "FAIL" "TestInstrumentor.py not found"
    fi
    
    # Test Util.py
    if [ -f "tool/src/Util.py" ]; then
        if timeout 30s python3 -c "import sys; sys.path.append('tool/src'); import Util; print('Util module imported')" >/dev/null 2>&1; then
            print_status "PASS" "Util module can be imported"
        else
            print_status "WARN" "Util module import failed"
        fi
    else
        print_status "FAIL" "Util.py not found"
    fi
else
    print_status "WARN" "python3 not available for module testing"
fi

echo ""
echo "11. Testing Data Files..."
echo "-------------------------"
# Test if data files exist
if [ -f "tool/newbugs.csv" ]; then
    print_status "PASS" "tool/newbugs.csv exists"
    
    # Test if file is readable and has content
    if [ -r "tool/newbugs.csv" ] && [ -s "tool/newbugs.csv" ]; then
        print_status "PASS" "tool/newbugs.csv is readable and has content"
    else
        print_status "WARN" "tool/newbugs.csv is not readable or empty"
    fi
else
    print_status "FAIL" "tool/newbugs.csv not found"
fi

echo ""
echo "12. Testing Virtual Environment..."
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
echo "13. Testing Documentation..."
echo "----------------------------"
# Test if documentation files are readable
if [ -r "README.md" ]; then
    print_status "PASS" "README.md is readable"
else
    print_status "WARN" "README.md is not readable"
fi

if [ -r ".gitignore" ]; then
    print_status "PASS" ".gitignore is readable"
else
    print_status "WARN" ".gitignore is not readable"
fi

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (Python3 3.6-3.8, pip3, conda, R, Rscript, git, bash)"
echo "- Project structure (tool/, tool/src/, tool/scripts/)"
echo "- Environment variables (PYTHONPATH, VIRTUAL_ENV, CONDA_DEFAULT_ENV, R_HOME, PATH)"
echo "- Python environment (python3, import system)"
echo "- Package management (pip3, conda)"
echo "- R environment (R, Rscript)"
echo "- Package installation (requirements.txt)"
echo "- FLEX dependencies (NumPy, SciPy, Pandas, Statsmodels, Hyperopt, ArviZ, Astunparse, Rpy2, R eva)"
echo "- FLEX scripts (general_setup.sh, boundschecker.py, assertscraper.py)"
echo "- FLEX Python modules (Config, TestDriver, TestInstrumentor, Util)"
echo "- Data files (newbugs.csv)"
echo "- Virtual environment (venv module)"
echo "- Documentation (README.md, .gitignore)"
echo "- Dockerfile structure (if Docker build failed)"

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
    print_status "INFO" "All tests passed! Your FLEX environment is ready!"
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your FLEX environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi

print_status "INFO" "You can now run FLEX: Fixing Flaky tests in Machine Learning Projects."
print_status "INFO" "Example: cd tool && python boundschecker.py -r coax -test test_update -file coax/coax/experience_replay/_prioritized_test.py -line 137 -conda coax -deps 'numpy' -bc"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/flex flex-env-test /bin/bash" 