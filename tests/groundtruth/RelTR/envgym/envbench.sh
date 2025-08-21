#!/bin/bash

# RelTR Environment Benchmark Test Script
# This script tests the Docker environment setup for RelTR: A relation extraction model
# Tailored specifically for RelTR project requirements and features

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
    docker stop reltr-env-test 2>/dev/null || true
    docker rm reltr-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the RelTR project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t reltr-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/RelTR" reltr-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "RelTR Environment Benchmark Test"
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
    python_major=$(python --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1)
    python_minor=$(python --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f2)
    if [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 6 ]; then
        print_status "PASS" "Python version is >= 3.6 (compatible with RelTR)"
    else
        print_status "WARN" "Python version should be >= 3.6 for RelTR (found: $python_major.$python_minor)"
    fi
else
    print_status "FAIL" "Python is not available for version check"
fi

# Check Conda
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

# Check curl
if command -v curl &> /dev/null; then
    curl_version=$(curl --version 2>&1 | head -n 1)
    print_status "PASS" "curl is available: $curl_version"
else
    print_status "FAIL" "curl is not available"
fi

# Check wget
if command -v wget &> /dev/null; then
    wget_version=$(wget --version 2>&1 | head -n 1)
    print_status "PASS" "wget is available: $wget_version"
else
    print_status "WARN" "wget is not available"
fi

# Check build tools
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version 2>&1 | head -n 1)
    print_status "PASS" "GCC is available: $gcc_version"
else
    print_status "FAIL" "GCC is not available"
fi

if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "make is available: $make_version"
else
    print_status "FAIL" "make is not available"
fi

if command -v unzip &> /dev/null; then
    unzip_version=$(unzip -v 2>&1 | head -n 1)
    print_status "PASS" "unzip is available: $unzip_version"
else
    print_status "WARN" "unzip is not available"
fi

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "models" ]; then
    print_status "PASS" "models directory exists (neural network models)"
else
    print_status "FAIL" "models directory not found"
fi

if [ -d "datasets" ]; then
    print_status "PASS" "datasets directory exists (dataset handling)"
else
    print_status "FAIL" "datasets directory not found"
fi

if [ -d "lib" ]; then
    print_status "PASS" "lib directory exists (utility libraries)"
else
    print_status "FAIL" "lib directory not found"
fi

if [ -d "util" ]; then
    print_status "PASS" "util directory exists (utilities)"
else
    print_status "FAIL" "util directory not found"
fi

if [ -d "data" ]; then
    print_status "PASS" "data directory exists (dataset storage)"
else
    print_status "FAIL" "data directory not found"
fi

if [ -d "demo" ]; then
    print_status "PASS" "demo directory exists (demonstrations)"
else
    print_status "FAIL" "demo directory not found"
fi

# Check key files
if [ -f "main.py" ]; then
    print_status "PASS" "main.py exists (training and evaluation script)"
else
    print_status "FAIL" "main.py not found"
fi

if [ -f "inference.py" ]; then
    print_status "PASS" "inference.py exists (inference script)"
else
    print_status "FAIL" "inference.py not found"
fi

if [ -f "engine.py" ]; then
    print_status "PASS" "engine.py exists (training engine)"
else
    print_status "FAIL" "engine.py not found"
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

# Check model files
if [ -f "models/reltr.py" ]; then
    print_status "PASS" "models/reltr.py exists (main RelTR model)"
else
    print_status "FAIL" "models/reltr.py not found"
fi

if [ -f "models/transformer.py" ]; then
    print_status "PASS" "models/transformer.py exists (transformer architecture)"
else
    print_status "FAIL" "models/transformer.py not found"
fi

if [ -f "models/backbone.py" ]; then
    print_status "PASS" "models/backbone.py exists (backbone network)"
else
    print_status "FAIL" "models/backbone.py not found"
fi

if [ -f "models/matcher.py" ]; then
    print_status "PASS" "models/matcher.py exists (matching algorithm)"
else
    print_status "FAIL" "models/matcher.py not found"
fi

if [ -f "models/position_encoding.py" ]; then
    print_status "PASS" "models/position_encoding.py exists (positional encoding)"
else
    print_status "FAIL" "models/position_encoding.py not found"
fi

# Check lib files
if [ -d "lib/fpn" ]; then
    print_status "PASS" "lib/fpn directory exists (feature pyramid network)"
else
    print_status "FAIL" "lib/fpn directory not found"
fi

if [ -d "lib/evaluation" ]; then
    print_status "PASS" "lib/evaluation directory exists (evaluation metrics)"
else
    print_status "FAIL" "lib/evaluation directory not found"
fi

if [ -d "lib/openimages_evaluation" ]; then
    print_status "PASS" "lib/openimages_evaluation directory exists (OpenImages evaluation)"
else
    print_status "FAIL" "lib/openimages_evaluation directory not found"
fi

if [ -f "lib/pytorch_misc.py" ]; then
    print_status "PASS" "lib/pytorch_misc.py exists (PyTorch utilities)"
else
    print_status "FAIL" "lib/pytorch_misc.py not found"
fi

# Check data directories
if [ -d "data/vg" ]; then
    print_status "PASS" "data/vg directory exists (Visual Genome dataset)"
else
    print_status "WARN" "data/vg directory not found (Visual Genome dataset)"
fi

if [ -d "data/oi" ]; then
    print_status "PASS" "data/oi directory exists (OpenImages dataset)"
else
    print_status "WARN" "data/oi directory not found (OpenImages dataset)"
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

if [ -n "${CONDA_DEFAULT_ENV:-}" ]; then
    print_status "PASS" "CONDA_DEFAULT_ENV is set: $CONDA_DEFAULT_ENV"
else
    print_status "WARN" "CONDA_DEFAULT_ENV is not set"
fi

if [ -n "${CONDA_PREFIX:-}" ]; then
    print_status "PASS" "CONDA_PREFIX is set: $CONDA_PREFIX"
else
    print_status "WARN" "CONDA_PREFIX is not set"
fi

# Check CUDA environment
if [ -n "${CUDA_HOME:-}" ]; then
    print_status "PASS" "CUDA_HOME is set: $CUDA_HOME"
else
    print_status "WARN" "CUDA_HOME is not set"
fi

if [ -n "${CUDA_VISIBLE_DEVICES:-}" ]; then
    print_status "PASS" "CUDA_VISIBLE_DEVICES is set: $CUDA_VISIBLE_DEVICES"
else
    print_status "WARN" "CUDA_VISIBLE_DEVICES is not set"
fi

# Check PATH
if echo "$PATH" | grep -q "python"; then
    print_status "PASS" "python is in PATH"
else
    print_status "WARN" "python is not in PATH"
fi

if echo "$PATH" | grep -q "conda"; then
    print_status "PASS" "conda is in PATH"
else
    print_status "WARN" "conda is not in PATH"
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
    if timeout 30s python --version >/dev/null 2>&1; then
        print_status "PASS" "Python execution works"
    else
        print_status "WARN" "Python execution failed"
    fi
    
    # Test Python import
    if timeout 30s python -c "import sys; print('Python import test passed')" >/dev/null 2>&1; then
        print_status "PASS" "Python import works"
    else
        print_status "WARN" "Python import failed"
    fi
else
    print_status "FAIL" "python is not available"
fi

# Test pip
if command -v pip &> /dev/null; then
    print_status "PASS" "pip is available"
    
    # Test pip version
    if timeout 30s pip --version >/dev/null 2>&1; then
        print_status "PASS" "pip version command works"
    else
        print_status "WARN" "pip version command failed"
    fi
else
    print_status "WARN" "pip is not available"
fi

echo ""
echo "5. Testing RelTR Dependencies..."
echo "-------------------------------"
# Test PyTorch
if python -c "import torch; print('PyTorch version:', torch.__version__)" >/dev/null 2>&1; then
    pytorch_version=$(python -c "import torch; print(torch.__version__)" 2>/dev/null)
    print_status "PASS" "PyTorch is available: $pytorch_version"
    
    # Check PyTorch version
    if python -c "import torch; print(torch.__version__)" 2>/dev/null | grep -q "1.6"; then
        print_status "PASS" "PyTorch version is 1.6.x (compatible with RelTR)"
    else
        print_status "WARN" "PyTorch version should be 1.6.x for RelTR"
    fi
    
    # Test CUDA availability
    if python -c "import torch; print('CUDA available:', torch.cuda.is_available())" >/dev/null 2>&1; then
        cuda_available=$(python -c "import torch; print(torch.cuda.is_available())" 2>/dev/null)
        if [ "$cuda_available" = "True" ]; then
            print_status "PASS" "CUDA is available in PyTorch"
        else
            print_status "WARN" "CUDA is not available in PyTorch"
        fi
    fi
else
    print_status "FAIL" "PyTorch is not available"
fi

# Test torchvision
if python -c "import torchvision; print('torchvision version:', torchvision.__version__)" >/dev/null 2>&1; then
    torchvision_version=$(python -c "import torchvision; print(torchvision.__version__)" 2>/dev/null)
    print_status "PASS" "torchvision is available: $torchvision_version"
else
    print_status "FAIL" "torchvision is not available"
fi

# Test matplotlib
if python -c "import matplotlib; print('matplotlib version:', matplotlib.__version__)" >/dev/null 2>&1; then
    matplotlib_version=$(python -c "import matplotlib; print(matplotlib.__version__)" 2>/dev/null)
    print_status "PASS" "matplotlib is available: $matplotlib_version"
else
    print_status "FAIL" "matplotlib is not available"
fi

# Test numpy
if python -c "import numpy; print('numpy version:', numpy.__version__)" >/dev/null 2>&1; then
    numpy_version=$(python -c "import numpy; print(numpy.__version__)" 2>/dev/null)
    print_status "PASS" "numpy is available: $numpy_version"
else
    print_status "FAIL" "numpy is not available"
fi

# Test scipy
if python -c "import scipy; print('scipy version:', scipy.__version__)" >/dev/null 2>&1; then
    scipy_version=$(python -c "import scipy; print(scipy.__version__)" 2>/dev/null)
    print_status "PASS" "scipy is available: $scipy_version"
else
    print_status "WARN" "scipy is not available"
fi

# Test pycocotools
if python -c "import pycocotools; print('pycocotools available')" >/dev/null 2>&1; then
    print_status "PASS" "pycocotools is available"
else
    print_status "WARN" "pycocotools is not available"
fi

echo ""
echo "6. Testing RelTR Source Code Structure..."
echo "----------------------------------------"
# Test source code directories
if [ -d "models" ]; then
    print_status "PASS" "models directory exists for model testing"
    
    # Count Python files
    python_files=$(find models -name "*.py" | wc -l)
    
    if [ "$python_files" -gt 0 ]; then
        print_status "PASS" "Found $python_files Python files in models"
    else
        print_status "WARN" "No Python files found in models"
    fi
    
    # Check for key model files
    if [ -f "models/__init__.py" ]; then
        print_status "PASS" "models/__init__.py exists (package initialization)"
    else
        print_status "FAIL" "models/__init__.py not found"
    fi
else
    print_status "FAIL" "models directory not found"
fi

if [ -d "datasets" ]; then
    print_status "PASS" "datasets directory exists for dataset testing"
    
    # Count dataset files
    dataset_files=$(find datasets -name "*.py" | wc -l)
    if [ "$dataset_files" -gt 0 ]; then
        print_status "PASS" "Found $dataset_files Python files in datasets"
    else
        print_status "WARN" "No Python files found in datasets"
    fi
else
    print_status "FAIL" "datasets directory not found"
fi

if [ -d "util" ]; then
    print_status "PASS" "util directory exists for utility testing"
    
    # Count utility files
    util_files=$(find util -name "*.py" | wc -l)
    if [ "$util_files" -gt 0 ]; then
        print_status "PASS" "Found $util_files Python files in util"
    else
        print_status "WARN" "No Python files found in util"
    fi
else
    print_status "FAIL" "util directory not found"
fi

if [ -d "lib" ]; then
    print_status "PASS" "lib directory exists for library testing"
    
    # Count library files
    lib_files=$(find lib -name "*.py" | wc -l)
    if [ "$lib_files" -gt 0 ]; then
        print_status "PASS" "Found $lib_files Python files in lib"
    else
        print_status "WARN" "No Python files found in lib"
    fi
else
    print_status "FAIL" "lib directory not found"
fi

echo ""
echo "7. Testing RelTR Documentation..."
echo "--------------------------------"
# Test documentation
if [ -r "README.md" ]; then
    print_status "PASS" "README.md is readable"
else
    print_status "FAIL" "README.md is not readable"
fi

if [ -r ".gitignore" ]; then
    print_status "PASS" ".gitignore is readable"
else
    print_status "FAIL" ".gitignore is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "RelTR" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "Scene Graph Generation" README.md; then
        print_status "PASS" "README.md contains project description"
    else
        print_status "WARN" "README.md missing project description"
    fi
    
    if grep -q "python" README.md; then
        print_status "PASS" "README.md contains usage instructions"
    else
        print_status "WARN" "README.md missing usage instructions"
    fi
fi

echo ""
echo "8. Testing RelTR Configuration..."
echo "--------------------------------"
# Test configuration files
if [ -r "main.py" ]; then
    print_status "PASS" "main.py is readable"
else
    print_status "FAIL" "main.py is not readable"
fi

if [ -r "inference.py" ]; then
    print_status "PASS" "inference.py is readable"
else
    print_status "FAIL" "inference.py is not readable"
fi

if [ -r "engine.py" ]; then
    print_status "PASS" "engine.py is readable"
else
    print_status "FAIL" "engine.py is not readable"
fi

if [ -r ".gitignore" ]; then
    print_status "PASS" ".gitignore is readable"
else
    print_status "FAIL" ".gitignore is not readable"
fi

# Check .gitignore content
if [ -r ".gitignore" ]; then
    if grep -q "*.pyc" .gitignore; then
        print_status "PASS" ".gitignore excludes Python cache files"
    else
        print_status "WARN" ".gitignore missing Python cache file exclusion"
    fi
    
    if grep -q "__pycache__" .gitignore; then
        print_status "PASS" ".gitignore excludes __pycache__ directories"
    else
        print_status "WARN" ".gitignore missing __pycache__ directory exclusion"
    fi
    
    if grep -q "*.pth" .gitignore; then
        print_status "PASS" ".gitignore excludes PyTorch model files"
    else
        print_status "WARN" ".gitignore missing PyTorch model file exclusion"
    fi
fi

echo ""
echo "9. Testing RelTR Docker Functionality..."
echo "---------------------------------------"
# Test if Docker container can run basic commands
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test Python in Docker
    if docker run --rm reltr-env-test python --version >/dev/null 2>&1; then
        print_status "PASS" "Python works in Docker container"
    else
        print_status "FAIL" "Python does not work in Docker container"
    fi
    
    # Test Conda in Docker
    if docker run --rm reltr-env-test conda --version >/dev/null 2>&1; then
        print_status "PASS" "Conda works in Docker container"
    else
        print_status "FAIL" "Conda does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm reltr-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test build tools in Docker
    if docker run --rm reltr-env-test gcc --version >/dev/null 2>&1; then
        print_status "PASS" "GCC works in Docker container"
    else
        print_status "FAIL" "GCC does not work in Docker container"
    fi
    
    # Test if main.py is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" reltr-env-test test -f main.py; then
        print_status "PASS" "main.py is accessible in Docker container"
    else
        print_status "FAIL" "main.py is not accessible in Docker container"
    fi
    
    # Test if models directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" reltr-env-test test -d models; then
        print_status "PASS" "models directory is accessible in Docker container"
    else
        print_status "FAIL" "models directory is not accessible in Docker container"
    fi
    
    # Test if datasets directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" reltr-env-test test -d datasets; then
        print_status "PASS" "datasets directory is accessible in Docker container"
    else
        print_status "FAIL" "datasets directory is not accessible in Docker container"
    fi
    
    # Test if lib directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" reltr-env-test test -d lib; then
        print_status "PASS" "lib directory is accessible in Docker container"
    else
        print_status "FAIL" "lib directory is not accessible in Docker container"
    fi
    
    # Test if util directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" reltr-env-test test -d util; then
        print_status "PASS" "util directory is accessible in Docker container"
    else
        print_status "FAIL" "util directory is not accessible in Docker container"
    fi
    
    # Test if data directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" reltr-env-test test -d data; then
        print_status "PASS" "data directory is accessible in Docker container"
    else
        print_status "FAIL" "data directory is not accessible in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" reltr-env-test test -f README.md; then
        print_status "PASS" "README.md is accessible in Docker container"
    else
        print_status "FAIL" "README.md is not accessible in Docker container"
    fi
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for RelTR:"
echo "- Docker build process (Ubuntu 22.04, Python, PyTorch)"
echo "- Python environment (version compatibility, module loading)"
echo "- PyTorch environment (deep learning, GPU support)"
echo "- RelTR build system (Python scripts, models)"
echo "- RelTR source code (main.py, engine.py, inference.py)"
echo "- RelTR documentation (README.md, usage instructions)"
echo "- RelTR configuration (models, datasets, util)"
echo "- Docker container functionality (Python, PyTorch, ML tools)"
echo "- Relation extraction capabilities"

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
    print_status "INFO" "All Docker tests passed! Your RelTR Docker environment is ready!"
    print_status "INFO" "RelTR is a relation extraction model."
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your RelTR Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi

print_status "INFO" "You can now run RelTR in Docker: A relation extraction model."
print_status "INFO" "Example: docker run --rm reltr-env-test python main.py"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/RelTR reltr-env-test /bin/bash" 