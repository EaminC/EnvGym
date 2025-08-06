#!/bin/bash

# fmtlib_fmt Environment Benchmark Test Script
# This script tests the environment setup for {fmt}: A modern formatting library

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
    docker stop fmtlib-env-test 2>/dev/null || true
    docker rm fmtlib-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the fmtlib_fmt project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t fmtlib-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/fmtlib_fmt" fmtlib-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "fmtlib_fmt Environment Benchmark Test"
echo "=========================================="

# Analyze Dockerfile if build failed
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
    if [ -f "envgym/envgym.dockerfile" ]; then
        echo ""
        echo "Analyzing Dockerfile..."
        echo "----------------------"
        
        # Check Dockerfile structure
        if grep -q "FROM" envgym/envgym.dockerfile; then
            print_status "PASS" "FROM instruction found"
        else
            print_status "FAIL" "FROM instruction not found"
        fi
        
        if grep -q "ubuntu:22.04" envgym/envgym.dockerfile; then
            print_status "PASS" "Ubuntu 22.04 specified"
        else
            print_status "WARN" "Ubuntu 22.04 not specified"
        fi
        
        if grep -q "WORKDIR" envgym/envgym.dockerfile; then
            print_status "PASS" "WORKDIR set"
        else
            print_status "WARN" "WORKDIR not set"
        fi
        
        if grep -q "build-essential" envgym/envgym.dockerfile; then
            print_status "PASS" "build-essential found"
        else
            print_status "FAIL" "build-essential not found"
        fi
        
        if grep -q "cmake" envgym/envgym.dockerfile; then
            print_status "PASS" "cmake found"
        else
            print_status "FAIL" "cmake not found"
        fi
        
        if grep -q "git" envgym/envgym.dockerfile; then
            print_status "PASS" "git found"
        else
            print_status "WARN" "git not found"
        fi
        
        if grep -q "clang" envgym/envgym.dockerfile; then
            print_status "PASS" "clang found"
        else
            print_status "WARN" "clang not found"
        fi
        
        if grep -q "ninja-build" envgym/envgym.dockerfile; then
            print_status "PASS" "ninja-build found"
        else
            print_status "WARN" "ninja-build not found"
        fi
        
        if grep -q "doxygen" envgym/envgym.dockerfile; then
            print_status "PASS" "doxygen found"
        else
            print_status "WARN" "doxygen not found"
        fi
        
        if grep -q "valgrind" envgym/envgym.dockerfile; then
            print_status "PASS" "valgrind found"
        else
            print_status "WARN" "valgrind not found"
        fi
        
        if grep -q "bazel" envgym/envgym.dockerfile; then
            print_status "PASS" "bazel found"
        else
            print_status "WARN" "bazel not found"
        fi
        
        if grep -q "COPY" envgym/envgym.dockerfile; then
            print_status "PASS" "COPY instruction found"
        else
            print_status "WARN" "COPY instruction not found"
        fi
        
        if grep -q "CMD" envgym/envgym.dockerfile; then
            print_status "PASS" "CMD found"
        else
            print_status "WARN" "CMD not found"
        fi
        
        echo ""
        total_dockerfile_checks=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT))
        if [ $total_dockerfile_checks -gt 0 ]; then
            dockerfile_score=$((PASS_COUNT * 100 / total_dockerfile_checks))
        else
            dockerfile_score=0
        fi
        print_status "INFO" "Dockerfile Environment Score: $dockerfile_score% ($PASS_COUNT/$total_dockerfile_checks checks passed)"
        print_status "INFO" "PASS: $PASS_COUNT, FAIL: $((FAIL_COUNT)), WARN: $((WARN_COUNT))"
        if [ $FAIL_COUNT -eq 0 ]; then
            print_status "INFO" "Dockerfile结构良好，建议检查依赖版本和构建产物。"
        else
            print_status "WARN" "Dockerfile存在一些问题，建议修复后重新构建。"
        fi
        echo ""
    else
        print_status "FAIL" "envgym.dockerfile not found"
    fi
fi

echo "1. Checking System Dependencies..."
echo "--------------------------------"
# Check gcc
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version 2>&1 | head -n 1)
    print_status "PASS" "GCC is available: $gcc_version"
else
    print_status "FAIL" "GCC is not available"
fi

# Check g++
if command -v g++ &> /dev/null; then
    gpp_version=$(g++ --version 2>&1 | head -n 1)
    print_status "PASS" "G++ is available: $gpp_version"
else
    print_status "FAIL" "G++ is not available"
fi

# Check clang
if command -v clang &> /dev/null; then
    clang_version=$(clang --version 2>&1 | head -n 1)
    print_status "PASS" "Clang is available: $clang_version"
else
    print_status "WARN" "Clang is not available"
fi

# Check clang++
if command -v clang++ &> /dev/null; then
    clangpp_version=$(clang++ --version 2>&1 | head -n 1)
    print_status "PASS" "Clang++ is available: $clangpp_version"
else
    print_status "WARN" "Clang++ is not available"
fi

# Check cmake
if command -v cmake &> /dev/null; then
    cmake_version=$(cmake --version 2>&1 | head -n 1)
    print_status "PASS" "CMake is available: $cmake_version"
else
    print_status "FAIL" "CMake is not available"
fi

# Check make
if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "Make is available: $make_version"
else
    print_status "FAIL" "Make is not available"
fi

# Check ninja
if command -v ninja &> /dev/null; then
    ninja_version=$(ninja --version 2>&1)
    print_status "PASS" "Ninja is available: $ninja_version"
else
    print_status "WARN" "Ninja is not available"
fi

# Check git
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

# Check python3
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>&1)
    print_status "PASS" "Python3 is available: $python_version"
else
    print_status "WARN" "Python3 is not available"
fi

# Check doxygen
if command -v doxygen &> /dev/null; then
    doxygen_version=$(doxygen --version 2>&1)
    print_status "PASS" "Doxygen is available: $doxygen_version"
else
    print_status "WARN" "Doxygen is not available"
fi

# Check valgrind
if command -v valgrind &> /dev/null; then
    valgrind_version=$(valgrind --version 2>&1)
    print_status "PASS" "Valgrind is available: $valgrind_version"
else
    print_status "WARN" "Valgrind is not available"
fi

# Check bazel
if command -v bazel &> /dev/null; then
    bazel_version=$(bazel --version 2>&1)
    print_status "PASS" "Bazel is available: $bazel_version"
else
    print_status "WARN" "Bazel is not available"
fi

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "include" ]; then
    print_status "PASS" "include directory exists"
else
    print_status "FAIL" "include directory not found"
fi

if [ -d "include/fmt" ]; then
    print_status "PASS" "include/fmt directory exists"
else
    print_status "FAIL" "include/fmt directory not found"
fi

if [ -d "src" ]; then
    print_status "PASS" "src directory exists"
else
    print_status "FAIL" "src directory not found"
fi

if [ -d "test" ]; then
    print_status "PASS" "test directory exists"
else
    print_status "FAIL" "test directory not found"
fi

if [ -d "support" ]; then
    print_status "PASS" "support directory exists"
else
    print_status "FAIL" "support directory not found"
fi

if [ -d "doc" ]; then
    print_status "PASS" "doc directory exists"
else
    print_status "FAIL" "doc directory not found"
fi

# Check key files
if [ -f "CMakeLists.txt" ]; then
    print_status "PASS" "CMakeLists.txt exists"
else
    print_status "FAIL" "CMakeLists.txt not found"
fi

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

if [ -f ".gitignore" ]; then
    print_status "PASS" ".gitignore exists"
else
    print_status "FAIL" ".gitignore not found"
fi

# Check include files
if [ -f "include/fmt/format.h" ]; then
    print_status "PASS" "include/fmt/format.h exists"
else
    print_status "FAIL" "include/fmt/format.h not found"
fi

if [ -f "include/fmt/base.h" ]; then
    print_status "PASS" "include/fmt/base.h exists"
else
    print_status "FAIL" "include/fmt/base.h not found"
fi

if [ -f "include/fmt/core.h" ]; then
    print_status "PASS" "include/fmt/core.h exists"
else
    print_status "FAIL" "include/fmt/core.h not found"
fi

if [ -f "include/fmt/format-inl.h" ]; then
    print_status "PASS" "include/fmt/format-inl.h exists"
else
    print_status "FAIL" "include/fmt/format-inl.h not found"
fi

if [ -f "include/fmt/printf.h" ]; then
    print_status "PASS" "include/fmt/printf.h exists"
else
    print_status "FAIL" "include/fmt/printf.h not found"
fi

if [ -f "include/fmt/chrono.h" ]; then
    print_status "PASS" "include/fmt/chrono.h exists"
else
    print_status "FAIL" "include/fmt/chrono.h not found"
fi

if [ -f "include/fmt/color.h" ]; then
    print_status "PASS" "include/fmt/color.h exists"
else
    print_status "FAIL" "include/fmt/color.h not found"
fi

if [ -f "include/fmt/compile.h" ]; then
    print_status "PASS" "include/fmt/compile.h exists"
else
    print_status "FAIL" "include/fmt/compile.h not found"
fi

if [ -f "include/fmt/ranges.h" ]; then
    print_status "PASS" "include/fmt/ranges.h exists"
else
    print_status "FAIL" "include/fmt/ranges.h not found"
fi

if [ -f "include/fmt/std.h" ]; then
    print_status "PASS" "include/fmt/std.h exists"
else
    print_status "FAIL" "include/fmt/std.h not found"
fi

# Check source files
if [ -f "src/fmt.cc" ]; then
    print_status "PASS" "src/fmt.cc exists"
else
    print_status "FAIL" "src/fmt.cc not found"
fi

if [ -f "src/format.cc" ]; then
    print_status "PASS" "src/format.cc exists"
else
    print_status "FAIL" "src/format.cc not found"
fi

if [ -f "src/os.cc" ]; then
    print_status "PASS" "src/os.cc exists"
else
    print_status "FAIL" "src/os.cc not found"
fi

# Check test files
if [ -f "test/format-test.cc" ]; then
    print_status "PASS" "test/format-test.cc exists"
else
    print_status "FAIL" "test/format-test.cc not found"
fi

if [ -f "test/base-test.cc" ]; then
    print_status "PASS" "test/base-test.cc exists"
else
    print_status "FAIL" "test/base-test.cc not found"
fi

if [ -f "test/printf-test.cc" ]; then
    print_status "PASS" "test/printf-test.cc exists"
else
    print_status "FAIL" "test/printf-test.cc not found"
fi

if [ -f "test/chrono-test.cc" ]; then
    print_status "PASS" "test/chrono-test.cc exists"
else
    print_status "FAIL" "test/chrono-test.cc not found"
fi

if [ -f "test/compile-test.cc" ]; then
    print_status "PASS" "test/compile-test.cc exists"
else
    print_status "FAIL" "test/compile-test.cc not found"
fi

if [ -f "test/CMakeLists.txt" ]; then
    print_status "PASS" "test/CMakeLists.txt exists"
else
    print_status "FAIL" "test/CMakeLists.txt not found"
fi

# Check support files
if [ -f "support/docopt.py" ]; then
    print_status "PASS" "support/docopt.py exists"
else
    print_status "FAIL" "support/docopt.py not found"
fi

if [ -f "support/release.py" ]; then
    print_status "PASS" "support/release.py exists"
else
    print_status "FAIL" "support/release.py not found"
fi

if [ -f "support/printable.py" ]; then
    print_status "PASS" "support/printable.py exists"
else
    print_status "FAIL" "support/printable.py not found"
fi

echo ""
echo "3. Checking Environment Variables..."
echo "-----------------------------------"
# Check C++ environment
if [ -n "${CC:-}" ]; then
    print_status "PASS" "CC is set: $CC"
else
    print_status "WARN" "CC is not set"
fi

if [ -n "${CXX:-}" ]; then
    print_status "PASS" "CXX is set: $CXX"
else
    print_status "WARN" "CXX is not set"
fi

if [ -n "${CFLAGS:-}" ]; then
    print_status "PASS" "CFLAGS is set: $CFLAGS"
else
    print_status "WARN" "CFLAGS is not set"
fi

if [ -n "${CXXFLAGS:-}" ]; then
    print_status "PASS" "CXXFLAGS is set: $CXXFLAGS"
else
    print_status "WARN" "CXXFLAGS is not set"
fi

if [ -n "${LDFLAGS:-}" ]; then
    print_status "PASS" "LDFLAGS is set: $LDFLAGS"
else
    print_status "WARN" "LDFLAGS is not set"
fi

# Check PATH
if echo "$PATH" | grep -q "gcc"; then
    print_status "PASS" "gcc is in PATH"
else
    print_status "WARN" "gcc is not in PATH"
fi

if echo "$PATH" | grep -q "g++"; then
    print_status "PASS" "g++ is in PATH"
else
    print_status "WARN" "g++ is not in PATH"
fi

if echo "$PATH" | grep -q "cmake"; then
    print_status "PASS" "cmake is in PATH"
else
    print_status "WARN" "cmake is not in PATH"
fi

if echo "$PATH" | grep -q "make"; then
    print_status "PASS" "make is in PATH"
else
    print_status "WARN" "make is not in PATH"
fi

if echo "$PATH" | grep -q "ninja"; then
    print_status "PASS" "ninja is in PATH"
else
    print_status "WARN" "ninja is not in PATH"
fi

echo ""
echo "4. Testing C/C++ Compilation..."
echo "-------------------------------"
# Test C compilation
if command -v gcc &> /dev/null; then
    print_status "PASS" "gcc is available"
    
    # Test simple C compilation
    echo '#include <stdio.h>
int main() { printf("Hello from C\n"); return 0; }' > test.c
    
    if timeout 30s gcc -o test_c test.c 2>/dev/null; then
        print_status "PASS" "C compilation works"
        if ./test_c 2>/dev/null; then
            print_status "PASS" "C execution works"
        else
            print_status "WARN" "C execution failed"
        fi
        rm -f test_c test.c
    else
        print_status "WARN" "C compilation failed"
        rm -f test.c
    fi
else
    print_status "FAIL" "gcc is not available"
fi

# Test C++ compilation
if command -v g++ &> /dev/null; then
    print_status "PASS" "g++ is available"
    
    # Test simple C++ compilation
    echo '#include <iostream>
int main() { std::cout << "Hello from C++" << std::endl; return 0; }' > test.cpp
    
    if timeout 30s g++ -o test_cpp test.cpp 2>/dev/null; then
        print_status "PASS" "C++ compilation works"
        if ./test_cpp 2>/dev/null; then
            print_status "PASS" "C++ execution works"
        else
            print_status "WARN" "C++ execution failed"
        fi
        rm -f test_cpp test.cpp
    else
        print_status "WARN" "C++ compilation failed"
        rm -f test.cpp
    fi
else
    print_status "FAIL" "g++ is not available"
fi

# Test Clang compilation
if command -v clang &> /dev/null; then
    print_status "PASS" "clang is available"
    
    # Test simple C compilation with clang
    echo '#include <stdio.h>
int main() { printf("Hello from Clang C\n"); return 0; }' > test_clang.c
    
    if timeout 30s clang -o test_clang_c test_clang.c 2>/dev/null; then
        print_status "PASS" "Clang C compilation works"
        rm -f test_clang_c test_clang.c
    else
        print_status "WARN" "Clang C compilation failed"
        rm -f test_clang.c
    fi
else
    print_status "WARN" "clang is not available"
fi

# Test Clang++ compilation
if command -v clang++ &> /dev/null; then
    print_status "PASS" "clang++ is available"
    
    # Test simple C++ compilation with clang++
    echo '#include <iostream>
int main() { std::cout << "Hello from Clang++" << std::endl; return 0; }' > test_clang.cpp
    
    if timeout 30s clang++ -o test_clang_cpp test_clang.cpp 2>/dev/null; then
        print_status "PASS" "Clang++ compilation works"
        rm -f test_clang_cpp test_clang.cpp
    else
        print_status "WARN" "Clang++ compilation failed"
        rm -f test_clang.cpp
    fi
else
    print_status "WARN" "clang++ is not available"
fi

echo ""
echo "5. Testing Build Systems..."
echo "---------------------------"
# Test CMake
if command -v cmake &> /dev/null; then
    print_status "PASS" "cmake is available"
    
    # Test cmake version
    if timeout 30s cmake --version >/dev/null 2>&1; then
        print_status "PASS" "cmake version command works"
    else
        print_status "WARN" "cmake version command failed"
    fi
    
    # Test cmake help
    if timeout 30s cmake --help >/dev/null 2>&1; then
        print_status "PASS" "cmake help command works"
    else
        print_status "WARN" "cmake help command failed"
    fi
else
    print_status "FAIL" "cmake is not available"
fi

# Test Make
if command -v make &> /dev/null; then
    print_status "PASS" "make is available"
    
    # Test make version
    if timeout 30s make --version >/dev/null 2>&1; then
        print_status "PASS" "make version command works"
    else
        print_status "WARN" "make version command failed"
    fi
    
    # Test make help
    if timeout 30s make --help >/dev/null 2>&1; then
        print_status "PASS" "make help command works"
    else
        print_status "WARN" "make help command failed"
    fi
else
    print_status "FAIL" "make is not available"
fi

# Test Ninja
if command -v ninja &> /dev/null; then
    print_status "PASS" "ninja is available"
    
    # Test ninja version
    if timeout 30s ninja --version >/dev/null 2>&1; then
        print_status "PASS" "ninja version command works"
    else
        print_status "WARN" "ninja version command failed"
    fi
    
    # Test ninja help
    if timeout 30s ninja --help >/dev/null 2>&1; then
        print_status "PASS" "ninja help command works"
    else
        print_status "WARN" "ninja help command failed"
    fi
else
    print_status "WARN" "ninja is not available"
fi

echo ""
echo "6. Testing Python Environment..."
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
    print_status "WARN" "python3 is not available"
fi

echo ""
echo "7. Testing Documentation Tools..."
echo "---------------------------------"
# Test Doxygen
if command -v doxygen &> /dev/null; then
    print_status "PASS" "doxygen is available"
    
    # Test doxygen version
    if timeout 30s doxygen --version >/dev/null 2>&1; then
        print_status "PASS" "doxygen version command works"
    else
        print_status "WARN" "doxygen version command failed"
    fi
    
    # Test doxygen help
    if timeout 30s doxygen --help >/dev/null 2>&1; then
        print_status "PASS" "doxygen help command works"
    else
        print_status "WARN" "doxygen help command failed"
    fi
else
    print_status "WARN" "doxygen is not available"
fi

echo ""
echo "8. Testing Testing Tools..."
echo "----------------------------"
# Test Valgrind
if command -v valgrind &> /dev/null; then
    print_status "PASS" "valgrind is available"
    
    # Test valgrind version
    if timeout 30s valgrind --version >/dev/null 2>&1; then
        print_status "PASS" "valgrind version command works"
    else
        print_status "WARN" "valgrind version command failed"
    fi
    
    # Test valgrind help
    if timeout 30s valgrind --help >/dev/null 2>&1; then
        print_status "PASS" "valgrind help command works"
    else
        print_status "WARN" "valgrind help command failed"
    fi
else
    print_status "WARN" "valgrind is not available"
fi

echo ""
echo "9. Testing Build Tools..."
echo "--------------------------"
# Test Bazel
if command -v bazel &> /dev/null; then
    print_status "PASS" "bazel is available"
    
    # Test bazel version
    if timeout 30s bazel --version >/dev/null 2>&1; then
        print_status "PASS" "bazel version command works"
    else
        print_status "WARN" "bazel version command failed"
    fi
    
    # Test bazel help
    if timeout 30s bazel help >/dev/null 2>&1; then
        print_status "PASS" "bazel help command works"
    else
        print_status "WARN" "bazel help command failed"
    fi
else
    print_status "WARN" "bazel is not available"
fi

echo ""
echo "10. Testing fmt Library Compilation..."
echo "--------------------------------------"
# Test fmt header compilation
if command -v g++ &> /dev/null; then
    print_status "PASS" "g++ is available for fmt compilation test"
    
    # Test fmt/core.h compilation
    echo '#include "include/fmt/core.h"
int main() { fmt::print("Hello from fmt!\n"); return 0; }' > test_fmt.cpp
    
    if timeout 60s g++ -std=c++11 -I. -o test_fmt test_fmt.cpp 2>/dev/null; then
        print_status "PASS" "fmt/core.h compilation works"
        if ./test_fmt 2>/dev/null; then
            print_status "PASS" "fmt/core.h execution works"
        else
            print_status "WARN" "fmt/core.h execution failed"
        fi
        rm -f test_fmt test_fmt.cpp
    else
        print_status "WARN" "fmt/core.h compilation failed"
        rm -f test_fmt.cpp
    fi
else
    print_status "WARN" "g++ not available for fmt compilation test"
fi

# Test fmt/base.h compilation
if command -v g++ &> /dev/null; then
    echo '#include "include/fmt/base.h"
int main() { fmt::print("Hello from fmt base!\n"); return 0; }' > test_fmt_base.cpp
    
    if timeout 60s g++ -std=c++11 -I. -o test_fmt_base test_fmt_base.cpp 2>/dev/null; then
        print_status "PASS" "fmt/base.h compilation works"
        rm -f test_fmt_base test_fmt_base.cpp
    else
        print_status "WARN" "fmt/base.h compilation failed"
        rm -f test_fmt_base.cpp
    fi
fi

echo ""
echo "11. Testing CMake Build Process..."
echo "----------------------------------"
# Test CMake configuration
if command -v cmake &> /dev/null; then
    print_status "PASS" "cmake is available for build test"
    
    # Create build directory
    mkdir -p build_test
    cd build_test
    
    # Test cmake configuration
    if timeout 120s cmake .. >/dev/null 2>&1; then
        print_status "PASS" "CMake configuration successful"
        
        # Test make build
        if command -v make &> /dev/null; then
            if timeout 300s make -j$(nproc) >/dev/null 2>&1; then
                print_status "PASS" "Make build successful"
            else
                print_status "WARN" "Make build failed or timed out"
            fi
        else
            print_status "WARN" "make not available for build test"
        fi
        
        # Test ninja build
        if command -v ninja &> /dev/null; then
            if timeout 300s ninja >/dev/null 2>&1; then
                print_status "PASS" "Ninja build successful"
            else
                print_status "WARN" "Ninja build failed or timed out"
            fi
        else
            print_status "WARN" "ninja not available for build test"
        fi
    else
        print_status "WARN" "CMake configuration failed"
    fi
    
    cd ..
    rm -rf build_test
else
    print_status "WARN" "cmake not available for build test"
fi

echo ""
echo "12. Testing fmt Library Features..."
echo "-----------------------------------"
# Test fmt library features
if command -v g++ &> /dev/null; then
    print_status "PASS" "g++ is available for fmt feature test"
    
    # Test basic formatting
    echo '#include "include/fmt/core.h"
int main() {
    std::string s = fmt::format("The answer is {}.", 42);
    fmt::print("{}\n", s);
    return 0;
}' > test_fmt_features.cpp
    
    if timeout 60s g++ -std=c++11 -I. -o test_fmt_features test_fmt_features.cpp 2>/dev/null; then
        print_status "PASS" "fmt basic formatting compilation works"
        if ./test_fmt_features 2>/dev/null; then
            print_status "PASS" "fmt basic formatting execution works"
        else
            print_status "WARN" "fmt basic formatting execution failed"
        fi
        rm -f test_fmt_features test_fmt_features.cpp
    else
        print_status "WARN" "fmt basic formatting compilation failed"
        rm -f test_fmt_features.cpp
    fi
else
    print_status "WARN" "g++ not available for fmt feature test"
fi

echo ""
echo "13. Testing Support Scripts..."
echo "-------------------------------"
# Test support scripts
if [ -f "support/docopt.py" ]; then
    print_status "PASS" "support/docopt.py exists"
    
    # Test if it can be executed
    if command -v python3 &> /dev/null; then
        if timeout 30s python3 -c "import sys; sys.path.append('support'); import docopt; print('docopt imported')" >/dev/null 2>&1; then
            print_status "PASS" "support/docopt.py can be imported"
        else
            print_status "WARN" "support/docopt.py import failed"
        fi
    else
        print_status "WARN" "python3 not available for script test"
    fi
else
    print_status "FAIL" "support/docopt.py not found"
fi

if [ -f "support/release.py" ]; then
    print_status "PASS" "support/release.py exists"
else
    print_status "FAIL" "support/release.py not found"
fi

if [ -f "support/printable.py" ]; then
    print_status "PASS" "support/printable.py exists"
else
    print_status "FAIL" "support/printable.py not found"
fi

echo ""
echo "14. Testing Documentation..."
echo "----------------------------"
# Test if documentation files are readable
if [ -r "README.md" ]; then
    print_status "PASS" "README.md is readable"
else
    print_status "WARN" "README.md is not readable"
fi

if [ -r "LICENSE" ]; then
    print_status "PASS" "LICENSE is readable"
else
    print_status "WARN" "LICENSE is not readable"
fi

if [ -r ".gitignore" ]; then
    print_status "PASS" ".gitignore is readable"
else
    print_status "WARN" ".gitignore is not readable"
fi

if [ -r "CMakeLists.txt" ]; then
    print_status "PASS" "CMakeLists.txt is readable"
else
    print_status "WARN" "CMakeLists.txt is not readable"
fi

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (GCC, G++, Clang, Clang++, CMake, Make, Ninja, Git, Bash)"
echo "- Project structure (include/, src/, test/, support/, doc/)"
echo "- Environment variables (CC, CXX, CFLAGS, CXXFLAGS, LDFLAGS, PATH)"
echo "- C/C++ compilation (gcc, g++, clang, clang++)"
echo "- Build systems (CMake, Make, Ninja)"
echo "- Python environment (python3)"
echo "- Documentation tools (Doxygen)"
echo "- Testing tools (Valgrind)"
echo "- Build tools (Bazel)"
echo "- fmt library compilation (core.h, base.h)"
echo "- CMake build process"
echo "- fmt library features (basic formatting)"
echo "- Support scripts (docopt.py, release.py, printable.py)"
echo "- Documentation (README.md, LICENSE, .gitignore, CMakeLists.txt)"
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
    print_status "INFO" "All tests passed! Your fmtlib_fmt environment is ready!"
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your fmtlib_fmt environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi

print_status "INFO" "You can now build and use {fmt}: A modern formatting library."
print_status "INFO" "Example: mkdir build && cd build && cmake .. && make"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/fmtlib_fmt fmtlib-env-test /bin/bash" 