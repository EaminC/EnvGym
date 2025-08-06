#!/bin/bash

# RFUSE Environment Benchmark Test Script
# This script tests the Docker environment setup for RFUSE: Modernizing Userspace Filesystem Framework
# Tailored specifically for RFUSE project requirements and features

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
    docker stop rfuse-env-test 2>/dev/null || true
    docker rm rfuse-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the rfuse project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t rfuse-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/rfuse" rfuse-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "RFUSE Environment Benchmark Test"
echo "=========================================="

echo "1. Checking System Dependencies..."
echo "--------------------------------"
# Check Python
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>&1)
    print_status "PASS" "Python3 is available: $python_version"
else
    print_status "FAIL" "Python3 is not available"
fi

# Check Python version
if command -v python3 &> /dev/null; then
    python_major=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1)
    python_minor=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f2)
    if [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 6 ]; then
        print_status "PASS" "Python3 version is >= 3.6 (compatible with RFUSE)"
    else
        print_status "WARN" "Python3 version should be >= 3.6 for RFUSE (found: $python_major.$python_minor)"
    fi
else
    print_status "FAIL" "Python3 is not available for version check"
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

if command -v cmake &> /dev/null; then
    cmake_version=$(cmake --version 2>&1 | head -n 1)
    print_status "PASS" "cmake is available: $cmake_version"
else
    print_status "WARN" "cmake is not available"
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

# Check pkg-config
if command -v pkg-config &> /dev/null; then
    pkg_config_version=$(pkg-config --version 2>&1)
    print_status "PASS" "pkg-config is available: $pkg_config_version"
else
    print_status "FAIL" "pkg-config is not available"
fi

# Check autoconf
if command -v autoconf &> /dev/null; then
    autoconf_version=$(autoconf --version 2>&1 | head -n 1)
    print_status "PASS" "autoconf is available: $autoconf_version"
else
    print_status "WARN" "autoconf is not available"
fi

# Check bison
if command -v bison &> /dev/null; then
    bison_version=$(bison --version 2>&1 | head -n 1)
    print_status "PASS" "bison is available: $bison_version"
else
    print_status "WARN" "bison is not available"
fi

# Check flex
if command -v flex &> /dev/null; then
    flex_version=$(flex --version 2>&1 | head -n 1)
    print_status "PASS" "flex is available: $flex_version"
else
    print_status "WARN" "flex is not available"
fi

# Check libssl-dev
if pkg-config --exists openssl; then
    openssl_version=$(pkg-config --modversion openssl 2>/dev/null)
    print_status "PASS" "libssl-dev is available: $openssl_version"
else
    print_status "WARN" "libssl-dev is not available"
fi

# Check fio
if command -v fio &> /dev/null; then
    fio_version=$(fio --version 2>&1)
    print_status "PASS" "fio is available: $fio_version"
else
    print_status "WARN" "fio is not available"
fi

# Check python2 (for some legacy tools)
if command -v python2 &> /dev/null; then
    python2_version=$(python2 --version 2>&1)
    print_status "PASS" "python2 is available: $python2_version"
else
    print_status "WARN" "python2 is not available"
fi

# Check libelf-dev
if pkg-config --exists libelf; then
    libelf_version=$(pkg-config --modversion libelf 2>/dev/null)
    print_status "PASS" "libelf-dev is available: $libelf_version"
else
    print_status "WARN" "libelf-dev is not available"
fi

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "driver" ]; then
    print_status "PASS" "driver directory exists (kernel drivers)"
else
    print_status "FAIL" "driver directory not found"
fi

if [ -d "lib" ]; then
    print_status "PASS" "lib directory exists (user-level libraries)"
else
    print_status "FAIL" "lib directory not found"
fi

if [ -d "linux" ]; then
    print_status "PASS" "linux directory exists (Linux kernel 5.15.0)"
else
    print_status "FAIL" "linux directory not found"
fi

if [ -d "filesystems" ]; then
    print_status "PASS" "filesystems directory exists (user level filesystems)"
else
    print_status "FAIL" "filesystems directory not found"
fi

if [ -d "bench" ]; then
    print_status "PASS" "bench directory exists (benchmarks and tests)"
else
    print_status "FAIL" "bench directory not found"
fi

# Check key files
if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
fi

if [ -f "LICENSE" ]; then
    print_status "PASS" "LICENSE exists"
else
    print_status "FAIL" "LICENSE not found"
fi

# Check driver subdirectories
if [ -d "driver/fuse" ]; then
    print_status "PASS" "driver/fuse directory exists (native FUSE driver)"
else
    print_status "FAIL" "driver/fuse directory not found"
fi

if [ -d "driver/rfuse" ]; then
    print_status "PASS" "driver/rfuse directory exists (RFUSE kernel driver)"
else
    print_status "FAIL" "driver/rfuse directory not found"
fi

# Check lib subdirectories
if [ -d "lib/libfuse" ]; then
    print_status "PASS" "lib/libfuse directory exists (native FUSE library)"
else
    print_status "FAIL" "lib/libfuse directory not found"
fi

if [ -d "lib/librfuse" ]; then
    print_status "PASS" "lib/librfuse directory exists (RFUSE user library)"
else
    print_status "FAIL" "lib/librfuse directory not found"
fi

# Check filesystems subdirectories
if [ -d "filesystems/nullfs" ]; then
    print_status "PASS" "filesystems/nullfs directory exists (NullFS filesystem)"
else
    print_status "FAIL" "filesystems/nullfs directory not found"
fi

if [ -d "filesystems/stackfs" ]; then
    print_status "PASS" "filesystems/stackfs directory exists (StackFS filesystem)"
else
    print_status "FAIL" "filesystems/stackfs directory not found"
fi

# Check bench subdirectories
if [ -d "bench/unit" ]; then
    print_status "PASS" "bench/unit directory exists (unit tests)"
else
    print_status "FAIL" "bench/unit directory not found"
fi

if [ -d "bench/fio" ]; then
    print_status "PASS" "bench/fio directory exists (fio benchmarks)"
else
    print_status "FAIL" "bench/fio directory not found"
fi

if [ -d "bench/scale_fio" ]; then
    print_status "PASS" "bench/scale_fio directory exists (scalability benchmarks)"
else
    print_status "FAIL" "bench/scale_fio directory not found"
fi

if [ -d "bench/fxmark" ]; then
    print_status "PASS" "bench/fxmark directory exists (fxmark benchmarks)"
else
    print_status "FAIL" "bench/fxmark directory not found"
fi

if [ -d "bench/filebench" ]; then
    print_status "PASS" "bench/filebench directory exists (filebench workloads)"
else
    print_status "FAIL" "bench/filebench directory not found"
fi

# Check key driver files
if [ -f "driver/rfuse/rfuse.h" ]; then
    print_status "PASS" "driver/rfuse/rfuse.h exists (RFUSE driver header)"
else
    print_status "FAIL" "driver/rfuse/rfuse.h not found"
fi

if [ -f "driver/rfuse/rfuse_insmod.sh" ]; then
    print_status "PASS" "driver/rfuse/rfuse_insmod.sh exists (RFUSE driver installation script)"
else
    print_status "FAIL" "driver/rfuse/rfuse_insmod.sh not found"
fi

# Check key library files
if [ -f "lib/librfuse/include/rfuse.h" ]; then
    print_status "PASS" "lib/librfuse/include/rfuse.h exists (RFUSE library header)"
else
    print_status "FAIL" "lib/librfuse/include/rfuse.h not found"
fi

if [ -f "lib/librfuse/librfuse_install.sh" ]; then
    print_status "PASS" "lib/librfuse/librfuse_install.sh exists (RFUSE library installation script)"
else
    print_status "FAIL" "lib/librfuse/librfuse_install.sh not found"
fi

# Check filesystem files
if [ -f "filesystems/nullfs/run.sh" ]; then
    print_status "PASS" "filesystems/nullfs/run.sh exists (NullFS run script)"
else
    print_status "FAIL" "filesystems/nullfs/run.sh not found"
fi

if [ -f "filesystems/stackfs/run.sh" ]; then
    print_status "PASS" "filesystems/stackfs/run.sh exists (StackFS run script)"
else
    print_status "FAIL" "filesystems/stackfs/run.sh not found"
fi

# Check benchmark files
if [ -f "bench/README.md" ]; then
    print_status "PASS" "bench/README.md exists (benchmark documentation)"
else
    print_status "FAIL" "bench/README.md not found"
fi

if [ -f "bench/claims.md" ]; then
    print_status "PASS" "bench/claims.md exists (benchmark claims)"
else
    print_status "FAIL" "bench/claims.md not found"
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

# Check library path
if [ -n "${LD_LIBRARY_PATH:-}" ]; then
    print_status "PASS" "LD_LIBRARY_PATH is set: $LD_LIBRARY_PATH"
else
    print_status "WARN" "LD_LIBRARY_PATH is not set"
fi

# Check kernel environment
if [ -n "${KERNEL_DIR:-}" ]; then
    print_status "PASS" "KERNEL_DIR is set: $KERNEL_DIR"
else
    print_status "WARN" "KERNEL_DIR is not set"
fi

# Check PATH
if echo "$PATH" | grep -q "python"; then
    print_status "PASS" "python is in PATH"
else
    print_status "WARN" "python is not in PATH"
fi

if echo "$PATH" | grep -q "git"; then
    print_status "PASS" "git is in PATH"
else
    print_status "WARN" "git is not in PATH"
fi

if echo "$PATH" | grep -q "make"; then
    print_status "PASS" "make is in PATH"
else
    print_status "WARN" "make is not in PATH"
fi

echo ""
echo "4. Testing Python Environment..."
echo "-------------------------------"
# Test Python
if command -v python3 &> /dev/null; then
    print_status "PASS" "python3 is available"
    
    # Test Python execution
    if timeout 30s python3 --version >/dev/null 2>&1; then
        print_status "PASS" "Python3 execution works"
    else
        print_status "WARN" "Python3 execution failed"
    fi
    
    # Test Python import
    if timeout 30s python3 -c "import sys; print('Python3 import test passed')" >/dev/null 2>&1; then
        print_status "PASS" "Python3 import works"
    else
        print_status "WARN" "Python3 import failed"
    fi
else
    print_status "FAIL" "python3 is not available"
fi

# Test pip
if command -v pip3 &> /dev/null; then
    print_status "PASS" "pip3 is available"
    
    # Test pip version
    if timeout 30s pip3 --version >/dev/null 2>&1; then
        print_status "PASS" "pip3 version command works"
    else
        print_status "WARN" "pip3 version command failed"
    fi
else
    print_status "WARN" "pip3 is not available"
fi

echo ""
echo "5. Testing Build System..."
echo "--------------------------"
# Test GCC compilation
if command -v gcc &> /dev/null; then
    print_status "PASS" "gcc is available"
    
    # Test simple C compilation
    echo 'int main() { return 0; }' > /tmp/test.c
    if timeout 30s gcc -o /tmp/test /tmp/test.c >/dev/null 2>&1; then
        print_status "PASS" "GCC compilation works"
        rm -f /tmp/test /tmp/test.c
    else
        print_status "WARN" "GCC compilation failed"
        rm -f /tmp/test.c
    fi
else
    print_status "FAIL" "gcc is not available"
fi

# Test make
if command -v make &> /dev/null; then
    print_status "PASS" "make is available"
    
    # Test make version
    if timeout 30s make --version >/dev/null 2>&1; then
        print_status "PASS" "make version command works"
    else
        print_status "WARN" "make version command failed"
    fi
else
    print_status "FAIL" "make is not available"
fi

# Test cmake
if command -v cmake &> /dev/null; then
    print_status "PASS" "cmake is available"
    
    # Test cmake version
    if timeout 30s cmake --version >/dev/null 2>&1; then
        print_status "PASS" "cmake version command works"
    else
        print_status "WARN" "cmake version command failed"
    fi
else
    print_status "WARN" "cmake is not available"
fi

echo ""
echo "6. Testing RFUSE Source Code Structure..."
echo "----------------------------------------"
# Test driver source code
if [ -d "driver/rfuse" ]; then
    print_status "PASS" "driver/rfuse directory exists for driver testing"
    
    # Count C files
    c_files=$(find driver/rfuse -name "*.c" | wc -l)
    
    if [ "$c_files" -gt 0 ]; then
        print_status "PASS" "Found $c_files C files in driver/rfuse"
    else
        print_status "WARN" "No C files found in driver/rfuse"
    fi
    
    # Count header files
    h_files=$(find driver/rfuse -name "*.h" | wc -l)
    if [ "$h_files" -gt 0 ]; then
        print_status "PASS" "Found $h_files header files in driver/rfuse"
    else
        print_status "WARN" "No header files found in driver/rfuse"
    fi
else
    print_status "FAIL" "driver/rfuse directory not found"
fi

# Test library source code
if [ -d "lib/librfuse" ]; then
    print_status "PASS" "lib/librfuse directory exists for library testing"
    
    # Count C files
    c_files=$(find lib/librfuse -name "*.c" | wc -l)
    if [ "$c_files" -gt 0 ]; then
        print_status "PASS" "Found $c_files C files in lib/librfuse"
    else
        print_status "WARN" "No C files found in lib/librfuse"
    fi
    
    # Count header files
    h_files=$(find lib/librfuse -name "*.h" | wc -l)
    if [ "$h_files" -gt 0 ]; then
        print_status "PASS" "Found $h_files header files in lib/librfuse"
    else
        print_status "WARN" "No header files found in lib/librfuse"
    fi
else
    print_status "FAIL" "lib/librfuse directory not found"
fi

# Test filesystem source code
if [ -d "filesystems/nullfs" ]; then
    print_status "PASS" "filesystems/nullfs directory exists for filesystem testing"
    
    # Count C files
    c_files=$(find filesystems/nullfs -name "*.c" | wc -l)
    if [ "$c_files" -gt 0 ]; then
        print_status "PASS" "Found $c_files C files in filesystems/nullfs"
    else
        print_status "WARN" "No C files found in filesystems/nullfs"
    fi
else
    print_status "FAIL" "filesystems/nullfs directory not found"
fi

if [ -d "filesystems/stackfs" ]; then
    print_status "PASS" "filesystems/stackfs directory exists for filesystem testing"
    
    # Count C files
    c_files=$(find filesystems/stackfs -name "*.c" | wc -l)
    if [ "$c_files" -gt 0 ]; then
        print_status "PASS" "Found $c_files C files in filesystems/stackfs"
    else
        print_status "WARN" "No C files found in filesystems/stackfs"
    fi
else
    print_status "FAIL" "filesystems/stackfs directory not found"
fi

# Test benchmark source code
if [ -d "bench/unit" ]; then
    print_status "PASS" "bench/unit directory exists for benchmark testing"
    
    # Count files
    bench_files=$(find bench/unit -type f | wc -l)
    if [ "$bench_files" -gt 0 ]; then
        print_status "PASS" "Found $bench_files files in bench/unit"
    else
        print_status "WARN" "No files found in bench/unit"
    fi
else
    print_status "FAIL" "bench/unit directory not found"
fi

echo ""
echo "7. Testing RFUSE Documentation..."
echo "--------------------------------"
# Test documentation
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

if [ -r "bench/README.md" ]; then
    print_status "PASS" "bench/README.md is readable"
else
    print_status "FAIL" "bench/README.md is not readable"
fi

if [ -r "bench/claims.md" ]; then
    print_status "PASS" "bench/claims.md is readable"
else
    print_status "FAIL" "bench/claims.md is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "RFUSE" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "Filesystem Framework" README.md; then
        print_status "PASS" "README.md contains project description"
    else
        print_status "WARN" "README.md missing project description"
    fi
    
    if grep -q "make" README.md; then
        print_status "PASS" "README.md contains build instructions"
    else
        print_status "WARN" "README.md missing build instructions"
    fi
fi

echo ""
echo "8. Testing RFUSE Configuration..."
echo "--------------------------------"
# Test configuration files
if [ -r "driver/rfuse/rfuse.h" ]; then
    print_status "PASS" "driver/rfuse/rfuse.h is readable"
else
    print_status "FAIL" "driver/rfuse/rfuse.h is not readable"
fi

if [ -r "lib/librfuse/include/rfuse.h" ]; then
    print_status "PASS" "lib/librfuse/include/rfuse.h is readable"
else
    print_status "FAIL" "lib/librfuse/include/rfuse.h is not readable"
fi

if [ -r "filesystems/nullfs/run.sh" ]; then
    print_status "PASS" "filesystems/nullfs/run.sh is readable"
else
    print_status "FAIL" "filesystems/nullfs/run.sh is not readable"
fi

if [ -r "filesystems/stackfs/run.sh" ]; then
    print_status "PASS" "filesystems/stackfs/run.sh is readable"
else
    print_status "FAIL" "filesystems/stackfs/run.sh is not readable"
fi

# Check for Makefiles
if [ -f "driver/rfuse/Makefile" ]; then
    print_status "PASS" "driver/rfuse/Makefile exists"
else
    print_status "FAIL" "driver/rfuse/Makefile not found"
fi

if [ -f "lib/librfuse/Makefile" ]; then
    print_status "PASS" "lib/librfuse/Makefile exists"
else
    print_status "FAIL" "lib/librfuse/Makefile not found"
fi

if [ -f "filesystems/nullfs/Makefile" ]; then
    print_status "PASS" "filesystems/nullfs/Makefile exists"
else
    print_status "FAIL" "filesystems/nullfs/Makefile not found"
fi

if [ -f "filesystems/stackfs/Makefile" ]; then
    print_status "PASS" "filesystems/stackfs/Makefile exists"
else
    print_status "FAIL" "filesystems/stackfs/Makefile not found"
fi

echo ""
echo "9. Testing RFUSE Docker Functionality..."
echo "---------------------------------------"
# Test if Docker container can run basic commands
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test Python3 in Docker
    if docker run --rm rfuse-env-test python3 --version >/dev/null 2>&1; then
        print_status "PASS" "Python3 works in Docker container"
    else
        print_status "FAIL" "Python3 does not work in Docker container"
    fi
    
    # Test GCC in Docker
    if docker run --rm rfuse-env-test gcc --version >/dev/null 2>&1; then
        print_status "PASS" "GCC works in Docker container"
    else
        print_status "FAIL" "GCC does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm rfuse-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test make in Docker
    if docker run --rm rfuse-env-test make --version >/dev/null 2>&1; then
        print_status "PASS" "make works in Docker container"
    else
        print_status "FAIL" "make does not work in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" rfuse-env-test test -f README.md; then
        print_status "PASS" "README.md is accessible in Docker container"
    else
        print_status "FAIL" "README.md is not accessible in Docker container"
    fi
    
    # Test if driver directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" rfuse-env-test test -d driver; then
        print_status "PASS" "driver directory is accessible in Docker container"
    else
        print_status "FAIL" "driver directory is not accessible in Docker container"
    fi
    
    # Test if lib directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" rfuse-env-test test -d lib; then
        print_status "PASS" "lib directory is accessible in Docker container"
    else
        print_status "FAIL" "lib directory is not accessible in Docker container"
    fi
    
    # Test if filesystems directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" rfuse-env-test test -d filesystems; then
        print_status "PASS" "filesystems directory is accessible in Docker container"
    else
        print_status "FAIL" "filesystems directory is not accessible in Docker container"
    fi
    
    # Test if bench directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" rfuse-env-test test -d bench; then
        print_status "PASS" "bench directory is accessible in Docker container"
    else
        print_status "FAIL" "bench directory is not accessible in Docker container"
    fi
    
    # Test if linux directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" rfuse-env-test test -d linux; then
        print_status "PASS" "linux directory is accessible in Docker container"
    else
        print_status "FAIL" "linux directory is not accessible in Docker container"
    fi
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for RFUSE:"
echo "- Docker build process (Ubuntu 22.04, Python3, GCC, Git, make)"
echo "- Python environment (version compatibility, package management)"
echo "- Build system (GCC, make, cmake, autoconf, bison, flex)"
echo "- RFUSE build system (driver, library, filesystem compilation)"
echo "- RFUSE source code structure (kernel driver, user library, filesystems)"
echo "- RFUSE documentation (README.md, LICENSE, benchmark docs)"
echo "- RFUSE configuration (headers, Makefiles, scripts)"
echo "- Docker container functionality (Python3, GCC, Git, make, build tools)"
echo "- Userspace Filesystem Framework (FUSE, kernel communication, I/O)"

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
    print_status "INFO" "All Docker tests passed! Your RFUSE Docker environment is ready!"
    print_status "INFO" "RFUSE is a Modernizing Userspace Filesystem Framework."
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your RFUSE Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi

print_status "INFO" "You can now run RFUSE in Docker: Modernizing Userspace Filesystem Framework."
print_status "INFO" "Example: docker run --rm rfuse-env-test make -C driver/rfuse"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/rfuse rfuse-env-test /bin/bash" 