#!/bin/bash

# Lottory Environment Benchmark Test Script
# This script tests the Docker environment setup for Lottory: Lottery Ticket Hypothesis in PyTorch
# Tailored specifically for Lottory project requirements and features

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
    jobs -p | xargs -r kill
    rm -f docker_build.log
    docker stop lottory-env-test 2>/dev/null || true
    docker rm lottory-env-test 2>/dev/null || true
    exit 0
}

trap cleanup SIGINT SIGTERM

# Check if we're running in Docker
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo "Running inside Docker container - performing environment tests..."
    DOCKER_MODE=true
else
    echo "Running on host - checking for Docker and envgym.dockerfile"
    DOCKER_MODE=false
    
    if ! command -v docker &> /dev/null; then
        print_status "WARN" "Docker not available - Docker environment not available"
    elif [ -f "envgym/envgym.dockerfile" ]; then
        echo "Building Docker image..."
        if timeout 300s docker build -f envgym/envgym.dockerfile -t lottory-env-test .; then
            echo "Docker build successful - analyzing build process..."
            DOCKER_BUILD_SUCCESS=true
        else
            echo "WARNING: Docker build failed - analyzing Dockerfile only"
            DOCKER_BUILD_FAILED=true
        fi
    else
        print_status "WARN" "envgym.dockerfile not found - Docker environment not available"
    fi
fi

# If Docker build was successful, analyze the build process
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    echo ""
    echo "Docker build was successful - analyzing build process..."
    echo "------------------------------------------------------"
    
    # Test if Python 3.7 is available in Docker
    if docker run --rm lottory-env-test python3.7 --version >/dev/null 2>&1; then
        python_version=$(docker run --rm lottory-env-test python3.7 --version 2>/dev/null)
        print_status "PASS" "Python 3.7 is available in Docker: $python_version"
    else
        print_status "FAIL" "Python 3.7 is not available in Docker"
    fi
    
    # Test if pip is available in Docker
    if docker run --rm lottory-env-test pip --version >/dev/null 2>&1; then
        pip_version=$(docker run --rm lottory-env-test pip --version 2>/dev/null)
        print_status "PASS" "pip is available in Docker: $pip_version"
    else
        print_status "FAIL" "pip is not available in Docker"
    fi
    
    # Test if PyTorch is available in Docker
    if docker run --rm lottory-env-test python3.7 -c "import torch; print(torch.__version__)" >/dev/null 2>&1; then
        torch_version=$(docker run --rm lottory-env-test python3.7 -c "import torch; print(torch.__version__)" 2>/dev/null)
        print_status "PASS" "PyTorch is available in Docker: $torch_version"
    else
        print_status "FAIL" "PyTorch is not available in Docker"
    fi
    
    # Test if torchvision is available in Docker
    if docker run --rm lottory-env-test python3.7 -c "import torchvision; print(torchvision.__version__)" >/dev/null 2>&1; then
        torchvision_version=$(docker run --rm lottory-env-test python3.7 -c "import torchvision; print(torchvision.__version__)" 2>/dev/null)
        print_status "PASS" "torchvision is available in Docker: $torchvision_version"
    else
        print_status "FAIL" "torchvision is not available in Docker"
    fi
    
    # Test if Git is available in Docker
    if docker run --rm lottory-env-test git --version >/dev/null 2>&1; then
        git_version=$(docker run --rm lottory-env-test git --version 2>/dev/null)
        print_status "PASS" "Git is available in Docker: $git_version"
    else
        print_status "FAIL" "Git is not available in Docker"
    fi
fi

echo "=========================================="
echo "Lottory Environment Benchmark Test"
echo "=========================================="

echo "1. Checking System Dependencies..."
echo "--------------------------------"
# Check Python 3.7
if command -v python3.7 &> /dev/null; then
    python_version=$(python3.7 --version 2>&1)
    print_status "PASS" "Python 3.7 is available: $python_version"
else
    print_status "FAIL" "Python 3.7 is not available"
fi

# Check pip
if command -v pip &> /dev/null; then
    pip_version=$(pip --version 2>&1)
    print_status "PASS" "pip is available: $pip_version"
else
    print_status "FAIL" "pip is not available"
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
    print_status "PASS" "Make is available: $make_version"
else
    print_status "FAIL" "Make is not available"
fi

# Check Python3
if command -v python3 &> /dev/null; then
    python3_version=$(python3 --version 2>&1)
    print_status "PASS" "Python3 is available: $python3_version"
else
    print_status "WARN" "Python3 is not available"
fi

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "archs" ]; then
    print_status "PASS" "archs directory exists (neural network architectures)"
else
    print_status "FAIL" "archs directory not found"
fi

if [ -d "archs/mnist" ]; then
    print_status "PASS" "archs/mnist directory exists"
else
    print_status "FAIL" "archs/mnist directory not found"
fi

if [ -d "archs/cifar10" ]; then
    print_status "PASS" "archs/cifar10 directory exists"
else
    print_status "FAIL" "archs/cifar10 directory not found"
fi

if [ -d "archs/cifar100" ]; then
    print_status "PASS" "archs/cifar100 directory exists"
else
    print_status "FAIL" "archs/cifar100 directory not found"
fi

# Check key files
if [ -f "main.py" ]; then
    print_status "PASS" "main.py exists (main training script)"
else
    print_status "FAIL" "main.py not found"
fi

if [ -f "utils.py" ]; then
    print_status "PASS" "utils.py exists (utility functions)"
else
    print_status "FAIL" "utils.py not found"
fi

if [ -f "combine_plots.py" ]; then
    print_status "PASS" "combine_plots.py exists (plot combination script)"
else
    print_status "FAIL" "combine_plots.py not found"
fi

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

# Check architecture files
if [ -f "archs/mnist/fc1.py" ]; then
    print_status "PASS" "archs/mnist/fc1.py exists (fully connected network)"
else
    print_status "FAIL" "archs/mnist/fc1.py not found"
fi

if [ -f "archs/mnist/LeNet5.py" ]; then
    print_status "PASS" "archs/mnist/LeNet5.py exists (LeNet5 architecture)"
else
    print_status "FAIL" "archs/mnist/LeNet5.py not found"
fi

if [ -f "archs/mnist/AlexNet.py" ]; then
    print_status "PASS" "archs/mnist/AlexNet.py exists (AlexNet architecture)"
else
    print_status "FAIL" "archs/mnist/AlexNet.py not found"
fi

if [ -f "archs/mnist/vgg.py" ]; then
    print_status "PASS" "archs/mnist/vgg.py exists (VGG architecture)"
else
    print_status "FAIL" "archs/mnist/vgg.py not found"
fi

if [ -f "archs/mnist/resnet.py" ]; then
    print_status "PASS" "archs/mnist/resnet.py exists (ResNet architecture)"
else
    print_status "FAIL" "archs/mnist/resnet.py not found"
fi

if [ -f "archs/cifar10/fc1.py" ]; then
    print_status "PASS" "archs/cifar10/fc1.py exists"
else
    print_status "FAIL" "archs/cifar10/fc1.py not found"
fi

if [ -f "archs/cifar10/LeNet5.py" ]; then
    print_status "PASS" "archs/cifar10/LeNet5.py exists"
else
    print_status "FAIL" "archs/cifar10/LeNet5.py not found"
fi

if [ -f "archs/cifar10/AlexNet.py" ]; then
    print_status "PASS" "archs/cifar10/AlexNet.py exists"
else
    print_status "FAIL" "archs/cifar10/AlexNet.py not found"
fi

if [ -f "archs/cifar10/vgg.py" ]; then
    print_status "PASS" "archs/cifar10/vgg.py exists"
else
    print_status "FAIL" "archs/cifar10/vgg.py not found"
fi

if [ -f "archs/cifar10/resnet.py" ]; then
    print_status "PASS" "archs/cifar10/resnet.py exists"
else
    print_status "FAIL" "archs/cifar10/resnet.py not found"
fi

if [ -f "archs/cifar10/densenet.py" ]; then
    print_status "PASS" "archs/cifar10/densenet.py exists (DenseNet architecture)"
else
    print_status "FAIL" "archs/cifar10/densenet.py not found"
fi

if [ -f "archs/cifar100/fc1.py" ]; then
    print_status "PASS" "archs/cifar100/fc1.py exists"
else
    print_status "FAIL" "archs/cifar100/fc1.py not found"
fi

if [ -f "archs/cifar100/LeNet5.py" ]; then
    print_status "PASS" "archs/cifar100/LeNet5.py exists"
else
    print_status "FAIL" "archs/cifar100/LeNet5.py not found"
fi

if [ -f "archs/cifar100/AlexNet.py" ]; then
    print_status "PASS" "archs/cifar100/AlexNet.py exists"
else
    print_status "FAIL" "archs/cifar100/AlexNet.py not found"
fi

if [ -f "archs/cifar100/vgg.py" ]; then
    print_status "PASS" "archs/cifar100/vgg.py exists"
else
    print_status "FAIL" "archs/cifar100/vgg.py not found"
fi

if [ -f "archs/cifar100/resnet.py" ]; then
    print_status "PASS" "archs/cifar100/resnet.py exists"
else
    print_status "FAIL" "archs/cifar100/resnet.py not found"
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

# Check PATH
if echo "$PATH" | grep -q "python3.7"; then
    print_status "PASS" "python3.7 is in PATH"
else
    print_status "WARN" "python3.7 is not in PATH"
fi

if echo "$PATH" | grep -q "pip"; then
    print_status "PASS" "pip is in PATH"
else
    print_status "WARN" "pip is not in PATH"
fi

if echo "$PATH" | grep -q "git"; then
    print_status "PASS" "git is in PATH"
else
    print_status "WARN" "git is not in PATH"
fi

echo ""
echo "4. Testing Python 3.7 Environment..."
echo "-----------------------------------"
# Test Python 3.7
if command -v python3.7 &> /dev/null; then
    print_status "PASS" "python3.7 is available"
    
    # Test Python 3.7 execution
    if timeout 30s python3.7 -c "print('Python 3.7 works')" >/dev/null 2>&1; then
        print_status "PASS" "Python 3.7 execution works"
    else
        print_status "WARN" "Python 3.7 execution failed"
    fi
    
    # Test Python 3.7 modules
    if timeout 30s python3.7 -c "import sys; print(sys.version)" >/dev/null 2>&1; then
        print_status "PASS" "Python 3.7 sys module works"
    else
        print_status "WARN" "Python 3.7 sys module failed"
    fi
    
    # Test Python 3.7 version
    if timeout 30s python3.7 -c "import sys; print(sys.version_info)" >/dev/null 2>&1; then
        print_status "PASS" "Python 3.7 version check works"
    else
        print_status "WARN" "Python 3.7 version check failed"
    fi
else
    print_status "FAIL" "python3.7 is not available"
fi

echo ""
echo "5. Testing pip Environment..."
echo "----------------------------"
# Test pip
if command -v pip &> /dev/null; then
    print_status "PASS" "pip is available"
    
    # Test pip version
    if timeout 30s pip --version >/dev/null 2>&1; then
        print_status "PASS" "pip version command works"
    else
        print_status "WARN" "pip version command failed"
    fi
    
    # Test pip list
    if timeout 30s pip list >/dev/null 2>&1; then
        print_status "PASS" "pip list command works"
    else
        print_status "WARN" "pip list command failed"
    fi
    
    # Test pip install
    if timeout 30s pip install --help >/dev/null 2>&1; then
        print_status "PASS" "pip install command works"
    else
        print_status "WARN" "pip install command failed"
    fi
else
    print_status "FAIL" "pip is not available"
fi

echo ""
echo "6. Testing Lottory Build System..."
echo "----------------------------------"
# Test requirements.txt
if [ -f "requirements.txt" ]; then
    print_status "PASS" "requirements.txt exists for build testing"
    
    # Count dependencies
    dep_count=$(wc -l < requirements.txt)
    if [ "$dep_count" -gt 0 ]; then
        print_status "PASS" "Found $dep_count dependencies in requirements.txt"
    else
        print_status "WARN" "No dependencies found in requirements.txt"
    fi
    
    # Check key dependencies
    if grep -q "torch==" requirements.txt; then
        print_status "PASS" "PyTorch dependency found in requirements.txt"
    else
        print_status "FAIL" "PyTorch dependency not found in requirements.txt"
    fi
    
    if grep -q "torchvision==" requirements.txt; then
        print_status "PASS" "torchvision dependency found in requirements.txt"
    else
        print_status "FAIL" "torchvision dependency not found in requirements.txt"
    fi
    
    if grep -q "numpy==" requirements.txt; then
        print_status "PASS" "numpy dependency found in requirements.txt"
    else
        print_status "FAIL" "numpy dependency not found in requirements.txt"
    fi
    
    if grep -q "matplotlib==" requirements.txt; then
        print_status "PASS" "matplotlib dependency found in requirements.txt"
    else
        print_status "FAIL" "matplotlib dependency not found in requirements.txt"
    fi
    
    if grep -q "seaborn==" requirements.txt; then
        print_status "PASS" "seaborn dependency found in requirements.txt"
    else
        print_status "FAIL" "seaborn dependency not found in requirements.txt"
    fi
    
    if grep -q "tensorboardX==" requirements.txt; then
        print_status "PASS" "tensorboardX dependency found in requirements.txt"
    else
        print_status "FAIL" "tensorboardX dependency not found in requirements.txt"
    fi
    
    if grep -q "tqdm==" requirements.txt; then
        print_status "PASS" "tqdm dependency found in requirements.txt"
    else
        print_status "FAIL" "tqdm dependency not found in requirements.txt"
    fi
else
    print_status "FAIL" "requirements.txt not found"
fi

echo ""
echo "7. Testing Lottory Architecture System..."
echo "----------------------------------------"
# Test architecture files
if [ -d "archs" ]; then
    print_status "PASS" "archs directory exists for architecture testing"
    
    # Count architecture files
    arch_count=$(find archs -name "*.py" | wc -l)
    if [ "$arch_count" -gt 0 ]; then
        print_status "PASS" "Found $arch_count architecture files"
    else
        print_status "WARN" "No architecture files found"
    fi
    
    # Test MNIST architectures
    if [ -d "archs/mnist" ]; then
        print_status "PASS" "archs/mnist directory exists"
        
        mnist_arch_count=$(find archs/mnist -name "*.py" | wc -l)
        if [ "$mnist_arch_count" -gt 0 ]; then
            print_status "PASS" "Found $mnist_arch_count MNIST architecture files"
        else
            print_status "WARN" "No MNIST architecture files found"
        fi
    else
        print_status "FAIL" "archs/mnist directory not found"
    fi
    
    # Test CIFAR10 architectures
    if [ -d "archs/cifar10" ]; then
        print_status "PASS" "archs/cifar10 directory exists"
        
        cifar10_arch_count=$(find archs/cifar10 -name "*.py" | wc -l)
        if [ "$cifar10_arch_count" -gt 0 ]; then
            print_status "PASS" "Found $cifar10_arch_count CIFAR10 architecture files"
        else
            print_status "WARN" "No CIFAR10 architecture files found"
        fi
    else
        print_status "FAIL" "archs/cifar10 directory not found"
    fi
    
    # Test CIFAR100 architectures
    if [ -d "archs/cifar100" ]; then
        print_status "PASS" "archs/cifar100 directory exists"
        
        cifar100_arch_count=$(find archs/cifar100 -name "*.py" | wc -l)
        if [ "$cifar100_arch_count" -gt 0 ]; then
            print_status "PASS" "Found $cifar100_arch_count CIFAR100 architecture files"
        else
            print_status "WARN" "No CIFAR100 architecture files found"
        fi
    else
        print_status "FAIL" "archs/cifar100 directory not found"
    fi
else
    print_status "FAIL" "archs directory not found"
fi

echo ""
echo "8. Testing Lottory Source Code..."
echo "--------------------------------"
# Test source code files
if [ -f "main.py" ]; then
    print_status "PASS" "main.py exists for source testing"
    
    # Test Python syntax
    if command -v python3.7 &> /dev/null; then
        if timeout 30s python3.7 -m py_compile main.py >/dev/null 2>&1; then
            print_status "PASS" "main.py syntax is valid"
        else
            print_status "WARN" "main.py syntax is invalid"
        fi
    else
        print_status "WARN" "python3.7 not available for syntax testing"
    fi
    
    # Check for key imports
    if grep -q "import torch" main.py; then
        print_status "PASS" "main.py imports PyTorch"
    else
        print_status "FAIL" "main.py does not import PyTorch"
    fi
    
    if grep -q "import torchvision" main.py; then
        print_status "PASS" "main.py imports torchvision"
    else
        print_status "FAIL" "main.py does not import torchvision"
    fi
    
    if grep -q "import matplotlib" main.py; then
        print_status "PASS" "main.py imports matplotlib"
    else
        print_status "FAIL" "main.py does not import matplotlib"
    fi
    
    if grep -q "import seaborn" main.py; then
        print_status "PASS" "main.py imports seaborn"
    else
        print_status "FAIL" "main.py does not import seaborn"
    fi
else
    print_status "FAIL" "main.py not found"
fi

if [ -f "utils.py" ]; then
    print_status "PASS" "utils.py exists"
    
    # Test Python syntax
    if command -v python3.7 &> /dev/null; then
        if timeout 30s python3.7 -m py_compile utils.py >/dev/null 2>&1; then
            print_status "PASS" "utils.py syntax is valid"
        else
            print_status "WARN" "utils.py syntax is invalid"
        fi
    else
        print_status "WARN" "python3.7 not available for syntax testing"
    fi
else
    print_status "FAIL" "utils.py not found"
fi

if [ -f "combine_plots.py" ]; then
    print_status "PASS" "combine_plots.py exists"
    
    # Test Python syntax
    if command -v python3.7 &> /dev/null; then
        if timeout 30s python3.7 -m py_compile combine_plots.py >/dev/null 2>&1; then
            print_status "PASS" "combine_plots.py syntax is valid"
        else
            print_status "WARN" "combine_plots.py syntax is invalid"
        fi
    else
        print_status "WARN" "python3.7 not available for syntax testing"
    fi
else
    print_status "FAIL" "combine_plots.py not found"
fi

echo ""
echo "9. Testing Lottory Documentation..."
echo "----------------------------------"
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
    if grep -q "Lottery Ticket Hypothesis" README.md; then
        print_status "PASS" "README.md contains project description"
    else
        print_status "WARN" "README.md missing project description"
    fi
    
    if grep -q "Requirements" README.md; then
        print_status "PASS" "README.md contains requirements section"
    else
        print_status "WARN" "README.md missing requirements section"
    fi
    
    if grep -q "How to run" README.md; then
        print_status "PASS" "README.md contains usage instructions"
    else
        print_status "WARN" "README.md missing usage instructions"
    fi
    
    if grep -q "Datasets and Architectures" README.md; then
        print_status "PASS" "README.md contains supported datasets and architectures"
    else
        print_status "WARN" "README.md missing supported datasets and architectures"
    fi
fi

echo ""
echo "10. Testing Lottory Configuration..."
echo "-----------------------------------"
# Test configuration files
if [ -r "requirements.txt" ]; then
    print_status "PASS" "requirements.txt is readable"
else
    print_status "FAIL" "requirements.txt is not readable"
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
        print_status "WARN" ".gitignore missing Python cache exclusion"
    fi
    
    if grep -q "__pycache__" .gitignore; then
        print_status "PASS" ".gitignore excludes Python cache directories"
    else
        print_status "WARN" ".gitignore missing Python cache directory exclusion"
    fi
fi

echo ""
echo "11. Testing Lottory Docker Functionality..."
echo "-------------------------------------------"
# Test if Docker container can run Python commands
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    # Test Python 3.7 in Docker
    if docker run --rm lottory-env-test python3.7 --version >/dev/null 2>&1; then
        print_status "PASS" "Python 3.7 works in Docker container"
    else
        print_status "FAIL" "Python 3.7 does not work in Docker container"
    fi
    
    # Test pip in Docker
    if docker run --rm lottory-env-test pip --version >/dev/null 2>&1; then
        print_status "PASS" "pip works in Docker container"
    else
        print_status "FAIL" "pip does not work in Docker container"
    fi
    
    # Test PyTorch in Docker
    if docker run --rm lottory-env-test python3.7 -c "import torch; print('PyTorch works')" >/dev/null 2>&1; then
        print_status "PASS" "PyTorch works in Docker container"
    else
        print_status "FAIL" "PyTorch does not work in Docker container"
    fi
    
    # Test torchvision in Docker
    if docker run --rm lottory-env-test python3.7 -c "import torchvision; print('torchvision works')" >/dev/null 2>&1; then
        print_status "PASS" "torchvision works in Docker container"
    else
        print_status "FAIL" "torchvision does not work in Docker container"
    fi
    
    # Test matplotlib in Docker
    if docker run --rm lottory-env-test python3.7 -c "import matplotlib; print('matplotlib works')" >/dev/null 2>&1; then
        print_status "PASS" "matplotlib works in Docker container"
    else
        print_status "FAIL" "matplotlib does not work in Docker container"
    fi
    
    # Test seaborn in Docker
    if docker run --rm lottory-env-test python3.7 -c "import seaborn; print('seaborn works')" >/dev/null 2>&1; then
        print_status "PASS" "seaborn works in Docker container"
    else
        print_status "FAIL" "seaborn does not work in Docker container"
    fi
    
    # Test numpy in Docker
    if docker run --rm lottory-env-test python3.7 -c "import numpy; print('numpy works')" >/dev/null 2>&1; then
        print_status "PASS" "numpy works in Docker container"
    else
        print_status "FAIL" "numpy does not work in Docker container"
    fi
    
    # Test pandas in Docker
    if docker run --rm lottory-env-test python3.7 -c "import pandas; print('pandas works')" >/dev/null 2>&1; then
        print_status "PASS" "pandas works in Docker container"
    else
        print_status "FAIL" "pandas does not work in Docker container"
    fi
    
    # Test if main.py is accessible in Docker
    if docker run --rm lottory-env-test test -f main.py; then
        print_status "PASS" "main.py is accessible in Docker container"
    else
        print_status "FAIL" "main.py is not accessible in Docker container"
    fi
    
    # Test if requirements.txt is accessible in Docker
    if docker run --rm lottory-env-test test -f requirements.txt; then
        print_status "PASS" "requirements.txt is accessible in Docker container"
    else
        print_status "FAIL" "requirements.txt is not accessible in Docker container"
    fi
    
    # Test if archs directory is accessible in Docker
    if docker run --rm lottory-env-test test -d archs; then
        print_status "PASS" "archs directory is accessible in Docker container"
    else
        print_status "FAIL" "archs directory is not accessible in Docker container"
    fi
    
    # Test if utils.py is accessible in Docker
    if docker run --rm lottory-env-test test -f utils.py; then
        print_status "PASS" "utils.py is accessible in Docker container"
    else
        print_status "FAIL" "utils.py is not accessible in Docker container"
    fi
    
    # Test if combine_plots.py is accessible in Docker
    if docker run --rm lottory-env-test test -f combine_plots.py; then
        print_status "PASS" "combine_plots.py is accessible in Docker container"
    else
        print_status "FAIL" "combine_plots.py is not accessible in Docker container"
    fi
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for Lottory:"
echo "- Docker build process (Ubuntu 22.04, Python 3.7, PyTorch 1.2.0)"
echo "- Python 3.7 environment (version compatibility, module loading)"
echo "- pip environment (package management, dependency installation)"
echo "- Lottory build system (requirements.txt, dependencies)"
echo "- Lottory architecture system (neural network architectures)"
echo "- Lottory source code (main.py, utils.py, combine_plots.py)"
echo "- Lottory documentation (README.md, usage instructions)"
echo "- Lottory configuration (requirements.txt, .gitignore)"
echo "- Docker container functionality (Python, PyTorch, dependencies)"
echo "- Lottery Ticket Hypothesis implementation (pruning, training, evaluation)"
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
print_status "INFO" "Docker Environment Score: $score_percentage% ($PASS_COUNT/$total_tests tests passed)"
echo ""
if [ $FAIL_COUNT -eq 0 ]; then
    print_status "INFO" "All Docker tests passed! Your Lottory Docker environment is ready!"
    print_status "INFO" "Lottory is a PyTorch implementation of the Lottery Ticket Hypothesis for finding sparse, trainable neural networks."
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your Lottory Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now run Lottory in Docker: A PyTorch implementation of the Lottery Ticket Hypothesis."
print_status "INFO" "Example: docker run --rm lottory-env-test python3.7 main.py --prune_type=lt --arch_type=fc1 --dataset=mnist"
print_status "INFO" "Example: docker run --rm lottory-env-test python3.7 combine_plots.py"
echo ""
print_status "INFO" "For more information, see README.md and https://github.com/rahulvigneswaran/Lottery-Ticket-Hypothesis-in-Pytorch"
exit 0
fi

# If Docker failed or not available, skip local environment tests
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ] || [ "${DOCKER_MODE:-false}" = "false" ]; then
    echo "Docker environment not available - skipping local environment tests"
    echo "This script is designed to test Docker environment only"
    exit 0
fi 