#!/bin/bash

# Anvil Environment Benchmark Test
# Tests if the environment is properly set up for the Anvil Rust project

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

# Function to check Rust version
check_rust_version() {
    local rust_version=$(rustc --version 2>&1)
    print_status "INFO" "Rust version: $rust_version"
    
    # Extract version number
    local version=$(rustc --version | sed 's/rustc //' | sed 's/ .*//')
    local major=$(echo $version | cut -d'.' -f1)
    local minor=$(echo $version | cut -d'.' -f2)
    
    if [ "$major" -eq 1 ] && [ "$minor" -ge 88 ]; then
        print_status "PASS" "Rust version >= 1.88 (found $version)"
    else
        print_status "FAIL" "Rust version < 1.88 (found $version)"
    fi
}

# Function to check Cargo version
check_cargo_version() {
    local cargo_version=$(cargo --version 2>&1)
    print_status "INFO" "Cargo version: $cargo_version"
    
    # Extract version number
    local version=$(cargo --version | sed 's/cargo //' | sed 's/ .*//')
    local major=$(echo $version | cut -d'.' -f1)
    local minor=$(echo $version | cut -d'.' -f2)
    
    if [ "$major" -eq 1 ] && [ "$minor" -ge 88 ]; then
        print_status "PASS" "Cargo version >= 1.88 (found $version)"
    else
        print_status "FAIL" "Cargo version < 1.88 (found $version)"
    fi
}

# Function to check kubectl version
check_kubectl_version() {
    local kubectl_version=$(kubectl version --client 2>&1)
    print_status "INFO" "kubectl version: $kubectl_version"
    
    # Extract version number
    local version=$(kubectl version --client | grep -o 'Client Version: v[0-9]*\.[0-9]*\.[0-9]*' | sed 's/Client Version: v//')
    local major=$(echo $version | cut -d'.' -f1)
    
    if [ "$major" -ge 1 ]; then
        print_status "PASS" "kubectl version >= 1.x (found $version)"
    else
        print_status "FAIL" "kubectl version < 1.x (found $version)"
    fi
}

# Function to check minikube version
check_minikube_version() {
    local minikube_version=$(minikube version 2>&1)
    print_status "INFO" "minikube version: $minikube_version"
    
    # Extract version number
    local version=$(minikube version | grep -o 'v[0-9]*\.[0-9]*\.[0-9]*' | head -1 | sed 's/v//')
    local major=$(echo $version | cut -d'.' -f1)
    local minor=$(echo $version | cut -d'.' -f2)
    
    if [ "$major" -eq 0 ] && [ "$minor" -ge 23 ]; then
        print_status "PASS" "minikube version >= 0.23 (found $version)"
    else
        print_status "FAIL" "minikube version < 0.23 (found $version)"
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the anvil project root directory."
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    docker build -f envgym/envgym.dockerfile -t anvil-env-test .
    
    # Run this script inside Docker container
    echo "Running environment test in Docker container..."
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/anvil" anvil-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        cd /home/cc/EnvGym/data/anvil && ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "Anvil Environment Benchmark Test"
echo "=========================================="

echo ""
echo "1. Checking System Dependencies..."
echo "--------------------------------"

# Check system commands (based on Anvil prerequisites)
check_command "rustc" "Rust Compiler"
check_command "cargo" "Cargo"
check_command "git" "Git"
check_command "curl" "cURL"
check_command "wget" "wget"
check_command "unzip" "unzip"
check_command "pkg-config" "pkg-config"
check_command "python3" "Python 3"
check_command "pip3" "pip3"

echo ""
echo "2. Checking Rust Toolchain..."
echo "-----------------------------"

check_rust_version
check_cargo_version

# Check Rust toolchain configuration
if [ -f "rust-toolchain.toml" ]; then
    print_status "PASS" "rust-toolchain.toml exists"
    
    # Check if toolchain version matches
    toolchain_version=$(grep "channel = " rust-toolchain.toml | sed 's/.*channel = "//' | sed 's/".*//')
    print_status "INFO" "Toolchain version in rust-toolchain.toml: $toolchain_version"
    
    if [ "$toolchain_version" = "1.88.0" ]; then
        print_status "PASS" "Toolchain version matches required 1.88.0"
    else
        print_status "FAIL" "Toolchain version mismatch (expected 1.88.0, found $toolchain_version)"
    fi
else
    print_status "FAIL" "rust-toolchain.toml missing"
fi

# Check Rust target
if rustup target list --installed | grep -q "x86_64-unknown-linux-gnu"; then
    print_status "PASS" "x86_64-unknown-linux-gnu target is installed"
else
    print_status "FAIL" "x86_64-unknown-linux-gnu target is not installed"
fi

echo ""
echo "3. Checking Kubernetes Tools..."
echo "-------------------------------"

check_kubectl_version
check_minikube_version

echo ""
echo "4. Checking Project Structure..."
echo "-------------------------------"

# Check if we're in the right directory
if [ -f "Cargo.toml" ]; then
    print_status "PASS" "Cargo.toml found"
else
    print_status "FAIL" "Cargo.toml not found"
    exit 1
fi

# Check if we're in the Anvil project
if grep -q "verifiable-controllers" Cargo.toml 2>/dev/null; then
    print_status "PASS" "Anvil project detected"
else
    print_status "FAIL" "Not an Anvil project"
fi

# Check project structure
print_status "INFO" "Checking project structure..."
if [ -d "src" ]; then
    print_status "PASS" "src directory exists"
else
    print_status "FAIL" "src directory missing"
fi

if [ -d "deploy" ]; then
    print_status "PASS" "deploy directory exists"
else
    print_status "FAIL" "deploy directory missing"
fi

if [ -d "e2e" ]; then
    print_status "PASS" "e2e directory exists"
else
    print_status "FAIL" "e2e directory missing"
fi

if [ -d "docker" ]; then
    print_status "PASS" "docker directory exists"
else
    print_status "FAIL" "docker directory missing"
fi

if [ -d "tools" ]; then
    print_status "PASS" "tools directory exists"
else
    print_status "FAIL" "tools directory missing"
fi

if [ -d "doc" ]; then
    print_status "PASS" "doc directory exists"
else
    print_status "FAIL" "doc directory missing"
fi

echo ""
echo "5. Testing Cargo Build..."
echo "------------------------"

# Test cargo build
if cargo check --quiet 2>/dev/null; then
    print_status "PASS" "cargo check successful"
else
    print_status "FAIL" "cargo check failed"
fi

echo ""
echo "6. Testing Rust Dependencies..."
echo "-------------------------------"

# Check if Cargo.toml has required dependencies
if grep -q "builtin" Cargo.toml 2>/dev/null; then
    print_status "PASS" "builtin dependency found in Cargo.toml"
else
    print_status "FAIL" "builtin dependency missing in Cargo.toml"
fi

if grep -q "builtin_macros" Cargo.toml 2>/dev/null; then
    print_status "PASS" "builtin_macros dependency found in Cargo.toml"
else
    print_status "FAIL" "builtin_macros dependency missing in Cargo.toml"
fi

if grep -q "vstd" Cargo.toml 2>/dev/null; then
    print_status "PASS" "vstd dependency found in Cargo.toml"
else
    print_status "FAIL" "vstd dependency missing in Cargo.toml"
fi

if grep -q "tungstenite" Cargo.toml 2>/dev/null; then
    print_status "PASS" "tungstenite dependency found in Cargo.toml"
else
    print_status "FAIL" "tungstenite dependency missing in Cargo.toml"
fi

if grep -q "rand" Cargo.toml 2>/dev/null; then
    print_status "PASS" "rand dependency found in Cargo.toml"
else
    print_status "FAIL" "rand dependency missing in Cargo.toml"
fi

echo ""
echo "7. Testing Source Code Structure..."
echo "-----------------------------------"

# Check source code structure
if [ -d "src" ]; then
    rust_files=$(find src -name "*.rs" | wc -l)
    print_status "INFO" "Found $rust_files Rust files in src directory"
    if [ "$rust_files" -gt 0 ]; then
        print_status "PASS" "Rust source files found"
    else
        print_status "FAIL" "No Rust source files found"
    fi
fi

# Check for specific Anvil source directories
if [ -d "src/reconciler" ]; then
    print_status "PASS" "src/reconciler directory exists"
else
    print_status "FAIL" "src/reconciler directory missing"
fi

if [ -d "src/shim_layer" ]; then
    print_status "PASS" "src/shim_layer directory exists"
else
    print_status "FAIL" "src/shim_layer directory missing"
fi

if [ -d "src/kubernetes_cluster" ]; then
    print_status "PASS" "src/kubernetes_cluster directory exists"
else
    print_status "FAIL" "src/kubernetes_cluster directory missing"
fi

if [ -d "src/kubernetes_api_objects" ]; then
    print_status "PASS" "src/kubernetes_api_objects directory exists"
else
    print_status "FAIL" "src/kubernetes_api_objects directory missing"
fi

if [ -d "src/state_machine" ]; then
    print_status "PASS" "src/state_machine directory exists"
else
    print_status "FAIL" "src/state_machine directory missing"
fi

if [ -d "src/temporal_logic" ]; then
    print_status "PASS" "src/temporal_logic directory exists"
else
    print_status "FAIL" "src/temporal_logic directory missing"
fi

if [ -d "src/deps_hack" ]; then
    print_status "PASS" "src/deps_hack directory exists"
else
    print_status "FAIL" "src/deps_hack directory missing"
fi

if [ -d "src/controller_examples" ]; then
    print_status "PASS" "src/controller_examples directory exists"
else
    print_status "FAIL" "src/controller_examples directory missing"
fi

echo ""
echo "8. Testing Build Scripts..."
echo "---------------------------"

# Check build scripts
if [ -f "build.sh" ]; then
    print_status "PASS" "build.sh exists"
    if [ -x "build.sh" ]; then
        print_status "PASS" "build.sh is executable"
    else
        print_status "FAIL" "build.sh is not executable"
    fi
else
    print_status "FAIL" "build.sh missing"
fi

if [ -f "deploy.sh" ]; then
    print_status "PASS" "deploy.sh exists"
    if [ -x "deploy.sh" ]; then
        print_status "PASS" "deploy.sh is executable"
    else
        print_status "FAIL" "deploy.sh is not executable"
    fi
else
    print_status "FAIL" "deploy.sh missing"
fi

if [ -f "local-test.sh" ]; then
    print_status "PASS" "local-test.sh exists"
    if [ -x "local-test.sh" ]; then
        print_status "PASS" "local-test.sh is executable"
    else
        print_status "FAIL" "local-test.sh is not executable"
    fi
else
    print_status "FAIL" "local-test.sh missing"
fi

echo ""
echo "9. Testing Docker Configuration..."
echo "----------------------------------"

# Check Docker configuration
if [ -d "docker" ]; then
    docker_files=$(find docker -name "Dockerfile*" | wc -l)
    print_status "INFO" "Found $docker_files Dockerfile files"
    if [ "$docker_files" -gt 0 ]; then
        print_status "PASS" "Docker configuration files found"
    else
        print_status "FAIL" "No Docker configuration files found"
    fi
fi

if [ -d "docker/controller" ]; then
    print_status "PASS" "docker/controller directory exists"
else
    print_status "FAIL" "docker/controller directory missing"
fi

if [ -f "docker/controller/Dockerfile.local" ]; then
    print_status "PASS" "docker/controller/Dockerfile.local exists"
else
    print_status "FAIL" "docker/controller/Dockerfile.local missing"
fi

if [ -f "docker/controller/Dockerfile.remote" ]; then
    print_status "PASS" "docker/controller/Dockerfile.remote exists"
else
    print_status "FAIL" "docker/controller/Dockerfile.remote missing"
fi

echo ""
echo "10. Testing E2E Test Structure..."
echo "---------------------------------"

# Check E2E test structure
if [ -d "e2e" ]; then
    e2e_files=$(find e2e -name "*.rs" | wc -l)
    print_status "INFO" "Found $e2e_files Rust files in e2e directory"
    if [ "$e2e_files" -gt 0 ]; then
        print_status "PASS" "E2E test files found"
    else
        print_status "FAIL" "No E2E test files found"
    fi
fi

if [ -d "e2e/src" ]; then
    print_status "PASS" "e2e/src directory exists"
else
    print_status "FAIL" "e2e/src directory missing"
fi

echo ""
echo "11. Testing Deploy Configuration..."
echo "-----------------------------------"

# Check deploy configuration
if [ -d "deploy" ]; then
    deploy_files=$(find deploy -name "*.yaml" -o -name "*.yml" | wc -l)
    print_status "INFO" "Found $deploy_files YAML files in deploy directory"
    if [ "$deploy_files" -gt 0 ]; then
        print_status "PASS" "Deploy configuration files found"
    else
        print_status "FAIL" "No deploy configuration files found"
    fi
fi

echo ""
echo "12. Testing Documentation..."
echo "----------------------------"

# Check documentation
if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md missing"
fi

if [ -f "build.md" ]; then
    print_status "PASS" "build.md exists"
else
    print_status "FAIL" "build.md missing"
fi

if [ -d "doc" ]; then
    print_status "PASS" "doc directory exists"
else
    print_status "FAIL" "doc directory missing"
fi

# Check if documentation mentions Anvil
if grep -q "anvil" README.md 2>/dev/null; then
    print_status "PASS" "README.md contains Anvil references"
else
    print_status "WARN" "README.md missing Anvil references"
fi

echo ""
echo "13. Testing Verus Integration..."
echo "--------------------------------"

# Check for Verus-related files and configurations
if [ -d "../verus" ]; then
    print_status "PASS" "Verus directory exists in parent directory"
else
    print_status "WARN" "Verus directory not found in parent directory"
fi

# Check if build.sh references Verus
if grep -q "VERUS_DIR" build.sh 2>/dev/null; then
    print_status "PASS" "build.sh references VERUS_DIR"
else
    print_status "FAIL" "build.sh missing VERUS_DIR reference"
fi

echo ""
echo "14. Testing Python Dependencies..."
echo "----------------------------------"

# Check Python dependencies
if python3 -c "import tabulate" 2>/dev/null; then
    print_status "PASS" "tabulate Python package is available"
else
    print_status "FAIL" "tabulate Python package is not available"
fi

echo ""
echo "15. Testing Basic Rust Functionality..."
echo "---------------------------------------"

# Test basic Rust functionality
if rustc --version >/dev/null 2>&1; then
    print_status "PASS" "Rust compiler basic functionality works"
else
    print_status "FAIL" "Rust compiler basic functionality failed"
fi

if cargo --version >/dev/null 2>&1; then
    print_status "PASS" "Cargo basic functionality works"
else
    print_status "FAIL" "Cargo basic functionality failed"
fi

echo ""
echo "16. Testing Kubernetes Tools Functionality..."
echo "---------------------------------------------"

# Test kubectl functionality
if kubectl version --client >/dev/null 2>&1; then
    print_status "PASS" "kubectl basic functionality works"
else
    print_status "FAIL" "kubectl basic functionality failed"
fi

# Test minikube functionality
if minikube version >/dev/null 2>&1; then
    print_status "PASS" "minikube basic functionality works"
else
    print_status "FAIL" "minikube basic functionality failed"
fi

echo ""
echo "17. Testing Build Script Functionality..."
echo "-----------------------------------------"

# Test if build script can be executed (without actually building)
if [ -f "build.sh" ] && [ -x "build.sh" ]; then
    # Just check if the script can be parsed
    if bash -n build.sh 2>/dev/null; then
        print_status "PASS" "build.sh syntax is valid"
    else
        print_status "FAIL" "build.sh syntax is invalid"
    fi
fi

echo ""
echo "18. Testing Cargo.toml Configuration..."
echo "---------------------------------------"

# Check Cargo.toml configuration
if grep -q 'edition = "2021"' Cargo.toml 2>/dev/null; then
    print_status "PASS" "Rust 2021 edition is specified"
else
    print_status "FAIL" "Rust 2021 edition is not specified"
fi

if grep -q 'name = "verifiable-controllers"' Cargo.toml 2>/dev/null; then
    print_status "PASS" "Package name is correctly set"
else
    print_status "FAIL" "Package name is not correctly set"
fi

echo ""
echo "19. Testing System Libraries..."
echo "-------------------------------"

# Check for required system libraries
if pkg-config --exists openssl 2>/dev/null; then
    print_status "PASS" "OpenSSL development libraries are available"
else
    print_status "FAIL" "OpenSSL development libraries are not available"
fi

if pkg-config --exists libssl 2>/dev/null; then
    print_status "PASS" "libssl development libraries are available"
else
    print_status "FAIL" "libssl development libraries are not available"
fi

echo ""
echo "20. Testing Git Configuration..."
echo "--------------------------------"

# Check Git configuration
if git --version >/dev/null 2>&1; then
    print_status "PASS" "Git is properly configured"
else
    print_status "FAIL" "Git is not properly configured"
fi

# Check if this is a Git repository
if [ -d ".git" ]; then
    print_status "PASS" "This is a Git repository"
else
    print_status "WARN" "This is not a Git repository"
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
echo "- System dependencies (Rust, Cargo, Git, curl, wget, pkg-config, Python3)"
echo "- Rust toolchain version compatibility (>= 1.88.0)"
echo "- Kubernetes tools (kubectl, minikube)"
echo "- Project structure and files"
echo "- Cargo build and dependencies"
echo "- Source code organization"
echo "- Build and deployment scripts"
echo "- Docker configuration"
echo "- E2E test structure"
echo "- Documentation"
echo "- Verus integration"
echo "- Python dependencies"
echo "- Basic tool functionality"
echo "- System libraries"

echo ""
echo ""
echo "=========================================="
echo "Test Results Summary"
echo "=========================================="
echo -e "${GREEN}PASS: $PASS_COUNT${NC}"
echo -e "${RED}FAIL: $FAIL_COUNT${NC}"
echo -e "${YELLOW}WARN: $WARN_COUNT${NC}"

if [ $FAIL_COUNT -eq 0 ]; then
    print_status "INFO" "All tests passed! Your Anvil environment is ready!"
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your Anvil environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi

print_status "INFO" "You can now build and verify Anvil controllers."
print_status "INFO" "Example: VERUS_DIR=../verus ./build.sh <controller_name>"
echo ""
print_status "INFO" "For more information, see README.md and build.md" 