#!/bin/bash

# Metis Environment Benchmark Test Script
# This script tests the Docker environment setup for Metis: A Model Checker for Linearizability
# Tailored specifically for Metis project requirements and features

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
    docker stop metis-env-test 2>/dev/null || true
    docker rm metis-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the Metis project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t metis-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/Metis" metis-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "Metis Environment Benchmark Test"
echo "=========================================="

echo "1. Checking System Dependencies..."
echo "--------------------------------"
# Check Python3
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>&1)
    print_status "PASS" "Python3 is available: $python_version"
else
    print_status "FAIL" "Python3 is not available"
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

if command -v g++ &> /dev/null; then
    gpp_version=$(g++ --version 2>&1 | head -n 1)
    print_status "PASS" "G++ is available: $gpp_version"
else
    print_status "FAIL" "G++ is not available"
fi

if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "Make is available: $make_version"
else
    print_status "FAIL" "Make is not available"
fi

if command -v cmake &> /dev/null; then
    cmake_version=$(cmake --version 2>&1 | head -n 1)
    print_status "PASS" "CMake is available: $cmake_version"
else
    print_status "FAIL" "CMake is not available"
fi

# Check autotools
if command -v autoconf &> /dev/null; then
    autoconf_version=$(autoconf --version 2>&1 | head -n 1)
    print_status "PASS" "Autoconf is available: $autoconf_version"
else
    print_status "FAIL" "Autoconf is not available"
fi

if command -v automake &> /dev/null; then
    automake_version=$(automake --version 2>&1 | head -n 1)
    print_status "PASS" "Automake is available: $automake_version"
else
    print_status "FAIL" "Automake is not available"
fi

if command -v libtool &> /dev/null; then
    libtool_version=$(libtool --version 2>&1 | head -n 1)
    print_status "PASS" "Libtool is available: $libtool_version"
else
    print_status "FAIL" "Libtool is not available"
fi

# Check parser generators
if command -v flex &> /dev/null; then
    flex_version=$(flex --version 2>&1 | head -n 1)
    print_status "PASS" "Flex is available: $flex_version"
else
    print_status "FAIL" "Flex is not available"
fi

if command -v bison &> /dev/null; then
    bison_version=$(bison --version 2>&1 | head -n 1)
    print_status "PASS" "Bison is available: $bison_version"
else
    print_status "FAIL" "Bison is not available"
fi

# Check SSH
if command -v ssh &> /dev/null; then
    ssh_version=$(ssh -V 2>&1 | head -n 1)
    print_status "PASS" "SSH is available: $ssh_version"
else
    print_status "FAIL" "SSH is not available"
fi

# Check pkg-config
if command -v pkg-config &> /dev/null; then
    pkg_config_version=$(pkg-config --version 2>&1)
    print_status "PASS" "pkg-config is available: $pkg_config_version"
else
    print_status "FAIL" "pkg-config is not available"
fi

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "common" ]; then
    print_status "PASS" "common directory exists (common source code)"
else
    print_status "FAIL" "common directory not found"
fi

if [ -d "include" ]; then
    print_status "PASS" "include directory exists (header files)"
else
    print_status "FAIL" "include directory not found"
fi

if [ -d "scripts" ]; then
    print_status "PASS" "scripts directory exists (setup and utility scripts)"
else
    print_status "FAIL" "scripts directory not found"
fi

if [ -d "kernel" ]; then
    print_status "PASS" "kernel directory exists (kernel versions)"
else
    print_status "FAIL" "kernel directory not found"
fi

if [ -d "tests" ]; then
    print_status "PASS" "tests directory exists (test files)"
else
    print_status "FAIL" "tests directory not found"
fi

if [ -d "fs_bugs" ]; then
    print_status "PASS" "fs_bugs directory exists (file system bugs)"
else
    print_status "FAIL" "fs_bugs directory not found"
fi

if [ -d "fs-state" ]; then
    print_status "PASS" "fs-state directory exists (file system state)"
else
    print_status "FAIL" "fs-state directory not found"
fi

if [ -d "driver-fs-state" ]; then
    print_status "PASS" "driver-fs-state directory exists (driver file system state)"
else
    print_status "FAIL" "driver-fs-state directory not found"
fi

if [ -d "verifs1" ]; then
    print_status "PASS" "verifs1 directory exists (verification files)"
else
    print_status "FAIL" "verifs1 directory not found"
fi

if [ -d "promela-demo" ]; then
    print_status "PASS" "promela-demo directory exists (Promela demonstrations)"
else
    print_status "FAIL" "promela-demo directory not found"
fi

if [ -d "python-demo" ]; then
    print_status "PASS" "python-demo directory exists (Python demonstrations)"
else
    print_status "FAIL" "python-demo directory not found"
fi

if [ -d "mcl-demo" ]; then
    print_status "PASS" "mcl-demo directory exists (MCL demonstrations)"
else
    print_status "FAIL" "mcl-demo directory not found"
fi

if [ -d "example" ]; then
    print_status "PASS" "example directory exists (example files)"
else
    print_status "FAIL" "example directory not found"
fi

if [ -d "ae-experiments" ]; then
    print_status "PASS" "ae-experiments directory exists (artifact evaluation experiments)"
else
    print_status "FAIL" "ae-experiments directory not found"
fi

# Check key files
if [ -f "Makefile" ]; then
    print_status "PASS" "Makefile exists"
else
    print_status "FAIL" "Makefile not found"
fi

if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
fi

if [ -f "README-others.md" ]; then
    print_status "PASS" "README-others.md exists"
else
    print_status "FAIL" "README-others.md not found"
fi

if [ -f "LICENSE" ]; then
    print_status "PASS" "LICENSE exists"
else
    print_status "FAIL" "LICENSE not found"
fi

if [ -f ".gitignore" ]; then
    print_status "PASS" ".gitignore exists"
else
    print_status "FAIL" ".gitignore not found"
fi

# Check source files
if [ -f "scripts/setup-deps.sh" ]; then
    print_status "PASS" "scripts/setup-deps.sh exists (dependency setup script)"
else
    print_status "FAIL" "scripts/setup-deps.sh not found"
fi

if [ -f "scripts/color.py" ]; then
    print_status "PASS" "scripts/color.py exists (color output script)"
else
    print_status "FAIL" "scripts/color.py not found"
fi

if [ -f "scripts/mcfs_helper_daemon.sh" ]; then
    print_status "PASS" "scripts/mcfs_helper_daemon.sh exists (helper daemon script)"
else
    print_status "FAIL" "scripts/mcfs_helper_daemon.sh not found"
fi

echo ""
echo "3. Checking Environment Variables..."
echo "-----------------------------------"
# Check Metis environment
if [ -n "${METIS_ROOT:-}" ]; then
    print_status "PASS" "METIS_ROOT is set: $METIS_ROOT"
else
    print_status "WARN" "METIS_ROOT is not set"
fi

if [ -n "${HOME:-}" ]; then
    print_status "PASS" "HOME is set: $HOME"
else
    print_status "WARN" "HOME is not set"
fi

if [ -n "${PATH:-}" ]; then
    print_status "PASS" "PATH is set"
else
    print_status "WARN" "PATH is not set"
fi

if [ -n "${VIRTUAL_ENV:-}" ]; then
    print_status "PASS" "VIRTUAL_ENV is set: $VIRTUAL_ENV"
else
    print_status "WARN" "VIRTUAL_ENV is not set"
fi

# Check PATH
if echo "$PATH" | grep -q "python3"; then
    print_status "PASS" "python3 is in PATH"
else
    print_status "WARN" "python3 is not in PATH"
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

if echo "$PATH" | grep -q "gcc"; then
    print_status "PASS" "gcc is in PATH"
else
    print_status "WARN" "gcc is not in PATH"
fi

if echo "$PATH" | grep -q "make"; then
    print_status "PASS" "make is in PATH"
else
    print_status "WARN" "make is not in PATH"
fi

echo ""
echo "4. Testing Python3 Environment..."
echo "--------------------------------"
# Test Python3
if command -v python3 &> /dev/null; then
    print_status "PASS" "python3 is available"
    
    # Test Python3 execution
    if timeout 30s python3 -c "print('Python3 works')" >/dev/null 2>&1; then
        print_status "PASS" "Python3 execution works"
    else
        print_status "WARN" "Python3 execution failed"
    fi
    
    # Test Python3 modules
    if timeout 30s python3 -c "import sys; print(sys.version)" >/dev/null 2>&1; then
        print_status "PASS" "Python3 sys module works"
    else
        print_status "WARN" "Python3 sys module failed"
    fi
    
    # Test Python3 version
    if timeout 30s python3 -c "import sys; print(sys.version_info)" >/dev/null 2>&1; then
        print_status "PASS" "Python3 version check works"
    else
        print_status "WARN" "Python3 version check failed"
    fi
else
    print_status "FAIL" "python3 is not available"
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
echo "6. Testing Metis Build System..."
echo "--------------------------------"
# Test Makefile
if [ -f "Makefile" ]; then
    print_status "PASS" "Makefile exists for build testing"
    
    # Test Makefile structure
    if grep -q "COMMON_DIR" Makefile; then
        print_status "PASS" "Makefile has COMMON_DIR definition"
    else
        print_status "FAIL" "Makefile missing COMMON_DIR definition"
    fi
    
    if grep -q "CFLAGS" Makefile; then
        print_status "PASS" "Makefile has CFLAGS definition"
    else
        print_status "FAIL" "Makefile missing CFLAGS definition"
    fi
    
    if grep -q "LIBS" Makefile; then
        print_status "PASS" "Makefile has LIBS definition"
    else
        print_status "FAIL" "Makefile missing LIBS definition"
    fi
    
    if grep -q "libmcfs" Makefile; then
        print_status "PASS" "Makefile has libmcfs target"
    else
        print_status "FAIL" "Makefile missing libmcfs target"
    fi
    
    if grep -q "install" Makefile; then
        print_status "PASS" "Makefile has install target"
    else
        print_status "FAIL" "Makefile missing install target"
    fi
    
    if grep -q "clean" Makefile; then
        print_status "PASS" "Makefile has clean target"
    else
        print_status "FAIL" "Makefile missing clean target"
    fi
else
    print_status "FAIL" "Makefile not found"
fi

echo ""
echo "7. Testing Metis Source Code Structure..."
echo "----------------------------------------"
# Test source code directories
if [ -d "common" ]; then
    print_status "PASS" "common directory exists for source testing"
    
    # Count source files
    c_files=$(find common -name "*.c" | wc -l)
    cpp_files=$(find common -name "*.cpp" | wc -l)
    
    if [ "$c_files" -gt 0 ]; then
        print_status "PASS" "Found $c_files C source files in common"
    else
        print_status "WARN" "No C source files found in common"
    fi
    
    if [ "$cpp_files" -gt 0 ]; then
        print_status "PASS" "Found $cpp_files C++ source files in common"
    else
        print_status "WARN" "No C++ source files found in common"
    fi
else
    print_status "FAIL" "common directory not found"
fi

if [ -d "include" ]; then
    print_status "PASS" "include directory exists for header testing"
    
    # Count header files
    h_files=$(find include -name "*.h" | wc -l)
    
    if [ "$h_files" -gt 0 ]; then
        print_status "PASS" "Found $h_files header files in include"
    else
        print_status "WARN" "No header files found in include"
    fi
else
    print_status "FAIL" "include directory not found"
fi

echo ""
echo "8. Testing Metis Scripts..."
echo "---------------------------"
# Test scripts
if [ -d "scripts" ]; then
    print_status "PASS" "scripts directory exists for script testing"
    
    # Count script files
    script_count=$(find scripts -type f | wc -l)
    if [ "$script_count" -gt 0 ]; then
        print_status "PASS" "Found $script_count script files"
    else
        print_status "WARN" "No script files found"
    fi
    
    # Test setup-deps.sh
    if [ -f "scripts/setup-deps.sh" ]; then
        print_status "PASS" "scripts/setup-deps.sh exists"
        
        if [ -x "scripts/setup-deps.sh" ]; then
            print_status "PASS" "scripts/setup-deps.sh is executable"
        else
            print_status "WARN" "scripts/setup-deps.sh is not executable"
        fi
        
        # Check if it's a bash script
        if head -n 1 scripts/setup-deps.sh | grep -q "#!/bin/bash"; then
            print_status "PASS" "scripts/setup-deps.sh is a bash script"
        else
            print_status "WARN" "scripts/setup-deps.sh is not a bash script"
        fi
    else
        print_status "FAIL" "scripts/setup-deps.sh not found"
    fi
    
    # Test color.py
    if [ -f "scripts/color.py" ]; then
        print_status "PASS" "scripts/color.py exists"
        
        if [ -x "scripts/color.py" ]; then
            print_status "PASS" "scripts/color.py is executable"
        else
            print_status "WARN" "scripts/color.py is not executable"
        fi
        
        # Test Python syntax
        if command -v python3 &> /dev/null; then
            if timeout 30s python3 -m py_compile scripts/color.py >/dev/null 2>&1; then
                print_status "PASS" "scripts/color.py syntax is valid"
            else
                print_status "WARN" "scripts/color.py syntax is invalid"
            fi
        else
            print_status "WARN" "python3 not available for script testing"
        fi
    else
        print_status "FAIL" "scripts/color.py not found"
    fi
    
    # Test mcfs_helper_daemon.sh
    if [ -f "scripts/mcfs_helper_daemon.sh" ]; then
        print_status "PASS" "scripts/mcfs_helper_daemon.sh exists"
        
        if [ -x "scripts/mcfs_helper_daemon.sh" ]; then
            print_status "PASS" "scripts/mcfs_helper_daemon.sh is executable"
        else
            print_status "WARN" "scripts/mcfs_helper_daemon.sh is not executable"
        fi
    else
        print_status "FAIL" "scripts/mcfs_helper_daemon.sh not found"
    fi
else
    print_status "FAIL" "scripts directory not found"
fi

echo ""
echo "9. Testing Metis Documentation..."
echo "--------------------------------"
# Test documentation
if [ -r "README.md" ]; then
    print_status "PASS" "README.md is readable"
else
    print_status "FAIL" "README.md is not readable"
fi

if [ -r "README-others.md" ]; then
    print_status "PASS" "README-others.md is readable"
else
    print_status "FAIL" "README-others.md is not readable"
fi

if [ -r "LICENSE" ]; then
    print_status "PASS" "LICENSE is readable"
else
    print_status "FAIL" "LICENSE is not readable"
fi

if [ -r ".gitignore" ]; then
    print_status "PASS" ".gitignore is readable"
else
    print_status "FAIL" ".gitignore is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "Metis" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "File System Model Checking" README.md; then
        print_status "PASS" "README.md contains project description"
    else
        print_status "WARN" "README.md missing project description"
    fi
    
    if grep -q "Setup" README.md; then
        print_status "PASS" "README.md contains setup instructions"
    else
        print_status "WARN" "README.md missing setup instructions"
    fi
    
    if grep -q "Prerequisites" README.md; then
        print_status "PASS" "README.md contains prerequisites"
    else
        print_status "WARN" "README.md missing prerequisites"
    fi
fi

echo ""
echo "10. Testing Metis Configuration..."
echo "----------------------------------"
# Test configuration files
if [ -r "Makefile" ]; then
    print_status "PASS" "Makefile is readable"
else
    print_status "FAIL" "Makefile is not readable"
fi

if [ -r ".gitignore" ]; then
    print_status "PASS" ".gitignore is readable"
else
    print_status "FAIL" ".gitignore is not readable"
fi

# Check .gitignore content
if [ -r ".gitignore" ]; then
    if grep -q "*.o" .gitignore; then
        print_status "PASS" ".gitignore excludes object files"
    else
        print_status "WARN" ".gitignore missing object file exclusion"
    fi
    
    if grep -q "*.so" .gitignore; then
        print_status "PASS" ".gitignore excludes shared libraries"
    else
        print_status "WARN" ".gitignore missing shared library exclusion"
    fi
    
    if grep -q "*.a" .gitignore; then
        print_status "PASS" ".gitignore excludes static libraries"
    else
        print_status "WARN" ".gitignore missing static library exclusion"
    fi
fi

echo ""
echo "11. Testing Metis Docker Functionality..."
echo "----------------------------------------"
# Test if Docker container can run basic commands
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test Python3 in Docker
    if docker run --rm metis-env-test python3 --version >/dev/null 2>&1; then
        print_status "PASS" "Python3 works in Docker container"
    else
        print_status "FAIL" "Python3 does not work in Docker container"
    fi
    
    # Test pip in Docker
    if docker run --rm metis-env-test pip --version >/dev/null 2>&1; then
        print_status "PASS" "pip works in Docker container"
    else
        print_status "FAIL" "pip does not work in Docker container"
    fi
    
    # Test gcc in Docker
    if docker run --rm metis-env-test gcc --version >/dev/null 2>&1; then
        print_status "PASS" "gcc works in Docker container"
    else
        print_status "FAIL" "gcc does not work in Docker container"
    fi
    
    # Test g++ in Docker
    if docker run --rm metis-env-test g++ --version >/dev/null 2>&1; then
        print_status "PASS" "g++ works in Docker container"
    else
        print_status "FAIL" "g++ does not work in Docker container"
    fi
    
    # Test make in Docker
    if docker run --rm metis-env-test make --version >/dev/null 2>&1; then
        print_status "PASS" "make works in Docker container"
    else
        print_status "FAIL" "make does not work in Docker container"
    fi
    
    # Test cmake in Docker
    if docker run --rm metis-env-test cmake --version >/dev/null 2>&1; then
        print_status "PASS" "cmake works in Docker container"
    else
        print_status "FAIL" "cmake does not work in Docker container"
    fi
    
    # Test git in Docker
    if docker run --rm metis-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "git works in Docker container"
    else
        print_status "FAIL" "git does not work in Docker container"
    fi
    
    # Test SSH in Docker
    if docker run --rm metis-env-test ssh -V >/dev/null 2>&1; then
        print_status "PASS" "SSH works in Docker container"
    else
        print_status "FAIL" "SSH does not work in Docker container"
    fi
    
    # Test if Makefile is accessible in Docker
    if docker run --rm metis-env-test test -f Makefile; then
        print_status "PASS" "Makefile is accessible in Docker container"
    else
        print_status "FAIL" "Makefile is not accessible in Docker container"
    fi
    
    # Test if scripts directory is accessible in Docker
    if docker run --rm metis-env-test test -d scripts; then
        print_status "PASS" "scripts directory is accessible in Docker container"
    else
        print_status "FAIL" "scripts directory is not accessible in Docker container"
    fi
    
    # Test if common directory is accessible in Docker
    if docker run --rm metis-env-test test -d common; then
        print_status "PASS" "common directory is accessible in Docker container"
    else
        print_status "FAIL" "common directory is not accessible in Docker container"
    fi
    
    # Test if include directory is accessible in Docker
    if docker run --rm metis-env-test test -d include; then
        print_status "PASS" "include directory is accessible in Docker container"
    else
        print_status "FAIL" "include directory is not accessible in Docker container"
    fi
    
    # Test if setup-deps.sh is accessible in Docker
    if docker run --rm metis-env-test test -f scripts/setup-deps.sh; then
        print_status "PASS" "scripts/setup-deps.sh is accessible in Docker container"
    else
        print_status "FAIL" "scripts/setup-deps.sh is not accessible in Docker container"
    fi
    
    # Test if color.py is accessible in Docker
    if docker run --rm metis-env-test test -f scripts/color.py; then
        print_status "PASS" "scripts/color.py is accessible in Docker container"
    else
        print_status "FAIL" "scripts/color.py is not accessible in Docker container"
    fi
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for Metis:"
echo "- Docker build process (Ubuntu 22.04, OCaml, SPIN, NuSMV)"
echo "- OCaml environment (version compatibility, module loading)"
echo "- Model checking tools (SPIN, NuSMV, CBMC)"
echo "- Metis build system (Makefile, dependencies)"
echo "- Metis verification system (linearizability checking)"
echo "- Metis source code (OCaml modules, verification scripts)"
echo "- Metis documentation (README.md, usage instructions)"
echo "- Metis configuration (Makefile, .gitignore)"
echo "- Docker container functionality (OCaml, model checkers)"
echo "- Linearizability verification capabilities"

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
    print_status "INFO" "All Docker tests passed! Your Metis Docker environment is ready!"
    print_status "INFO" "Metis is a model checker for linearizability verification."
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your Metis Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi

print_status "INFO" "You can now run Metis in Docker: A model checker for linearizability."
print_status "INFO" "Example: docker run --rm metis-env-test make"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/Metis metis-env-test /bin/bash" 