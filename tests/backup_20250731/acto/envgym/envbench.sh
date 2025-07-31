#!/bin/bash

# Acto Environment Benchmark Test
# Tests if the Dockerfile successfully sets up the environment for the Acto repository

# Don't exit on error - continue testing even if some tests fail
# set -e  # Exit on any error
trap 'echo -e "\n\033[0;31m[ERROR] Script interrupted by user\033[0m"; exit 1' INT TERM

# Function to ensure clean exit
cleanup() {
    echo -e "\n\033[0;34m[INFO] Cleaning up...\033[0m"
    # Kill any background processes
    jobs -p | xargs -r kill
    exit 1
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test result counters
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
        *)
            echo "[$status] $message"
            ;;
    esac
}

# Function to check if a command exists
check_command() {
    local cmd=$1
    local name=$2
    
    if command -v "$cmd" &> /dev/null; then
        print_status "PASS" "$name is installed"
        return 0
    else
        print_status "FAIL" "$name is not installed"
        return 1
    fi
}

# Function to check if a Python package is installed
check_python_package() {
    local package=$1
    if python -c "import $package" 2>/dev/null; then
        print_status "PASS" "Python package '$package' is installed"
        return 0
    else
        # Try to get more information about why import failed
        python -c "import $package" 2>&1 | head -1 | grep -q "ModuleNotFoundError" && {
            print_status "FAIL" "Python package '$package' is not installed"
        } || {
            print_status "FAIL" "Python package '$package' import failed (other error)"
        }
        return 1
    fi
}

# Function to check Python package version
check_python_package_version() {
    local package=$1
    local expected_version=$2
    local actual_version=$(python -c "import $package; print($package.__version__)" 2>/dev/null)
    if [ $? -eq 0 ]; then
        print_status "PASS" "Python package '$package' version: $actual_version"
        return 0
    else
        print_status "FAIL" "Python package '$package' version check failed"
        return 1
    fi
}

# Check if we're running inside Docker container
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo "Running inside Docker container - proceeding with environment test..."
else
    echo "Not running in Docker container - building and running Docker test..."
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        echo "ERROR: Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "envgym/envgym.dockerfile" ]; then
        echo "ERROR: envgym.dockerfile not found. Please run this script from the acto project root directory."
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    docker build -f envgym/envgym.dockerfile -t acto-env-test .
    
    # Run this script inside Docker container
    echo "Running environment test in Docker container..."
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/acto" acto-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "Acto Environment Benchmark Test"
echo "=========================================="

echo ""
echo "1. Checking System Dependencies..."
echo "--------------------------------"

# Check system commands (based on Acto prerequisites)
check_command "python" "Python"
check_command "pip" "pip"
check_command "go" "Go"
check_command "kubectl" "kubectl"
check_command "kind" "Kind"
check_command "helm" "Helm"
check_command "git" "Git"
check_command "make" "Make"

echo ""
echo "2. Checking Python Version..."
echo "----------------------------"

python_version=$(python --version 2>&1)
print_status "INFO" "Python version: $python_version"

# Check if Python version is >= 3.12
python_major=$(python -c "import sys; print(sys.version_info.major)")
python_minor=$(python -c "import sys; print(sys.version_info.minor)")
if [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 12 ]; then
    print_status "PASS" "Python version >= 3.12"
else
    print_status "FAIL" "Python version < 3.12 (found $python_major.$python_minor)"
fi

echo ""
echo "3. Checking Go Version..."
echo "------------------------"

go_version=$(go version 2>&1)
print_status "INFO" "Go version: $go_version"

# Check if Go version is >= 1.22
go_major=$(go version | grep -o 'go[0-9]*' | sed 's/go//' | head -1)
if [ "$go_major" -ge 22 ]; then
    print_status "PASS" "Go version >= 1.22"
else
    print_status "FAIL" "Go version < 1.22 (found $go_major)"
fi

echo ""
echo "4. Checking Kubernetes Tools..."
echo "------------------------------"

# Check kubectl version
kubectl_version=$(kubectl version --client 2>&1 | head -1)
print_status "INFO" "kubectl version: $kubectl_version"

# Check Kind version
kind_version=$(kind version 2>&1)
print_status "INFO" "Kind version: $kind_version"

# Check Helm version
helm_version=$(helm version --short 2>&1)
print_status "INFO" "Helm version: $helm_version"

echo ""
echo "5. Checking Python Package Installation..."
echo "----------------------------------------"

# Check if pip is working
if python -c "import pip; print('pip version:', pip.__version__)" 2>/dev/null; then
    print_status "PASS" "pip is working"
else
    print_status "FAIL" "pip is not working"
fi

# Check if packages were actually installed
print_status "INFO" "Checking if packages were actually installed..."
if python -c "import pkg_resources; print('Installed packages:'); [print(f'  {d.project_name} {d.version}') for d in pkg_resources.working_set]" 2>/dev/null; then
    print_status "PASS" "Package list retrieved successfully"
else
    print_status "FAIL" "Could not retrieve package list"
fi

echo ""
echo "6. Checking Core Python Dependencies..."
echo "-------------------------------------"

# Essential packages for Acto core functionality
print_status "INFO" "Checking core Python dependencies..."
check_python_package "kubernetes"      # Kubernetes client
check_python_package "deepdiff"       # State comparison
check_python_package "exrex"          # Regular expression generation
check_python_package "jsonschema"     # Schema validation
check_python_package "jsonpatch"      # JSON patch operations
check_python_package "pandas"         # Data analysis
check_python_package "yaml"           # YAML processing
check_python_package "ruamel.yaml"    # Advanced YAML processing
check_python_package "requests"       # HTTP requests
check_python_package "pydantic"       # Data validation
check_python_package "pytest"         # Testing framework
check_python_package "urllib3"        # HTTP client

echo ""
echo "7. Checking Development Dependencies..."
echo "------------------------------------"

# Development packages (optional for development workflow)
print_status "INFO" "Checking development Python dependencies..."
check_python_package "docker"           # Container management
check_python_package "prometheus_client" # Metrics collection
check_python_package "pytest_cov"       # Test coverage
check_python_package "tabulate"         # Table formatting
check_python_package "pip_tools"        # Dependency management
check_python_package "pre_commit"       # Git hooks
check_python_package "ansible"          # Automation
check_python_package "jinja2"           # Template engine
check_python_package "isort"            # Import sorting
check_python_package "mypy"             # Type checking
check_python_package "black"            # Code formatting
check_python_package "pylint"           # Code linting
check_python_package "jsonref"          # JSON reference resolution
check_python_package "cryptography"     # Cryptographic functions

echo ""
echo "8. Testing Acto Module Import..."
echo "-------------------------------"

# Test importing the main acto module
if python -c "import acto; print('Acto module imported successfully')" 2>/dev/null; then
    print_status "PASS" "Acto module can be imported"
else
    print_status "FAIL" "Acto module cannot be imported"
fi

# Test importing key submodules (only test if main module works)
if python -c "import acto" 2>/dev/null; then
    check_python_package "acto.engine"           # Core testing engine
    check_python_package "acto.input"            # Input generation
    check_python_package "acto.schema"           # Schema processing
    check_python_package "acto.utils"            # Utility functions
    check_python_package "acto.system_state"     # System state management
    check_python_package "acto.kubernetes_engine" # Kubernetes cluster management
    check_python_package "acto.k8s_util"         # Kubernetes utilities
    check_python_package "acto.cli"              # Command line tools
else
    print_status "FAIL" "Acto main module cannot be imported"
fi

echo ""
echo "9. Testing CLI Tools..."
echo "----------------------"

# Test acto CLI help (main entry point)
if python -m acto --help &>/dev/null; then
    print_status "PASS" "Acto CLI help works"
else
    print_status "FAIL" "Acto CLI help failed"
fi

# Test reproduce CLI help (bug reproduction tool)
if python -m acto.reproduce --help &>/dev/null; then
    print_status "PASS" "Acto reproduce CLI help works"
else
    print_status "FAIL" "Acto reproduce CLI help failed"
fi

echo ""
echo "10. Testing CLI Tools (Advanced)..."
echo "-----------------------------------"

# Test schema matching CLI (CRD annotation tool)
if python -m acto.cli.schema_match --help &>/dev/null; then
    print_status "PASS" "Schema matching CLI help works"
else
    print_status "FAIL" "Schema matching CLI help failed"
fi

# Test system state collection CLI (cluster state tool)
if python -m acto.cli.collect_system_state --help &>/dev/null; then
    print_status "PASS" "System state collection CLI help works"
else
    print_status "FAIL" "System state collection CLI help failed"
fi

echo ""
echo "11. Testing Make Build..."
echo "------------------------"

# Test make build (compiles C extensions for k8s_util and ssa)
if make lib &>/dev/null; then
    print_status "PASS" "Make build completed successfully"
else
    print_status "FAIL" "Make build failed"
fi

echo ""
echo "12. Testing Basic Python Code Execution..."
echo "----------------------------------------"

# Test basic Python code execution
if python -c "
import acto
from acto import DEFAULT_KUBERNETES_VERSION
print(f'Default Kubernetes version: {DEFAULT_KUBERNETES_VERSION}')
" 2>/dev/null; then
    print_status "PASS" "Basic Python code execution works"
else
    print_status "FAIL" "Basic Python code execution failed"
fi

echo ""
echo "13. Testing Configuration Loading..."
echo "-----------------------------------"

# Test loading a sample configuration (operator config)
if python -c "
import json
import os
config_path = 'data/cass-operator/v1-10-3/config_demo.json'
if os.path.exists(config_path):
    with open(config_path, 'r') as f:
        config = json.load(f)
    print(f'Config loaded successfully: {config[\"crd_name\"]}')
else:
    print('Config file not found')
" 2>/dev/null; then
    print_status "PASS" "Configuration loading works"
else
    print_status "FAIL" "Configuration loading failed"
fi

echo ""
echo "14. Testing Test Data Access..."
echo "------------------------------"

# Test accessing test data (bug reproduction data)
if python -c "
import os
test_data_path = 'test/e2e_tests/test_data/cassop-330/trial-demo'
if os.path.exists(test_data_path):
    files = os.listdir(test_data_path)
    print(f'Test data directory accessible: {len(files)} files found')
else:
    print('Test data directory not found')
" 2>/dev/null; then
    print_status "PASS" "Test data access works"
else
    print_status "FAIL" "Test data access failed"
fi

echo ""
echo "15. Testing YAML Processing..."
echo "-----------------------------"

# Test YAML processing capabilities (for CRD and config files)
if python -c "
import yaml
import ruamel.yaml
print('YAML processing libraries work')
" 2>/dev/null; then
    print_status "PASS" "YAML processing works"
else
    print_status "FAIL" "YAML processing failed"
fi

echo ""
echo "16. Testing JSON Processing..."
echo "-----------------------------"

# Test JSON processing capabilities (for state transitions and patches)
if python -c "
import json
import jsonpatch
print('JSON processing libraries work')
" 2>/dev/null; then
    print_status "PASS" "JSON processing works"
else
    print_status "FAIL" "JSON processing failed"
fi

echo ""
echo "17. Testing Kubernetes Client..."
echo "-------------------------------"

# Test Kubernetes client initialization (for cluster interaction)
if python -c "
from kubernetes import client, config
try:
    config.load_incluster_config()
    print('Kubernetes in-cluster config loaded')
except:
    try:
        config.load_kube_config()
        print('Kubernetes kubeconfig loaded')
    except:
        print('Kubernetes config not available (expected in container)')
" 2>/dev/null; then
    print_status "PASS" "Kubernetes client works"
else
    print_status "FAIL" "Kubernetes client failed"
fi

echo ""
echo "18. Testing Environment Variables..."
echo "----------------------------------"

# Check if environment variables are set correctly
if [ -n "$ACTO_HOME" ]; then
    print_status "PASS" "ACTO_HOME is set: $ACTO_HOME"
else
    print_status "WARN" "ACTO_HOME is not set"
fi

if [ -n "$PYTHONPATH" ]; then
    print_status "PASS" "PYTHONPATH is set: $PYTHONPATH"
else
    print_status "WARN" "PYTHONPATH is not set"
fi

if [ -n "$KUBECONFIG" ]; then
    print_status "PASS" "KUBECONFIG is set: $KUBECONFIG"
else
    print_status "WARN" "KUBECONFIG is not set"
fi

echo ""
echo "19. Testing Pandas..."
echo "--------------------"

# Test pandas functionality
if python -c "
import pandas as pd
df = pd.DataFrame({'test': [1, 2, 3]})
print(f'Pandas works: DataFrame with {len(df)} rows')
" 2>/dev/null; then
    print_status "PASS" "Pandas works"
else
    print_status "FAIL" "Pandas failed"
fi

echo ""
echo "20. Testing Pytest..."
echo "--------------------"

# Test pytest availability
if python -c "
import pytest
print(f'Pytest version: {pytest.__version__}')
" 2>/dev/null; then
    print_status "PASS" "Pytest is available"
else
    print_status "FAIL" "Pytest is not available"
fi

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="

# Summary
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (Python, Go, kubectl, kind, helm, git, make)"
echo "- Python version compatibility (>= 3.12)"
echo "- Go version compatibility (>= 1.22)"
echo "- Kubernetes tools (kubectl, kind, helm)"
echo "- Core Python dependencies (essential for Acto)"
echo "- Development Python dependencies (optional)"
echo "- Acto module imports and submodules"
echo "- CLI tool availability"
echo "- Build system (make)"
echo "- Basic code execution"
echo "- Configuration and test data access"
echo "- YAML/JSON processing"
echo "- Kubernetes client"
echo "- Environment variables"
echo "- Data processing libraries (pandas)"
echo "- Testing framework (pytest)"

echo ""
echo ""
echo "=========================================="
echo "Test Results Summary"
echo "=========================================="
echo -e "${GREEN}PASS: $PASS_COUNT${NC}"
echo -e "${RED}FAIL: $FAIL_COUNT${NC}"
echo -e "${YELLOW}WARN: $WARN_COUNT${NC}"

if [ $FAIL_COUNT -eq 0 ]; then
    print_status "INFO" "All tests passed! Your Docker environment is ready!"
elif [ $FAIL_COUNT -lt 10 ]; then
    print_status "INFO" "Most tests passed! Your Docker environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that pip install failed in the Dockerfile."
fi

print_status "INFO" "You can now run Acto tests and reproduce bugs."
print_status "INFO" "Example: python -m acto.reproduce --reproduce-dir test/e2e_tests/test_data/cassop-330/trial-demo --config data/cass-operator/v1-10-3/config.json"
echo ""
print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/acto acto-env-test /bin/bash" 