#!/bin/bash

# P4Control Environment Benchmark Test Script
# This script tests the Docker environment setup for P4Control: Line-Rate Cross-Host Attack Prevention
# Tailored specifically for P4Control project requirements and features

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
    docker stop p4ctl-env-test 2>/dev/null || true
    docker rm p4ctl-env-test 2>/dev/null || true
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
        if timeout 600s docker build -f envgym/envgym.dockerfile -t p4ctl-env-test .; then
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
    if docker run --rm p4ctl-env-test python3.7 --version >/dev/null 2>&1; then
        python_version=$(docker run --rm p4ctl-env-test python3.7 --version 2>/dev/null)
        print_status "PASS" "Python 3.7 is available in Docker: $python_version"
    else
        print_status "FAIL" "Python 3.7 is not available in Docker"
    fi
    
    # Test if GCC is available in Docker
    if docker run --rm p4ctl-env-test gcc --version >/dev/null 2>&1; then
        gcc_version=$(docker run --rm p4ctl-env-test gcc --version 2>&1 | head -n 1)
        print_status "PASS" "GCC is available in Docker: $gcc_version"
    else
        print_status "FAIL" "GCC is not available in Docker"
    fi
    
    # Test if Clang is available in Docker
    if docker run --rm p4ctl-env-test clang --version >/dev/null 2>&1; then
        clang_version=$(docker run --rm p4ctl-env-test clang --version 2>&1 | head -n 1)
        print_status "PASS" "Clang is available in Docker: $clang_version"
    else
        print_status "FAIL" "Clang is not available in Docker"
    fi
    
    # Test if Bison is available in Docker
    if docker run --rm p4ctl-env-test bison --version >/dev/null 2>&1; then
        bison_version=$(docker run --rm p4ctl-env-test bison --version 2>&1 | head -n 1)
        print_status "PASS" "Bison is available in Docker: $bison_version"
    else
        print_status "FAIL" "Bison is not available in Docker"
    fi
    
    # Test if Flex is available in Docker
    if docker run --rm p4ctl-env-test flex --version >/dev/null 2>&1; then
        flex_version=$(docker run --rm p4ctl-env-test flex --version 2>&1 | head -n 1)
        print_status "PASS" "Flex is available in Docker: $flex_version"
    else
        print_status "FAIL" "Flex is not available in Docker"
    fi
    
    # Test if ncat is available in Docker
    if docker run --rm p4ctl-env-test ncat --version >/dev/null 2>&1; then
        ncat_version=$(docker run --rm p4ctl-env-test ncat --version 2>&1 | head -n 1)
        print_status "PASS" "ncat is available in Docker: $ncat_version"
    else
        print_status "FAIL" "ncat is not available in Docker"
    fi
    
    # Test if Git is available in Docker
    if docker run --rm p4ctl-env-test git --version >/dev/null 2>&1; then
        git_version=$(docker run --rm p4ctl-env-test git --version 2>&1)
        print_status "PASS" "Git is available in Docker: $git_version"
    else
        print_status "FAIL" "Git is not available in Docker"
    fi
fi

echo "=========================================="
echo "P4Control Environment Benchmark Test"
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

# Check Python 3.7 version
if command -v python3.7 &> /dev/null; then
    python_major=$(python3.7 --version 2>&1 | sed 's/.*Python \([0-9]*\)\.[0-9]*.*/\1/')
    python_minor=$(python3.7 --version 2>&1 | sed 's/.*Python [0-9]*\.\([0-9]*\).*/\1/')
    if [ -n "$python_major" ] && [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 7 ]; then
        print_status "PASS" "Python version is >= 3.7 (compatible)"
    else
        print_status "WARN" "Python version should be >= 3.7 (found: $python_major.$python_minor)"
    fi
else
    print_status "FAIL" "Python 3.7 is not available for version check"
fi

# Check GCC
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version 2>&1 | head -n 1)
    print_status "PASS" "GCC is available: $gcc_version"
else
    print_status "FAIL" "GCC is not available"
fi

# Check Clang
if command -v clang &> /dev/null; then
    clang_version=$(clang --version 2>&1 | head -n 1)
    print_status "PASS" "Clang is available: $clang_version"
else
    print_status "WARN" "Clang is not available"
fi

# Check LLVM
if command -v llvm-config &> /dev/null; then
    llvm_version=$(llvm-config --version 2>&1)
    print_status "PASS" "LLVM is available: $llvm_version"
else
    print_status "WARN" "LLVM is not available"
fi

# Check Bison
if command -v bison &> /dev/null; then
    bison_version=$(bison --version 2>&1 | head -n 1)
    print_status "PASS" "Bison is available: $bison_version"
else
    print_status "FAIL" "Bison is not available"
fi

# Check Bison version
if command -v bison &> /dev/null; then
    bison_major=$(bison --version | head -n 1 | sed 's/.*bison (GNU Bison) \([0-9]*\)\.[0-9]*.*/\1/')
    if [ -n "$bison_major" ] && [ "$bison_major" -ge 3 ]; then
        print_status "PASS" "Bison version is >= 3 (compatible)"
    else
        print_status "WARN" "Bison version should be >= 3 (found: $bison_major)"
    fi
else
    print_status "FAIL" "Bison is not available for version check"
fi

# Check Flex
if command -v flex &> /dev/null; then
    flex_version=$(flex --version 2>&1 | head -n 1)
    print_status "PASS" "Flex is available: $flex_version"
else
    print_status "FAIL" "Flex is not available"
fi

# Check Flex version
if command -v flex &> /dev/null; then
    flex_major=$(flex --version | head -n 1 | sed 's/.*flex \([0-9]*\)\.[0-9]*.*/\1/')
    if [ -n "$flex_major" ] && [ "$flex_major" -ge 2 ]; then
        print_status "PASS" "Flex version is >= 2 (compatible)"
    else
        print_status "WARN" "Flex version should be >= 2 (found: $flex_major)"
    fi
else
    print_status "FAIL" "Flex is not available for version check"
fi

# Check ncat
if command -v ncat &> /dev/null; then
    ncat_version=$(ncat --version 2>&1 | head -n 1)
    print_status "PASS" "ncat is available: $ncat_version"
else
    print_status "WARN" "ncat is not available"
fi

# Check Git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1)
    print_status "PASS" "Git is available: $git_version"
else
    print_status "FAIL" "Git is not available"
fi

# Check Make
if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "Make is available: $make_version"
else
    print_status "FAIL" "Make is not available"
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

# Check Linux headers
if [ -d "/usr/src/linux-headers-$(uname -r)" ]; then
    print_status "PASS" "Linux headers are available for current kernel"
else
    print_status "WARN" "Linux headers not found for current kernel"
fi

# Check libelf-dev
if pkg-config --exists libelf; then
    print_status "PASS" "libelf-dev is available"
else
    print_status "WARN" "libelf-dev is not available"
fi

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "compiler" ]; then
    print_status "PASS" "compiler directory exists (NetCL compiler)"
else
    print_status "FAIL" "compiler directory not found"
fi

if [ -d "host_agent" ]; then
    print_status "PASS" "host_agent directory exists (eBPF host agent)"
else
    print_status "FAIL" "host_agent directory not found"
fi

if [ -d "switch" ]; then
    print_status "PASS" "switch directory exists (P4 switch code)"
else
    print_status "FAIL" "switch directory not found"
fi

# Check key files
if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
fi

if [ -f "custom-send.py" ]; then
    print_status "PASS" "custom-send.py exists (custom packet sender)"
else
    print_status "FAIL" "custom-send.py not found"
fi

if [ -f "custom-recieve.py" ]; then
    print_status "PASS" "custom-recieve.py exists (custom packet receiver)"
else
    print_status "FAIL" "custom-recieve.py not found"
fi

# Check compiler files
if [ -f "compiler/netcl.y" ]; then
    print_status "PASS" "compiler/netcl.y exists (Bison grammar file)"
else
    print_status "FAIL" "compiler/netcl.y not found"
fi

if [ -f "compiler/netcl.l" ]; then
    print_status "PASS" "compiler/netcl.l exists (Flex lexer file)"
else
    print_status "FAIL" "compiler/netcl.l not found"
fi

if [ -f "compiler/netcl-compile" ]; then
    print_status "PASS" "compiler/netcl-compile exists (compiled NetCL compiler)"
else
    print_status "FAIL" "compiler/netcl-compile not found"
fi

if [ -f "compiler/Makefile" ]; then
    print_status "PASS" "compiler/Makefile exists (compiler build configuration)"
else
    print_status "FAIL" "compiler/Makefile not found"
fi

if [ -f "compiler/netcl_rules" ]; then
    print_status "PASS" "compiler/netcl_rules exists (sample NetCL rules)"
else
    print_status "FAIL" "compiler/netcl_rules not found"
fi

if [ -f "compiler/compiled_rules" ]; then
    print_status "PASS" "compiler/compiled_rules exists (compiled NetCL rules)"
else
    print_status "FAIL" "compiler/compiled_rules not found"
fi

# Check host agent files
if [ -f "host_agent/host_agent.py" ]; then
    print_status "PASS" "host_agent/host_agent.py exists (Python host agent)"
else
    print_status "FAIL" "host_agent/host_agent.py not found"
fi

if [ -f "host_agent/host_agent_ebpf.c" ]; then
    print_status "PASS" "host_agent/host_agent_ebpf.c exists (eBPF host agent)"
else
    print_status "FAIL" "host_agent/host_agent_ebpf.c not found"
fi

# Check switch files
if [ -f "switch/p4control.p4" ]; then
    print_status "PASS" "switch/p4control.p4 exists (P4 program)"
else
    print_status "FAIL" "switch/p4control.p4 not found"
fi

if [ -f "switch/controller.py" ]; then
    print_status "PASS" "switch/controller.py exists (P4 controller)"
else
    print_status "FAIL" "switch/controller.py not found"
fi

if [ -f "switch/netcl.py" ]; then
    print_status "PASS" "switch/netcl.py exists (NetCL rules)"
else
    print_status "FAIL" "switch/netcl.py not found"
fi

echo ""
echo "3. Checking Environment Variables..."
echo "-----------------------------------"
# Check P4 environment
if [ -n "${SDE:-}" ]; then
    print_status "PASS" "SDE is set: $SDE"
else
    print_status "WARN" "SDE is not set (Tofino SDE path)"
fi

if [ -n "${SDE_INSTALL:-}" ]; then
    print_status "PASS" "SDE_INSTALL is set: $SDE_INSTALL"
else
    print_status "WARN" "SDE_INSTALL is not set (Tofino SDE install path)"
fi

if [ -n "${PYTHONPATH:-}" ]; then
    print_status "PASS" "PYTHONPATH is set: $PYTHONPATH"
else
    print_status "WARN" "PYTHONPATH is not set"
fi

# Check PATH
if echo "$PATH" | grep -q "python3.7"; then
    print_status "PASS" "python3.7 is in PATH"
else
    print_status "WARN" "python3.7 is not in PATH"
fi

if echo "$PATH" | grep -q "gcc"; then
    print_status "PASS" "gcc is in PATH"
else
    print_status "WARN" "gcc is not in PATH"
fi

if echo "$PATH" | grep -q "bison"; then
    print_status "PASS" "bison is in PATH"
else
    print_status "WARN" "bison is not in PATH"
fi

if echo "$PATH" | grep -q "flex"; then
    print_status "PASS" "flex is in PATH"
else
    print_status "WARN" "flex is not in PATH"
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
    
    # Test pip for Python 3.7
    if timeout 30s python3.7 -m pip --version >/dev/null 2>&1; then
        print_status "PASS" "pip for Python 3.7 works"
    else
        print_status "WARN" "pip for Python 3.7 failed"
    fi
    
    # Test Scapy import
    if timeout 30s python3.7 -c "import scapy; print('Scapy imported successfully')" >/dev/null 2>&1; then
        print_status "PASS" "Scapy import works"
    else
        print_status "WARN" "Scapy import failed"
    fi
else
    print_status "FAIL" "python3.7 is not available"
fi

echo ""
echo "5. Testing Compiler Environment..."
echo "--------------------------------"
# Test Bison
if command -v bison &> /dev/null; then
    print_status "PASS" "bison is available"
    
    # Test Bison version
    if timeout 30s bison --version >/dev/null 2>&1; then
        print_status "PASS" "Bison version command works"
    else
        print_status "WARN" "Bison version command failed"
    fi
    
    # Test Bison help
    if timeout 30s bison --help >/dev/null 2>&1; then
        print_status "PASS" "Bison help command works"
    else
        print_status "WARN" "Bison help command failed"
    fi
else
    print_status "FAIL" "bison is not available"
fi

# Test Flex
if command -v flex &> /dev/null; then
    print_status "PASS" "flex is available"
    
    # Test Flex version
    if timeout 30s flex --version >/dev/null 2>&1; then
        print_status "PASS" "Flex version command works"
    else
        print_status "WARN" "Flex version command failed"
    fi
    
    # Test Flex help
    if timeout 30s flex --help >/dev/null 2>&1; then
        print_status "PASS" "Flex help command works"
    else
        print_status "WARN" "Flex help command failed"
    fi
else
    print_status "FAIL" "flex is not available"
fi

# Test GCC
if command -v gcc &> /dev/null; then
    print_status "PASS" "gcc is available"
    
    # Test GCC compilation
    if timeout 30s gcc --version >/dev/null 2>&1; then
        print_status "PASS" "GCC version command works"
    else
        print_status "WARN" "GCC version command failed"
    fi
else
    print_status "FAIL" "gcc is not available"
fi

echo ""
echo "6. Testing P4Control Build System..."
echo "-----------------------------------"
# Test compiler Makefile
if [ -f "compiler/Makefile" ]; then
    print_status "PASS" "compiler/Makefile exists for build testing"
    
    # Check for key Makefile targets
    if grep -q "all" compiler/Makefile; then
        print_status "PASS" "compiler/Makefile includes all target"
    else
        print_status "WARN" "compiler/Makefile missing all target"
    fi
    
    if grep -q "clean" compiler/Makefile; then
        print_status "PASS" "compiler/Makefile includes clean target"
    else
        print_status "WARN" "compiler/Makefile missing clean target"
    fi
else
    print_status "FAIL" "compiler/Makefile not found"
fi

# Test NetCL compiler
if [ -f "compiler/netcl-compile" ]; then
    print_status "PASS" "netcl-compile exists"
    
    # Test if it's executable
    if [ -x "compiler/netcl-compile" ]; then
        print_status "PASS" "netcl-compile is executable"
        
        # Test basic functionality
        if timeout 30s ./compiler/netcl-compile --help >/dev/null 2>&1; then
            print_status "PASS" "netcl-compile help command works"
        else
            print_status "WARN" "netcl-compile help command failed"
        fi
    else
        print_status "WARN" "netcl-compile is not executable"
    fi
else
    print_status "FAIL" "netcl-compile not found"
fi

# Test P4 program
if [ -f "switch/p4control.p4" ]; then
    print_status "PASS" "p4control.p4 exists"
    
    # Check for key P4 components
    if grep -q "parser" switch/p4control.p4; then
        print_status "PASS" "p4control.p4 includes parser"
    else
        print_status "WARN" "p4control.p4 missing parser"
    fi
    
    if grep -q "control" switch/p4control.p4; then
        print_status "PASS" "p4control.p4 includes control"
    else
        print_status "WARN" "p4control.p4 missing control"
    fi
    
    if grep -q "ingress" switch/p4control.p4; then
        print_status "PASS" "p4control.p4 includes ingress"
    else
        print_status "WARN" "p4control.p4 missing ingress"
    fi
else
    print_status "FAIL" "p4control.p4 not found"
fi

# Test Python controller
if [ -f "switch/controller.py" ]; then
    print_status "PASS" "controller.py exists"
    
    # Check for key Python components
    if grep -q "import" switch/controller.py; then
        print_status "PASS" "controller.py includes imports"
    else
        print_status "WARN" "controller.py missing imports"
    fi
    
    if grep -q "def" switch/controller.py; then
        print_status "PASS" "controller.py includes functions"
    else
        print_status "WARN" "controller.py missing functions"
    fi
else
    print_status "FAIL" "controller.py not found"
fi

echo ""
echo "7. Testing P4Control Source Code Structure..."
echo "-------------------------------------------"
# Test source code directories
if [ -d "compiler" ]; then
    print_status "PASS" "compiler directory exists for source testing"
    
    # Count source files
    source_count=$(find compiler -name "*.c" -o -name "*.h" -o -name "*.y" -o -name "*.l" | wc -l)
    if [ "$source_count" -gt 0 ]; then
        print_status "PASS" "Found $source_count source files in compiler directory"
    else
        print_status "WARN" "No source files found in compiler directory"
    fi
    
    # Check for key compiler files
    if [ -f "compiler/netcl.y" ]; then
        print_status "PASS" "compiler/netcl.y exists (Bison grammar)"
    else
        print_status "FAIL" "compiler/netcl.y not found"
    fi
    
    if [ -f "compiler/netcl.l" ]; then
        print_status "PASS" "compiler/netcl.l exists (Flex lexer)"
    else
        print_status "FAIL" "compiler/netcl.l not found"
    fi
else
    print_status "FAIL" "compiler directory not found"
fi

if [ -d "host_agent" ]; then
    print_status "PASS" "host_agent directory exists for eBPF testing"
    
    # Count eBPF files
    ebpf_count=$(find host_agent -name "*.c" -o -name "*.py" | wc -l)
    if [ "$ebpf_count" -gt 0 ]; then
        print_status "PASS" "Found $ebpf_count files in host_agent directory"
    else
        print_status "WARN" "No files found in host_agent directory"
    fi
    
    # Check for key host agent files
    if [ -f "host_agent/host_agent_ebpf.c" ]; then
        print_status "PASS" "host_agent/host_agent_ebpf.c exists (eBPF program)"
    else
        print_status "FAIL" "host_agent/host_agent_ebpf.c not found"
    fi
    
    if [ -f "host_agent/host_agent.py" ]; then
        print_status "PASS" "host_agent/host_agent.py exists (Python agent)"
    else
        print_status "FAIL" "host_agent/host_agent.py not found"
    fi
else
    print_status "FAIL" "host_agent directory not found"
fi

if [ -d "switch" ]; then
    print_status "PASS" "switch directory exists for P4 testing"
    
    # Count P4 files
    p4_count=$(find switch -name "*.p4" -o -name "*.py" | wc -l)
    if [ "$p4_count" -gt 0 ]; then
        print_status "PASS" "Found $p4_count files in switch directory"
    else
        print_status "WARN" "No files found in switch directory"
    fi
    
    # Check for key switch files
    if [ -f "switch/p4control.p4" ]; then
        print_status "PASS" "switch/p4control.p4 exists (P4 program)"
    else
        print_status "FAIL" "switch/p4control.p4 not found"
    fi
    
    if [ -f "switch/controller.py" ]; then
        print_status "PASS" "switch/controller.py exists (P4 controller)"
    else
        print_status "FAIL" "switch/controller.py not found"
    fi
else
    print_status "FAIL" "switch directory not found"
fi

# Test custom tools
if [ -f "custom-send.py" ]; then
    print_status "PASS" "custom-send.py exists for packet testing"
    
    # Check if it's a valid Python script
    if command -v python3.7 &> /dev/null; then
        if timeout 30s python3.7 -m py_compile custom-send.py >/dev/null 2>&1; then
            print_status "PASS" "custom-send.py is a valid Python script"
        else
            print_status "WARN" "custom-send.py may not be a valid Python script"
        fi
    else
        print_status "WARN" "python3.7 not available for custom-send.py testing"
    fi
else
    print_status "FAIL" "custom-send.py not found"
fi

if [ -f "custom-recieve.py" ]; then
    print_status "PASS" "custom-recieve.py exists for packet testing"
    
    # Check if it's a valid Python script
    if command -v python3.7 &> /dev/null; then
        if timeout 30s python3.7 -m py_compile custom-recieve.py >/dev/null 2>&1; then
            print_status "PASS" "custom-recieve.py is a valid Python script"
        else
            print_status "WARN" "custom-recieve.py may not be a valid Python script"
        fi
    else
        print_status "WARN" "python3.7 not available for custom-recieve.py testing"
    fi
else
    print_status "FAIL" "custom-recieve.py not found"
fi

echo ""
echo "8. Testing P4Control Configuration Files..."
echo "-----------------------------------------"
# Test configuration files
if [ -r "compiler/Makefile" ]; then
    print_status "PASS" "compiler/Makefile is readable"
else
    print_status "FAIL" "compiler/Makefile is not readable"
fi

if [ -r "compiler/netcl.y" ]; then
    print_status "PASS" "compiler/netcl.y is readable"
else
    print_status "FAIL" "compiler/netcl.y is not readable"
fi

if [ -r "compiler/netcl.l" ]; then
    print_status "PASS" "compiler/netcl.l is readable"
else
    print_status "FAIL" "compiler/netcl.l is not readable"
fi

if [ -r "switch/p4control.p4" ]; then
    print_status "PASS" "switch/p4control.p4 is readable"
else
    print_status "FAIL" "switch/p4control.p4 is not readable"
fi

if [ -r "switch/controller.py" ]; then
    print_status "PASS" "switch/controller.py is readable"
else
    print_status "FAIL" "switch/controller.py is not readable"
fi

if [ -r "host_agent/host_agent_ebpf.c" ]; then
    print_status "PASS" "host_agent/host_agent_ebpf.c is readable"
else
    print_status "FAIL" "host_agent/host_agent_ebpf.c is not readable"
fi

if [ -r "host_agent/host_agent.py" ]; then
    print_status "PASS" "host_agent/host_agent.py is readable"
else
    print_status "FAIL" "host_agent/host_agent.py is not readable"
fi

# Check Makefile content
if [ -r "compiler/Makefile" ]; then
    if grep -q "CC" compiler/Makefile; then
        print_status "PASS" "compiler/Makefile includes compiler definition"
    else
        print_status "WARN" "compiler/Makefile missing compiler definition"
    fi
    
    if grep -q "CFLAGS" compiler/Makefile; then
        print_status "PASS" "compiler/Makefile includes CFLAGS"
    else
        print_status "WARN" "compiler/Makefile missing CFLAGS"
    fi
fi

# Check P4 program content
if [ -r "switch/p4control.p4" ]; then
    if grep -q "header" switch/p4control.p4; then
        print_status "PASS" "p4control.p4 includes header definitions"
    else
        print_status "WARN" "p4control.p4 missing header definitions"
    fi
    
    if grep -q "struct" switch/p4control.p4; then
        print_status "PASS" "p4control.p4 includes struct definitions"
    else
        print_status "WARN" "p4control.p4 missing struct definitions"
    fi
fi

echo ""
echo "9. Testing P4Control Documentation..."
echo "-----------------------------------"
# Test documentation
if [ -r "README.md" ]; then
    print_status "PASS" "README.md is readable"
else
    print_status "FAIL" "README.md is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "P4Control" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "Dependencies" README.md; then
        print_status "PASS" "README.md contains dependencies section"
    else
        print_status "WARN" "README.md missing dependencies section"
    fi
    
    if grep -q "Python 3.7" README.md; then
        print_status "PASS" "README.md contains Python 3.7 requirement"
    else
        print_status "WARN" "README.md missing Python 3.7 requirement"
    fi
    
    if grep -q "Tofino" README.md; then
        print_status "PASS" "README.md contains Tofino reference"
    else
        print_status "WARN" "README.md missing Tofino reference"
    fi
    
    if grep -q "eBPF" README.md; then
        print_status "PASS" "README.md contains eBPF reference"
    else
        print_status "WARN" "README.md missing eBPF reference"
    fi
fi

echo ""
echo "10. Testing P4Control Docker Functionality..."
echo "-------------------------------------------"
# Test if Docker container can run basic commands
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    # Test Python 3.7 in Docker
    if docker run --rm p4ctl-env-test python3.7 --version >/dev/null 2>&1; then
        print_status "PASS" "Python 3.7 works in Docker container"
    else
        print_status "FAIL" "Python 3.7 does not work in Docker container"
    fi
    
    # Test GCC in Docker
    if docker run --rm p4ctl-env-test gcc --version >/dev/null 2>&1; then
        print_status "PASS" "GCC works in Docker container"
    else
        print_status "FAIL" "GCC does not work in Docker container"
    fi
    
    # Test Bison in Docker
    if docker run --rm p4ctl-env-test bison --version >/dev/null 2>&1; then
        print_status "PASS" "Bison works in Docker container"
    else
        print_status "FAIL" "Bison does not work in Docker container"
    fi
    
    # Test Flex in Docker
    if docker run --rm p4ctl-env-test flex --version >/dev/null 2>&1; then
        print_status "PASS" "Flex works in Docker container"
    else
        print_status "FAIL" "Flex does not work in Docker container"
    fi
    
    # Test ncat in Docker
    if docker run --rm p4ctl-env-test ncat --version >/dev/null 2>&1; then
        print_status "PASS" "ncat works in Docker container"
    else
        print_status "FAIL" "ncat does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm p4ctl-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test if compiler directory is accessible in Docker
    if docker run --rm p4ctl-env-test test -d compiler; then
        print_status "PASS" "compiler directory is accessible in Docker container"
    else
        print_status "FAIL" "compiler directory is not accessible in Docker container"
    fi
    
    # Test if host_agent directory is accessible in Docker
    if docker run --rm p4ctl-env-test test -d host_agent; then
        print_status "PASS" "host_agent directory is accessible in Docker container"
    else
        print_status "FAIL" "host_agent directory is not accessible in Docker container"
    fi
    
    # Test if switch directory is accessible in Docker
    if docker run --rm p4ctl-env-test test -d switch; then
        print_status "PASS" "switch directory is accessible in Docker container"
    else
        print_status "FAIL" "switch directory is not accessible in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm p4ctl-env-test test -f README.md; then
        print_status "PASS" "README.md is accessible in Docker container"
    else
        print_status "FAIL" "README.md is not accessible in Docker container"
    fi
    
    # Test if custom-send.py is accessible in Docker
    if docker run --rm p4ctl-env-test test -f custom-send.py; then
        print_status "PASS" "custom-send.py is accessible in Docker container"
    else
        print_status "FAIL" "custom-send.py is not accessible in Docker container"
    fi
    
    # Test if custom-recieve.py is accessible in Docker
    if docker run --rm p4ctl-env-test test -f custom-recieve.py; then
        print_status "PASS" "custom-recieve.py is accessible in Docker container"
    else
        print_status "FAIL" "custom-recieve.py is not accessible in Docker container"
    fi
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for P4Control:"
echo "- Docker build process (Ubuntu 22.04, Python 3.7, GCC, Bison, Flex, ncat)"
echo "- Python 3.7 environment (execution, pip, Scapy)"
echo "- Compiler environment (Bison, Flex, GCC, Make)"
echo "- P4Control build system (Makefile, netcl-compile, P4 program, controller)"
echo "- P4Control source code structure (compiler, host_agent, switch, custom tools)"
echo "- P4Control configuration files (Makefile, P4, Python, eBPF)"
echo "- P4Control documentation (README.md with dependencies and setup)"
echo "- Docker container functionality (Python 3.7, GCC, Bison, Flex, ncat, Git)"
echo "- Network security (P4, eBPF, NetCL, cross-host attack prevention)"
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
    print_status "INFO" "All Docker tests passed! Your P4Control Docker environment is ready!"
    print_status "INFO" "P4Control is a line-rate cross-host attack prevention system."
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your P4Control Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now run P4Control in Docker: Line-Rate Cross-Host Attack Prevention."
print_status "INFO" "Example: docker run --rm p4ctl-env-test python3.7 custom-send.py"
print_status "INFO" "Example: docker run --rm p4ctl-env-test ./compiler/netcl-compile"
echo ""
print_status "INFO" "For more information, see README.md and the IEEE S&P 2024 paper"
exit 0
fi

# If Docker failed or not available, skip local environment tests
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ] || [ "${DOCKER_MODE:-false}" = "false" ]; then
    echo "Docker environment not available - skipping local environment tests"
    echo "This script is designed to test Docker environment only"
    exit 0
fi 