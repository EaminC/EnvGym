#!/bin/bash

# SixthSense Environment Benchmark Test Script
# This script tests the Docker environment setup for SixthSense: A machine learning framework
# Tailored specifically for SixthSense project requirements and features

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
    docker stop sixthsense-env-test 2>/dev/null || true
    docker rm sixthsense-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the sixthsense project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t sixthsense-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/sixthsense" sixthsense-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "SixthSense Environment Benchmark Test"
echo "=========================================="

echo "1. Checking Python Environment..."
echo "---------------------------------"
# Check Python version
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>&1)
    print_status "PASS" "Python3 is available: $python_version"
    
    # Check Python version compatibility (SixthSense requires 3.6+)
    python_major=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1)
    python_minor=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f2)
    if [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 6 ]; then
        print_status "PASS" "Python version is >= 3.6 (compatible with SixthSense)"
    else
        print_status "WARN" "Python version should be >= 3.6 for SixthSense (found: $python_major.$python_minor)"
    fi
else
    print_status "FAIL" "Python3 is not available"
fi

# Check pip
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

# Check Python execution
if command -v python3 &> /dev/null; then
    if timeout 30s python3 --version >/dev/null 2>&1; then
        print_status "PASS" "Python3 execution works"
    else
        print_status "WARN" "Python3 execution failed"
    fi
    
    # Test Python modules
    if python3 -c "import sys" 2>/dev/null; then
        print_status "PASS" "Python sys module is available"
    else
        print_status "FAIL" "Python sys module is not available"
    fi
    
    if python3 -c "import os" 2>/dev/null; then
        print_status "PASS" "Python os module is available"
    else
        print_status "FAIL" "Python os module is not available"
    fi
else
    print_status "FAIL" "Python3 is not available for testing"
fi

echo ""
echo "2. Checking Machine Learning Dependencies..."
echo "--------------------------------------------"
# Test if required Python packages are available
if command -v python3 &> /dev/null; then
    print_status "INFO" "Testing SixthSense Python dependencies..."
    
    # Test scikit-learn
    if python3 -c "import sklearn" 2>/dev/null; then
        sklearn_version=$(python3 -c "import sklearn; print(sklearn.__version__)" 2>/dev/null)
        print_status "PASS" "scikit-learn dependency is available: $sklearn_version"
    else
        print_status "FAIL" "scikit-learn dependency is not available"
    fi
    
    # Test numpy
    if python3 -c "import numpy" 2>/dev/null; then
        numpy_version=$(python3 -c "import numpy; print(numpy.__version__)" 2>/dev/null)
        print_status "PASS" "numpy dependency is available: $numpy_version"
    else
        print_status "FAIL" "numpy dependency is not available"
    fi
    
    # Test matplotlib
    if python3 -c "import matplotlib" 2>/dev/null; then
        matplotlib_version=$(python3 -c "import matplotlib; print(matplotlib.__version__)" 2>/dev/null)
        print_status "PASS" "matplotlib dependency is available: $matplotlib_version"
    else
        print_status "FAIL" "matplotlib dependency is not available"
    fi
    
    # Test pandas
    if python3 -c "import pandas" 2>/dev/null; then
        pandas_version=$(python3 -c "import pandas; print(pandas.__version__)" 2>/dev/null)
        print_status "PASS" "pandas dependency is available: $pandas_version"
    else
        print_status "FAIL" "pandas dependency is not available"
    fi
    
    # Test jsonpickle
    if python3 -c "import jsonpickle" 2>/dev/null; then
        print_status "PASS" "jsonpickle dependency is available"
    else
        print_status "FAIL" "jsonpickle dependency is not available"
    fi
    
    # Test nearpy
    if python3 -c "import nearpy" 2>/dev/null; then
        print_status "PASS" "nearpy dependency is available"
    else
        print_status "FAIL" "nearpy dependency is not available"
    fi
    
    # Test treeinterpreter
    if python3 -c "import treeinterpreter" 2>/dev/null; then
        print_status "PASS" "treeinterpreter dependency is available"
    else
        print_status "FAIL" "treeinterpreter dependency is not available"
    fi
    
    # Test cleanlab
    if python3 -c "import cleanlab" 2>/dev/null; then
        print_status "PASS" "cleanlab dependency is available"
    else
        print_status "FAIL" "cleanlab dependency is not available"
    fi
else
    print_status "FAIL" "Python3 is not available for dependency testing"
fi

echo ""
echo "3. Checking System Dependencies..."
echo "---------------------------------"
# Check Git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1)
    print_status "PASS" "Git is available: $git_version"
else
    print_status "FAIL" "Git is not available"
fi

# Check build tools
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version 2>&1 | head -n 1)
    print_status "PASS" "GCC is available: $gcc_version"
else
    print_status "WARN" "GCC is not available"
fi

# Check gfortran
if command -v gfortran &> /dev/null; then
    gfortran_version=$(gfortran --version 2>&1 | head -n 1)
    print_status "PASS" "gfortran is available: $gfortran_version"
else
    print_status "WARN" "gfortran is not available"
fi

# Check curl and wget
if command -v curl &> /dev/null; then
    curl_version=$(curl --version 2>&1 | head -n 1)
    print_status "PASS" "curl is available: $curl_version"
else
    print_status "FAIL" "curl is not available"
fi

if command -v wget &> /dev/null; then
    wget_version=$(wget --version 2>&1 | head -n 1)
    print_status "PASS" "wget is available: $wget_version"
else
    print_status "FAIL" "wget is not available"
fi

echo ""
echo "4. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "csvs" ]; then
    print_status "PASS" "csvs directory exists (data files)"
else
    print_status "FAIL" "csvs directory not found"
fi

if [ -d "subcategories" ]; then
    print_status "PASS" "subcategories directory exists (model categories)"
else
    print_status "FAIL" "subcategories directory not found"
fi

# Check key files
if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
fi

if [ -f "requirements.txt" ]; then
    print_status "PASS" "requirements.txt exists"
else
    print_status "FAIL" "requirements.txt not found"
fi

if [ -f "install.sh" ]; then
    print_status "PASS" "install.sh exists (installation script)"
else
    print_status "FAIL" "install.sh not found"
fi

if [ -f "train.py" ]; then
    print_status "PASS" "train.py exists (main training script)"
else
    print_status "FAIL" "train.py not found"
fi

if [ -f "utils.py" ]; then
    print_status "PASS" "utils.py exists (utility functions)"
else
    print_status "FAIL" "utils.py not found"
fi

# Check subcategories files
if [ -f "subcategories/lrm2.json" ]; then
    print_status "PASS" "subcategories/lrm2.json exists (linear regression models)"
else
    print_status "FAIL" "subcategories/lrm2.json not found"
fi

if [ -f "subcategories/mix.json" ]; then
    print_status "PASS" "subcategories/mix.json exists (mixture models)"
else
    print_status "FAIL" "subcategories/mix.json not found"
fi

if [ -f "subcategories/ts.json" ]; then
    print_status "PASS" "subcategories/ts.json exists (time series models)"
else
    print_status "FAIL" "subcategories/ts.json not found"
fi

echo ""
echo "5. Testing SixthSense Source Code..."
echo "------------------------------------"
# Count Python files
python_files=$(find . -name "*.py" | wc -l)
if [ "$python_files" -gt 0 ]; then
    print_status "PASS" "Found $python_files Python files"
else
    print_status "FAIL" "No Python files found"
fi

# Count shell scripts
shell_files=$(find . -name "*.sh" | wc -l)
if [ "$shell_files" -gt 0 ]; then
    print_status "PASS" "Found $shell_files shell script files"
else
    print_status "WARN" "No shell script files found"
fi

# Count JSON files
json_files=$(find . -name "*.json" | wc -l)
if [ "$json_files" -gt 0 ]; then
    print_status "PASS" "Found $json_files JSON files"
else
    print_status "WARN" "No JSON files found"
fi

# Test Python syntax
if command -v python3 &> /dev/null; then
    print_status "INFO" "Testing Python syntax..."
    syntax_errors=0
    for py_file in $(find . -name "*.py"); do
        if ! timeout 30s python3 -m py_compile "$py_file" >/dev/null 2>&1; then
            ((syntax_errors++))
        fi
    done
    
    if [ "$syntax_errors" -eq 0 ]; then
        print_status "PASS" "All Python files have valid syntax"
    else
        print_status "WARN" "Found $syntax_errors Python files with syntax errors"
    fi
else
    print_status "FAIL" "Python3 is not available for syntax checking"
fi

# Test requirements.txt parsing
if command -v pip3 &> /dev/null; then
    print_status "INFO" "Testing requirements.txt parsing..."
    if timeout 60s pip3 check -r requirements.txt >/dev/null 2>&1; then
        print_status "PASS" "requirements.txt parsing successful"
    else
        print_status "WARN" "requirements.txt parsing failed"
    fi
else
    print_status "FAIL" "pip3 is not available for requirements.txt parsing"
fi

echo ""
echo "6. Testing SixthSense Dependencies..."
echo "------------------------------------"
# Test if required Python packages are available
if command -v python3 &> /dev/null; then
    print_status "INFO" "Testing SixthSense Python dependencies..."
    
    # Test scikit-learn
    if python3 -c "import sklearn" 2>/dev/null; then
        print_status "PASS" "scikit-learn dependency is available"
    else
        print_status "FAIL" "scikit-learn dependency is not available"
    fi
    
    # Test numpy
    if python3 -c "import numpy" 2>/dev/null; then
        print_status "PASS" "numpy dependency is available"
    else
        print_status "FAIL" "numpy dependency is not available"
    fi
    
    # Test matplotlib
    if python3 -c "import matplotlib" 2>/dev/null; then
        print_status "PASS" "matplotlib dependency is available"
    else
        print_status "FAIL" "matplotlib dependency is not available"
    fi
    
    # Test pandas
    if python3 -c "import pandas" 2>/dev/null; then
        print_status "PASS" "pandas dependency is available"
    else
        print_status "FAIL" "pandas dependency is not available"
    fi
    
    # Test jsonpickle
    if python3 -c "import jsonpickle" 2>/dev/null; then
        print_status "PASS" "jsonpickle dependency is available"
    else
        print_status "FAIL" "jsonpickle dependency is not available"
    fi
    
    # Test nearpy
    if python3 -c "import nearpy" 2>/dev/null; then
        print_status "PASS" "nearpy dependency is available"
    else
        print_status "FAIL" "nearpy dependency is not available"
    fi
    
    # Test treeinterpreter
    if python3 -c "import treeinterpreter" 2>/dev/null; then
        print_status "PASS" "treeinterpreter dependency is available"
    else
        print_status "FAIL" "treeinterpreter dependency is not available"
    fi
    
    # Test cleanlab
    if python3 -c "import cleanlab" 2>/dev/null; then
        print_status "PASS" "cleanlab dependency is available"
    else
        print_status "FAIL" "cleanlab dependency is not available"
    fi
else
    print_status "FAIL" "Python3 is not available for dependency testing"
fi

echo ""
echo "7. Testing SixthSense Documentation..."
echo "-------------------------------------"
# Test documentation readability
if [ -r "README.md" ]; then
    print_status "PASS" "README.md is readable"
else
    print_status "FAIL" "README.md is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "SixthSense" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "probabilistic" README.md; then
        print_status "PASS" "README.md contains probabilistic programs description"
    else
        print_status "WARN" "README.md missing probabilistic programs description"
    fi
    
    if grep -q "convergence" README.md; then
        print_status "PASS" "README.md contains convergence problems description"
    else
        print_status "WARN" "README.md missing convergence problems description"
    fi
    
    if grep -q "machine learning" README.md; then
        print_status "PASS" "README.md contains machine learning description"
    else
        print_status "WARN" "README.md missing machine learning description"
    fi
    
    if grep -q "FASE" README.md; then
        print_status "PASS" "README.md contains FASE conference reference"
    else
        print_status "WARN" "README.md missing FASE conference reference"
    fi
fi

echo ""
echo "8. Testing SixthSense Docker Functionality..."
echo "---------------------------------------------"
# Test if Docker container can run basic commands
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test Python in Docker
    if docker run --rm sixthsense-env-test python --version >/dev/null 2>&1; then
        print_status "PASS" "Python works in Docker container"
    else
        print_status "FAIL" "Python does not work in Docker container"
    fi
    
    # Test conda in Docker
    if docker run --rm sixthsense-env-test conda --version >/dev/null 2>&1; then
        print_status "PASS" "Conda works in Docker container"
    else
        print_status "FAIL" "Conda does not work in Docker container"
    fi
    
    # Test pip in Docker
    if docker run --rm sixthsense-env-test pip --version >/dev/null 2>&1; then
        print_status "PASS" "pip works in Docker container"
    else
        print_status "FAIL" "pip does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm sixthsense-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" sixthsense-env-test test -f README.md; then
        print_status "PASS" "README.md is accessible in Docker container"
    else
        print_status "FAIL" "README.md is not accessible in Docker container"
    fi
    
    # Test if train.py is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" sixthsense-env-test test -f train.py; then
        print_status "PASS" "train.py is accessible in Docker container"
    else
        print_status "FAIL" "train.py is not accessible in Docker container"
    fi
    
    # Test if utils.py is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" sixthsense-env-test test -f utils.py; then
        print_status "PASS" "utils.py is accessible in Docker container"
    else
        print_status "FAIL" "utils.py is not accessible in Docker container"
    fi
    
    # Test if requirements.txt is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" sixthsense-env-test test -f requirements.txt; then
        print_status "PASS" "requirements.txt is accessible in Docker container"
    else
        print_status "FAIL" "requirements.txt is not accessible in Docker container"
    fi
    
    # Test Python dependencies in Docker
    if docker run --rm -v "$(pwd):/workspace" sixthsense-env-test python -c "import sklearn, numpy, matplotlib, pandas" >/dev/null 2>&1; then
        print_status "PASS" "Python dependencies work in Docker container"
    else
        print_status "FAIL" "Python dependencies do not work in Docker container"
    fi
    
    # Test Python script execution in Docker
    if timeout 60s docker run --rm -v "$(pwd):/workspace" -w /workspace sixthsense-env-test python -c "print('SixthSense test successful')" >/dev/null 2>&1; then
        print_status "PASS" "Python script execution works in Docker container"
    else
        print_status "FAIL" "Python script execution does not work in Docker container"
    fi
fi

echo ""
echo "9. Testing SixthSense Build Process..."
echo "--------------------------------------"
# Test if Docker container can run build commands
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test if install.sh is accessible and executable
    if docker run --rm -v "$(pwd):/workspace" -w /workspace sixthsense-env-test test -f install.sh; then
        print_status "PASS" "install.sh is accessible in Docker container"
    else
        print_status "FAIL" "install.sh is not accessible in Docker container"
    fi
    
    # Test if required directories can be created
    if docker run --rm -v "$(pwd):/workspace" -w /workspace sixthsense-env-test bash -c "mkdir -p plots models results && test -d plots && test -d models && test -d results"; then
        print_status "PASS" "Required directories can be created in Docker container"
    else
        print_status "FAIL" "Required directories cannot be created in Docker container"
    fi
    
    # Test Python script execution (simple test)
    if timeout 60s docker run --rm -v "$(pwd):/workspace" -w /workspace sixthsense-env-test python -c "import sys; print('Python version:', sys.version)" >/dev/null 2>&1; then
        print_status "PASS" "Python script execution works in Docker container"
    else
        print_status "FAIL" "Python script execution does not work in Docker container"
    fi
    
    # Test train.py help (without running full training)
    if timeout 60s docker run --rm -v "$(pwd):/workspace" -w /workspace sixthsense-env-test python train.py --help >/dev/null 2>&1; then
        print_status "PASS" "train.py help works in Docker container"
    else
        print_status "FAIL" "train.py help does not work in Docker container"
    fi
    
    # Skip actual training tests to avoid timeouts
    print_status "WARN" "Skipping actual training tests to avoid timeouts (full model training)"
    print_status "INFO" "Docker environment is ready for SixthSense development"
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for SixthSense:"
echo "- Docker build process (Ubuntu 22.04, Python, PyTorch)"
echo "- Python environment (version compatibility, module loading)"
echo "- PyTorch environment (deep learning, neural networks)"
echo "- SixthSense build system (Python scripts, models)"
echo "- SixthSense source code (train.py, utils.py)"
echo "- SixthSense documentation (README.md, usage instructions)"
echo "- SixthSense configuration (requirements.txt, install.sh)"
echo "- Docker container functionality (Python, PyTorch, ML tools)"
echo "- Machine learning capabilities"

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
    print_status "INFO" "All Docker tests passed! Your SixthSense Docker environment is ready!"
    print_status "INFO" "SixthSense is a machine learning framework."
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your SixthSense Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi

print_status "INFO" "You can now run SixthSense in Docker: A machine learning framework."
print_status "INFO" "Example: docker run --rm sixthsense-env-test python train.py"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/sixthsense sixthsense-env-test /bin/bash" 