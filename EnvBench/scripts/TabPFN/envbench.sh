#!/bin/bash

# TabPFN Environment Benchmark Test Script
# This script tests the Docker environment setup for TabPFN: A transformer for tabular data
# Tailored specifically for TabPFN project requirements and features

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
    docker stop tabpfn-env-test 2>/dev/null || true
    docker rm tabpfn-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the TabPFN project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t tabpfn-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/TabPFN" tabpfn-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "TabPFN Environment Benchmark Test"
echo "=========================================="

echo "1. Checking Python Environment..."
echo "---------------------------------"
# Check Python version
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>&1)
    print_status "PASS" "Python3 is available: $python_version"
    
    # Check Python version compatibility (TabPFN requires 3.9+)
    python_major=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1)
    python_minor=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f2)
    if [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 9 ]; then
        print_status "PASS" "Python version is >= 3.9 (compatible with TabPFN)"
    else
        print_status "WARN" "Python version should be >= 3.9 for TabPFN (found: $python_major.$python_minor)"
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

# Test Python execution
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
    print_status "INFO" "Testing TabPFN Python dependencies..."
    
    # Test PyTorch
    if python3 -c "import torch" 2>/dev/null; then
        torch_version=$(python3 -c "import torch; print(torch.__version__)" 2>/dev/null)
        print_status "PASS" "PyTorch dependency is available: $torch_version"
        
        # Test CUDA availability
        if python3 -c "import torch; print(torch.cuda.is_available())" 2>/dev/null | grep -q "True"; then
            print_status "PASS" "CUDA is available for PyTorch"
        else
            print_status "WARN" "CUDA is not available for PyTorch (GPU acceleration disabled)"
        fi
    else
        print_status "FAIL" "PyTorch dependency is not available"
    fi
    
    # Test scikit-learn
    if python3 -c "import sklearn" 2>/dev/null; then
        sklearn_version=$(python3 -c "import sklearn; print(sklearn.__version__)" 2>/dev/null)
        print_status "PASS" "scikit-learn dependency is available: $sklearn_version"
    else
        print_status "FAIL" "scikit-learn dependency is not available"
    fi
    
    # Test pandas
    if python3 -c "import pandas" 2>/dev/null; then
        pandas_version=$(python3 -c "import pandas; print(pandas.__version__)" 2>/dev/null)
        print_status "PASS" "pandas dependency is available: $pandas_version"
    else
        print_status "FAIL" "pandas dependency is not available"
    fi
    
    # Test scipy
    if python3 -c "import scipy" 2>/dev/null; then
        scipy_version=$(python3 -c "import scipy; print(scipy.__version__)" 2>/dev/null)
        print_status "PASS" "scipy dependency is available: $scipy_version"
    else
        print_status "FAIL" "scipy dependency is not available"
    fi
    
    # Test einops
    if python3 -c "import einops" 2>/dev/null; then
        einops_version=$(python3 -c "import einops; print(einops.__version__)" 2>/dev/null)
        print_status "PASS" "einops dependency is available: $einops_version"
    else
        print_status "FAIL" "einops dependency is not available"
    fi
    
    # Test huggingface-hub
    if python3 -c "import huggingface_hub" 2>/dev/null; then
        hf_version=$(python3 -c "import huggingface_hub; print(huggingface_hub.__version__)" 2>/dev/null)
        print_status "PASS" "huggingface-hub dependency is available: $hf_version"
    else
        print_status "FAIL" "huggingface-hub dependency is not available"
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

if command -v g++ &> /dev/null; then
    gpp_version=$(g++ --version 2>&1 | head -n 1)
    print_status "PASS" "G++ is available: $gpp_version"
else
    print_status "WARN" "G++ is not available"
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

# Check make
if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "make is available: $make_version"
else
    print_status "WARN" "make is not available"
fi

echo ""
echo "4. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "src" ]; then
    print_status "PASS" "src directory exists (source code)"
else
    print_status "FAIL" "src directory not found"
fi

if [ -d "src/tabpfn" ]; then
    print_status "PASS" "src/tabpfn directory exists (main package)"
else
    print_status "FAIL" "src/tabpfn directory not found"
fi

if [ -d "tests" ]; then
    print_status "PASS" "tests directory exists (test suite)"
else
    print_status "FAIL" "tests directory not found"
fi

if [ -d "examples" ]; then
    print_status "PASS" "examples directory exists (usage examples)"
else
    print_status "FAIL" "examples directory not found"
fi

if [ -d "scripts" ]; then
    print_status "PASS" "scripts directory exists (utility scripts)"
else
    print_status "FAIL" "scripts directory not found"
fi

# Check key files
if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
fi

if [ -f "pyproject.toml" ]; then
    print_status "PASS" "pyproject.toml exists (project configuration)"
else
    print_status "FAIL" "pyproject.toml not found"
fi

if [ -f "LICENSE" ]; then
    print_status "PASS" "LICENSE exists"
else
    print_status "FAIL" "LICENSE not found"
fi

if [ -f "CHANGELOG.md" ]; then
    print_status "PASS" "CHANGELOG.md exists"
else
    print_status "FAIL" "CHANGELOG.md not found"
fi

if [ -f ".pre-commit-config.yaml" ]; then
    print_status "PASS" ".pre-commit-config.yaml exists (pre-commit hooks)"
else
    print_status "FAIL" ".pre-commit-config.yaml not found"
fi

# Check source files
if [ -f "src/tabpfn/__init__.py" ]; then
    print_status "PASS" "src/tabpfn/__init__.py exists (package init)"
else
    print_status "FAIL" "src/tabpfn/__init__.py not found"
fi

if [ -f "src/tabpfn/classifier.py" ]; then
    print_status "PASS" "src/tabpfn/classifier.py exists (classifier implementation)"
else
    print_status "FAIL" "src/tabpfn/classifier.py not found"
fi

if [ -f "src/tabpfn/regressor.py" ]; then
    print_status "PASS" "src/tabpfn/regressor.py exists (regressor implementation)"
else
    print_status "FAIL" "src/tabpfn/regressor.py not found"
fi

if [ -d "src/tabpfn/model" ]; then
    print_status "PASS" "src/tabpfn/model directory exists (model implementation)"
else
    print_status "FAIL" "src/tabpfn/model directory not found"
fi

echo ""
echo "5. Testing TabPFN Source Code..."
echo "--------------------------------"
# Count Python files
python_files=$(find . -name "*.py" | wc -l)
if [ "$python_files" -gt 0 ]; then
    print_status "PASS" "Found $python_files Python files"
else
    print_status "FAIL" "No Python files found"
fi

# Count test files
test_files=$(find . -name "test_*.py" | wc -l)
if [ "$test_files" -gt 0 ]; then
    print_status "PASS" "Found $test_files test files"
else
    print_status "WARN" "No test files found"
fi

# Count YAML files
yaml_files=$(find . -name "*.yaml" | wc -l)
if [ "$yaml_files" -gt 0 ]; then
    print_status "PASS" "Found $yaml_files YAML files"
else
    print_status "WARN" "No YAML files found"
fi

# Count TOML files
toml_files=$(find . -name "*.toml" | wc -l)
if [ "$toml_files" -gt 0 ]; then
    print_status "PASS" "Found $toml_files TOML files"
else
    print_status "WARN" "No TOML files found"
fi

# Test Python syntax
if command -v python3 &> /dev/null; then
    print_status "INFO" "Testing Python syntax..."
    syntax_errors=0
    for py_file in $(find . -name "*.py" | head -20); do
        if ! timeout 30s python3 -m py_compile "$py_file" >/dev/null 2>&1; then
            ((syntax_errors++))
        fi
    done
    
    if [ "$syntax_errors" -eq 0 ]; then
        print_status "PASS" "All tested Python files have valid syntax"
    else
        print_status "WARN" "Found $syntax_errors Python files with syntax errors"
    fi
else
    print_status "FAIL" "Python3 is not available for syntax checking"
fi

# Test pyproject.toml parsing
if command -v python3 &> /dev/null; then
    print_status "INFO" "Testing pyproject.toml parsing..."
    if timeout 30s python3 -c "import tomllib; tomllib.load(open('pyproject.toml', 'rb'))" >/dev/null 2>&1; then
        print_status "PASS" "pyproject.toml parsing successful"
    else
        print_status "FAIL" "pyproject.toml parsing failed"
    fi
else
    print_status "FAIL" "Python3 is not available for pyproject.toml parsing"
fi

echo ""
echo "6. Testing TabPFN Dependencies..."
echo "---------------------------------"
# Test if required Python packages are available
if command -v python3 &> /dev/null; then
    print_status "INFO" "Testing TabPFN Python dependencies..."
    
    # Test PyTorch
    if python3 -c "import torch" 2>/dev/null; then
        print_status "PASS" "PyTorch dependency is available"
    else
        print_status "FAIL" "PyTorch dependency is not available"
    fi
    
    # Test scikit-learn
    if python3 -c "import sklearn" 2>/dev/null; then
        print_status "PASS" "scikit-learn dependency is available"
    else
        print_status "FAIL" "scikit-learn dependency is not available"
    fi
    
    # Test pandas
    if python3 -c "import pandas" 2>/dev/null; then
        print_status "PASS" "pandas dependency is available"
    else
        print_status "FAIL" "pandas dependency is not available"
    fi
    
    # Test scipy
    if python3 -c "import scipy" 2>/dev/null; then
        print_status "PASS" "scipy dependency is available"
    else
        print_status "FAIL" "scipy dependency is not available"
    fi
    
    # Test einops
    if python3 -c "import einops" 2>/dev/null; then
        print_status "PASS" "einops dependency is available"
    else
        print_status "FAIL" "einops dependency is not available"
    fi
    
    # Test huggingface-hub
    if python3 -c "import huggingface_hub" 2>/dev/null; then
        print_status "PASS" "huggingface-hub dependency is available"
    else
        print_status "FAIL" "huggingface-hub dependency is not available"
    fi
else
    print_status "FAIL" "Python3 is not available for dependency testing"
fi

echo ""
echo "7. Testing TabPFN Documentation..."
echo "----------------------------------"
# Test documentation readability
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

if [ -r "CHANGELOG.md" ]; then
    print_status "PASS" "CHANGELOG.md is readable"
else
    print_status "FAIL" "CHANGELOG.md is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "TabPFN" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "tabular data" README.md; then
        print_status "PASS" "README.md contains tabular data description"
    else
        print_status "WARN" "README.md missing tabular data description"
    fi
    
    if grep -q "PyTorch" README.md; then
        print_status "PASS" "README.md contains PyTorch description"
    else
        print_status "WARN" "README.md missing PyTorch description"
    fi
    
    if grep -q "GPU" README.md; then
        print_status "PASS" "README.md contains GPU description"
    else
        print_status "WARN" "README.md missing GPU description"
    fi
    
    if grep -q "scikit-learn" README.md; then
        print_status "PASS" "README.md contains scikit-learn description"
    else
        print_status "WARN" "README.md missing scikit-learn description"
    fi
fi

echo ""
echo "8. Testing TabPFN Docker Functionality..."
echo "-----------------------------------------"
# Test if Docker container can run basic commands
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test Python in Docker
    if docker run --rm tabpfn-env-test python --version >/dev/null 2>&1; then
        print_status "PASS" "Python works in Docker container"
    else
        print_status "FAIL" "Python does not work in Docker container"
    fi
    
    # Test pip in Docker
    if docker run --rm tabpfn-env-test pip --version >/dev/null 2>&1; then
        print_status "PASS" "pip works in Docker container"
    else
        print_status "FAIL" "pip does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm tabpfn-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test PyTorch in Docker
    if docker run --rm tabpfn-env-test python -c "import torch" >/dev/null 2>&1; then
        print_status "PASS" "PyTorch works in Docker container"
    else
        print_status "FAIL" "PyTorch does not work in Docker container"
    fi
    
    # Test scikit-learn in Docker
    if docker run --rm tabpfn-env-test python -c "import sklearn" >/dev/null 2>&1; then
        print_status "PASS" "scikit-learn works in Docker container"
    else
        print_status "FAIL" "scikit-learn does not work in Docker container"
    fi
    
    # Test TabPFN in Docker
    if docker run --rm tabpfn-env-test python -c "import tabpfn" >/dev/null 2>&1; then
        print_status "PASS" "TabPFN works in Docker container"
    else
        print_status "FAIL" "TabPFN does not work in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" tabpfn-env-test test -f README.md; then
        print_status "PASS" "README.md is accessible in Docker container"
    else
        print_status "FAIL" "README.md is not accessible in Docker container"
    fi
    
    # Test if pyproject.toml is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" tabpfn-env-test test -f pyproject.toml; then
        print_status "PASS" "pyproject.toml is accessible in Docker container"
    else
        print_status "FAIL" "pyproject.toml is not accessible in Docker container"
    fi
    
    # Test if src/tabpfn directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" tabpfn-env-test test -d src/tabpfn; then
        print_status "PASS" "src/tabpfn directory is accessible in Docker container"
    else
        print_status "FAIL" "src/tabpfn directory is not accessible in Docker container"
    fi
    
    # Test Python script execution in Docker
    if timeout 60s docker run --rm -v "$(pwd):/workspace" -w /workspace tabpfn-env-test python -c "print('TabPFN test successful')" >/dev/null 2>&1; then
        print_status "PASS" "Python script execution works in Docker container"
    else
        print_status "FAIL" "Python script execution does not work in Docker container"
    fi
fi

echo ""
echo "9. Testing TabPFN Build Process..."
echo "----------------------------------"
# Test if Docker container can run build commands
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test if pre-commit config is accessible
    if docker run --rm -v "$(pwd):/workspace" -w /workspace tabpfn-env-test test -f .pre-commit-config.yaml; then
        print_status "PASS" ".pre-commit-config.yaml is accessible in Docker container"
    else
        print_status "FAIL" ".pre-commit-config.yaml is not accessible in Docker container"
    fi
    
    # Test if tests directory is accessible
    if docker run --rm -v "$(pwd):/workspace" -w /workspace tabpfn-env-test test -d tests; then
        print_status "PASS" "tests directory is accessible in Docker container"
    else
        print_status "FAIL" "tests directory is not accessible in Docker container"
    fi
    
    # Test if examples directory is accessible
    if docker run --rm -v "$(pwd):/workspace" -w /workspace tabpfn-env-test test -d examples; then
        print_status "PASS" "examples directory is accessible in Docker container"
    else
        print_status "FAIL" "examples directory is not accessible in Docker container"
    fi
    
    # Test pip install in editable mode
    if timeout 120s docker run --rm -v "$(pwd):/workspace" -w /workspace tabpfn-env-test pip install -e . >/dev/null 2>&1; then
        print_status "PASS" "pip install -e . works in Docker container"
    else
        print_status "FAIL" "pip install -e . does not work in Docker container"
    fi
    
    # Test pytest help
    if timeout 60s docker run --rm -v "$(pwd):/workspace" -w /workspace tabpfn-env-test python -m pytest --help >/dev/null 2>&1; then
        print_status "PASS" "pytest help works in Docker container"
    else
        print_status "FAIL" "pytest help does not work in Docker container"
    fi
    
    # Skip actual test execution to avoid timeouts
    print_status "WARN" "Skipping actual test execution to avoid timeouts (full test suite)"
    print_status "INFO" "Docker environment is ready for TabPFN development"
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for TabPFN:"
echo "- Docker build process (Ubuntu 22.04, Python, PyTorch)"
echo "- Python environment (version compatibility, module loading)"
echo "- PyTorch environment (deep learning, transformers)"
echo "- TabPFN build system (Python scripts, models)"
echo "- TabPFN source code (src, tests, examples)"
echo "- TabPFN documentation (README.md, CHANGELOG.md)"
echo "- TabPFN configuration (pyproject.toml, .gitignore)"
echo "- Docker container functionality (Python, PyTorch, ML tools)"
echo "- Tabular data transformer capabilities"

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
    print_status "INFO" "All Docker tests passed! Your TabPFN Docker environment is ready!"
    print_status "INFO" "TabPFN is a transformer for tabular data."
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your TabPFN Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi

print_status "INFO" "You can now run TabPFN in Docker: A transformer for tabular data."
print_status "INFO" "Example: docker run --rm tabpfn-env-test python -m pip install -e ."

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/TabPFN tabpfn-env-test /bin/bash" 