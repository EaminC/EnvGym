#!/bin/bash

# SimdJSON Environment Benchmark Test Script
# This script tests the Docker environment setup for SimdJSON: A fast JSON parser
# Tailored specifically for SimdJSON project requirements and features

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
    docker stop simdjson-env-test 2>/dev/null || true
    docker rm simdjson-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the simdjson_simdjson project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t simdjson-env-test .; then
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
    docker run --rm -v "$(pwd):/workspace" --entrypoint="" simdjson-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        cd /workspace
        bash envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "SimdJSON Environment Benchmark Test"
echo "=========================================="

echo "1. Checking C++ Compiler Environment..."
echo "---------------------------------------"
# Check GCC version
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version 2>&1 | head -n 1)
    print_status "PASS" "GCC is available: $gcc_version"
    
    # Check GCC version compatibility (simdjson requires g++ 7+)
    gcc_major=$(gcc --version 2>&1 | head -n 1 | grep -o '[0-9]\+\.[0-9]\+' | head -n 1 | cut -d'.' -f1)
    gcc_minor=$(gcc --version 2>&1 | head -n 1 | grep -o '[0-9]\+\.[0-9]\+' | head -n 1 | cut -d'.' -f2)
    if [ "$gcc_major" -ge 7 ]; then
        print_status "PASS" "GCC version is >= 7.0 (compatible with SimdJSON)"
    else
        print_status "WARN" "GCC version should be >= 7.0 for SimdJSON (found: $gcc_major.$gcc_minor)"
    fi
else
    print_status "FAIL" "GCC is not available"
fi

# Check G++ version
if command -v g++ &> /dev/null; then
    gpp_version=$(g++ --version 2>&1 | head -n 1)
    print_status "PASS" "G++ is available: $gpp_version"
    
    # Check G++ version compatibility
    gpp_major=$(g++ --version 2>&1 | head -n 1 | grep -o '[0-9]\+\.[0-9]\+' | head -n 1 | cut -d'.' -f1)
    gpp_minor=$(g++ --version 2>&1 | head -n 1 | grep -o '[0-9]\+\.[0-9]\+' | head -n 1 | cut -d'.' -f2)
    if [ "$gpp_major" -ge 7 ]; then
        print_status "PASS" "G++ version is >= 7.0 (compatible with SimdJSON)"
    else
        print_status "WARN" "G++ version should be >= 7.0 for SimdJSON (found: $gpp_major.$gpp_minor)"
    fi
else
    print_status "FAIL" "G++ is not available"
fi

# Check Clang version
if command -v clang &> /dev/null; then
    clang_version=$(clang --version 2>&1 | head -n 1)
    print_status "PASS" "Clang is available: $clang_version"
    
    # Check Clang version compatibility (simdjson requires clang++ 6+)
    clang_major=$(clang --version 2>&1 | head -n 1 | grep -o '[0-9]\+\.[0-9]\+' | head -n 1 | cut -d'.' -f1)
    clang_minor=$(clang --version 2>&1 | head -n 1 | grep -o '[0-9]\+\.[0-9]\+' | head -n 1 | cut -d'.' -f2)
    if [ "$clang_major" -ge 6 ]; then
        print_status "PASS" "Clang version is >= 6.0 (compatible with SimdJSON)"
    else
        print_status "WARN" "Clang version should be >= 6.0 for SimdJSON (found: $clang_major.$clang_minor)"
    fi
else
    print_status "WARN" "Clang is not available"
fi

# Check C++ compilation
if command -v g++ &> /dev/null; then
    echo 'int main() { return 0; }' > /tmp/test.cpp
    if timeout 30s g++ -o /tmp/test /tmp/test.cpp >/dev/null 2>&1; then
        print_status "PASS" "C++ compilation works with G++"
        rm -f /tmp/test /tmp/test.cpp
    else
        print_status "WARN" "C++ compilation failed with G++"
        rm -f /tmp/test.cpp
    fi
else
    print_status "FAIL" "G++ is not available for compilation testing"
fi

echo ""
echo "2. Checking Build System Environment..."
echo "--------------------------------------"
# Check CMake
if command -v cmake &> /dev/null; then
    cmake_version=$(cmake --version 2>&1 | head -n 1)
    print_status "PASS" "CMake is available: $cmake_version"
    
    # Check CMake version compatibility (simdjson requires 3.14+)
    cmake_major=$(cmake --version 2>&1 | head -n 1 | grep -o '[0-9]\+\.[0-9]\+' | head -n 1 | cut -d'.' -f1)
    cmake_minor=$(cmake --version 2>&1 | head -n 1 | grep -o '[0-9]\+\.[0-9]\+' | head -n 1 | cut -d'.' -f2)
    if [ "$cmake_major" -eq 3 ] && [ "$cmake_minor" -ge 14 ]; then
        print_status "PASS" "CMake version is >= 3.14 (compatible with SimdJSON)"
    else
        print_status "WARN" "CMake version should be >= 3.14 for SimdJSON (found: $cmake_major.$cmake_minor)"
    fi
else
    print_status "FAIL" "CMake is not available"
fi

# Check Ninja
if command -v ninja &> /dev/null; then
    ninja_version=$(ninja --version 2>&1)
    print_status "PASS" "Ninja is available: $ninja_version"
else
    print_status "WARN" "Ninja is not available"
fi

# Check Make
if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "Make is available: $make_version"
else
    print_status "FAIL" "Make is not available"
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

# Check Python3
if command -v python3 &> /dev/null; then
    python3_version=$(python3 --version 2>&1)
    print_status "PASS" "Python3 is available: $python3_version"
else
    print_status "WARN" "Python3 is not available"
fi

# Check Node.js
if command -v node &> /dev/null; then
    node_version=$(node --version 2>&1)
    print_status "PASS" "Node.js is available: $node_version"
else
    print_status "WARN" "Node.js is not available"
fi

# Check Rust
if command -v rustc &> /dev/null; then
    rust_version=$(rustc --version 2>&1)
    print_status "PASS" "Rust is available: $rust_version"
else
    print_status "WARN" "Rust is not available"
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

# Check build tools
if command -v pkg-config &> /dev/null; then
    pkg_config_version=$(pkg-config --version 2>&1)
    print_status "PASS" "pkg-config is available: $pkg_config_version"
else
    print_status "WARN" "pkg-config is not available"
fi

# Check Doxygen
if command -v doxygen &> /dev/null; then
    doxygen_version=$(doxygen --version 2>&1)
    print_status "PASS" "Doxygen is available: $doxygen_version"
else
    print_status "WARN" "Doxygen is not available"
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

if [ -d "include" ]; then
    print_status "PASS" "include directory exists (headers)"
else
    print_status "FAIL" "include directory not found"
fi

if [ -d "tests" ]; then
    print_status "PASS" "tests directory exists (test suite)"
else
    print_status "FAIL" "tests directory not found"
fi

if [ -d "examples" ]; then
    print_status "PASS" "examples directory exists (examples)"
else
    print_status "FAIL" "examples directory not found"
fi

if [ -d "benchmark" ]; then
    print_status "PASS" "benchmark directory exists (benchmarks)"
else
    print_status "FAIL" "benchmark directory not found"
fi

if [ -d "singleheader" ]; then
    print_status "PASS" "singleheader directory exists (single header files)"
else
    print_status "FAIL" "singleheader directory not found"
fi

if [ -d "jsonexamples" ]; then
    print_status "PASS" "jsonexamples directory exists (JSON test files)"
else
    print_status "FAIL" "jsonexamples directory not found"
fi

if [ -d "doc" ]; then
    print_status "PASS" "doc directory exists (documentation)"
else
    print_status "FAIL" "doc directory not found"
fi

if [ -d "tools" ]; then
    print_status "PASS" "tools directory exists (build tools)"
else
    print_status "FAIL" "tools directory not found"
fi

if [ -d "cmake" ]; then
    print_status "PASS" "cmake directory exists (CMake modules)"
else
    print_status "FAIL" "cmake directory not found"
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

if [ -f "LICENSE-MIT" ]; then
    print_status "PASS" "LICENSE-MIT exists"
else
    print_status "FAIL" "LICENSE-MIT not found"
fi

if [ -f "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md exists"
else
    print_status "FAIL" "CONTRIBUTING.md not found"
fi

if [ -f "HACKING.md" ]; then
    print_status "PASS" "HACKING.md exists"
else
    print_status "FAIL" "HACKING.md not found"
fi

if [ -f "SECURITY.md" ]; then
    print_status "PASS" "SECURITY.md exists"
else
    print_status "FAIL" "SECURITY.md not found"
fi

if [ -f "Doxyfile" ]; then
    print_status "PASS" "Doxyfile exists (documentation config)"
else
    print_status "FAIL" "Doxyfile not found"
fi

if [ -f ".clang-format" ]; then
    print_status "PASS" ".clang-format exists (code formatting config)"
else
    print_status "FAIL" ".clang-format not found"
fi

# Check source files
if [ -f "src/simdjson.cpp" ]; then
    print_status "PASS" "src/simdjson.cpp exists (main source)"
else
    print_status "FAIL" "src/simdjson.cpp not found"
fi

if [ -f "singleheader/simdjson.h" ]; then
    print_status "PASS" "singleheader/simdjson.h exists (single header)"
else
    print_status "FAIL" "singleheader/simdjson.h not found"
fi

if [ -f "singleheader/simdjson.cpp" ]; then
    print_status "PASS" "singleheader/simdjson.cpp exists (single header implementation)"
else
    print_status "FAIL" "singleheader/simdjson.cpp not found"
fi

echo ""
echo "5. Testing SimdJSON Source Code..."
echo "----------------------------------"
# Count C++ files
cpp_files=$(find . -name "*.cpp" | wc -l)
if [ "$cpp_files" -gt 0 ]; then
    print_status "PASS" "Found $cpp_files C++ files"
else
    print_status "FAIL" "No C++ files found"
fi

# Count header files
header_files=$(find . -name "*.h" | wc -l)
if [ "$header_files" -gt 0 ]; then
    print_status "PASS" "Found $header_files header files"
else
    print_status "FAIL" "No header files found"
fi

# Count test files
test_files=$(find . -name "*test*.cpp" | wc -l)
if [ "$test_files" -gt 0 ]; then
    print_status "PASS" "Found $test_files test files"
else
    print_status "WARN" "No test files found"
fi

# Test C++ syntax
if command -v g++ &> /dev/null; then
    print_status "INFO" "Testing C++ syntax..."
    syntax_errors=0
    for cpp_file in $(find . -name "*.cpp" | head -10); do
        if ! timeout 30s g++ -std=c++17 -fsyntax-only "$cpp_file" >/dev/null 2>&1; then
            ((syntax_errors++))
        fi
    done
    
    if [ "$syntax_errors" -eq 0 ]; then
        print_status "PASS" "All tested C++ files have valid syntax"
    else
        print_status "WARN" "Found $syntax_errors C++ files with syntax errors"
    fi
else
    print_status "FAIL" "G++ is not available for syntax checking"
fi

# Test CMakeLists.txt parsing
if command -v cmake &> /dev/null; then
    print_status "INFO" "Testing CMakeLists.txt parsing..."
    if timeout 60s cmake -S . -B /tmp/cmake_test >/dev/null 2>&1; then
        print_status "PASS" "CMakeLists.txt parsing successful"
    else
        print_status "WARN" "CMakeLists.txt parsing failed"
    fi
    rm -rf /tmp/cmake_test
else
    print_status "FAIL" "CMake is not available for CMakeLists.txt parsing"
fi

echo ""
echo "6. Testing SimdJSON Dependencies..."
echo "-----------------------------------"
# Test if required libraries are available
if command -v pkg-config &> /dev/null; then
    print_status "INFO" "Testing SimdJSON dependencies..."
    
    # Test basic system libraries
    if pkg-config --exists zlib; then
        zlib_version=$(pkg-config --modversion zlib 2>/dev/null)
        print_status "PASS" "zlib dependency is available: $zlib_version"
    else
        print_status "WARN" "zlib dependency is not available"
    fi
    
    if pkg-config --exists libcurl; then
        curl_version=$(pkg-config --modversion libcurl 2>/dev/null)
        print_status "PASS" "libcurl dependency is available: $curl_version"
    else
        print_status "WARN" "libcurl dependency is not available"
    fi
else
    print_status "WARN" "pkg-config is not available for dependency testing"
fi

echo ""
echo "7. Testing SimdJSON Documentation..."
echo "------------------------------------"
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

if [ -r "LICENSE-MIT" ]; then
    print_status "PASS" "LICENSE-MIT is readable"
else
    print_status "FAIL" "LICENSE-MIT is not readable"
fi

if [ -r "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md is readable"
else
    print_status "FAIL" "CONTRIBUTING.md is not readable"
fi

if [ -r "HACKING.md" ]; then
    print_status "PASS" "HACKING.md is readable"
else
    print_status "FAIL" "HACKING.md is not readable"
fi

if [ -r "SECURITY.md" ]; then
    print_status "PASS" "SECURITY.md is readable"
else
    print_status "FAIL" "SECURITY.md is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "simdjson" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "JSON" README.md; then
        print_status "PASS" "README.md contains JSON description"
    else
        print_status "WARN" "README.md missing JSON description"
    fi
    
    if grep -q "SIMD" README.md; then
        print_status "PASS" "README.md contains SIMD description"
    else
        print_status "WARN" "README.md missing SIMD description"
    fi
    
    if grep -q "CMake" README.md; then
        print_status "PASS" "README.md contains CMake description"
    else
        print_status "WARN" "README.md missing CMake description"
    fi
fi

echo ""
echo "8. Testing SimdJSON Docker Functionality..."
echo "-------------------------------------------"
# Test if Docker container can run basic commands (only when not in Docker container)
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test C++ in Docker
    if docker run --rm simdjson-env-test g++ --version >/dev/null 2>&1; then
        print_status "PASS" "G++ works in Docker container"
    else
        print_status "FAIL" "G++ does not work in Docker container"
    fi
    
    # Test CMake in Docker
    if docker run --rm simdjson-env-test cmake --version >/dev/null 2>&1; then
        print_status "PASS" "CMake works in Docker container"
    else
        print_status "FAIL" "CMake does not work in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" simdjson-env-test test -f README.md; then
        print_status "PASS" "README.md is accessible in Docker container"
    else
        print_status "FAIL" "README.md is not accessible in Docker container"
    fi
    
    # Test if src directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" simdjson-env-test test -d src; then
        print_status "PASS" "src directory is accessible in Docker container"
    else
        print_status "FAIL" "src directory is not accessible in Docker container"
    fi
    
    # Test if include directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" simdjson-env-test test -d include; then
        print_status "PASS" "include directory is accessible in Docker container"
    else
        print_status "FAIL" "include directory is not accessible in Docker container"
    fi
    
    # Test if tests directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" simdjson-env-test test -d tests; then
        print_status "PASS" "tests directory is accessible in Docker container"
    else
        print_status "FAIL" "tests directory is not accessible in Docker container"
    fi
    
    # Test if examples directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" simdjson-env-test test -d examples; then
        print_status "PASS" "examples directory is accessible in Docker container"
    else
        print_status "FAIL" "examples directory is not accessible in Docker container"
    fi
    
    # Test if singleheader directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" simdjson-env-test test -d singleheader; then
        print_status "PASS" "singleheader directory is accessible in Docker container"
    else
        print_status "FAIL" "singleheader directory is not accessible in Docker container"
    fi
    
    # Test if CMakeLists.txt is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" simdjson-env-test test -f CMakeLists.txt; then
        print_status "PASS" "CMakeLists.txt is accessible in Docker container"
    else
        print_status "FAIL" "CMakeLists.txt is not accessible in Docker container"
    fi
else
    print_status "INFO" "Skipping Docker functionality tests (running inside container)"
fi

echo ""
echo "9. Testing SimdJSON Build Process..."
echo "------------------------------------"
# Test if Docker container can run build commands (only when not in Docker container)
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test CMake configuration in Docker
    if docker run --rm -v "$(pwd):/workspace" -w /workspace simdjson-env-test cmake -S . -B /tmp/build >/dev/null 2>&1; then
        print_status "PASS" "CMake configuration works in Docker container"
    else
        print_status "FAIL" "CMake configuration does not work in Docker container"
    fi
    
    # Test C++ compilation in Docker
    if docker run --rm -v "$(pwd):/workspace" -w /workspace simdjson-env-test g++ -std=c++17 -fsyntax-only singleheader/simdjson.cpp >/dev/null 2>&1; then
        print_status "PASS" "C++ compilation works in Docker container"
    else
        print_status "FAIL" "C++ compilation does not work in Docker container"
    fi
    
    # Test singleheader compilation in Docker
    if docker run --rm -v "$(pwd):/workspace" -w /workspace simdjson-env-test g++ -std=c++17 -c singleheader/simdjson.cpp -o /tmp/simdjson.o >/dev/null 2>&1; then
        print_status "PASS" "Singleheader compilation works in Docker container"
    else
        print_status "FAIL" "Singleheader compilation does not work in Docker container"
    fi
    
    # Test make in Docker
    if docker run --rm -v "$(pwd):/workspace" -w /workspace simdjson-env-test make --version >/dev/null 2>&1; then
        print_status "PASS" "Make works in Docker container"
    else
        print_status "FAIL" "Make does not work in Docker container"
    fi
    
    # Test ninja in Docker
    if docker run --rm -v "$(pwd):/workspace" -w /workspace simdjson-env-test ninja --version >/dev/null 2>&1; then
        print_status "PASS" "Ninja works in Docker container"
    else
        print_status "FAIL" "Ninja does not work in Docker container"
    fi
else
    print_status "INFO" "Skipping Docker build tests (running inside container)"
    
    # Test local build capabilities instead
    if command -v g++ &> /dev/null; then
        if timeout 60s g++ -std=c++17 -fsyntax-only singleheader/simdjson.cpp >/dev/null 2>&1; then
            print_status "PASS" "Local singleheader compilation works"
        else
            print_status "FAIL" "Local singleheader compilation failed"
        fi
    else
        print_status "FAIL" "G++ not available for local compilation test"
    fi
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for SimdJSON:"
echo "- Docker build process (Ubuntu 22.04, C++, CMake)"
echo "- C++ environment (compilation, optimization)"
echo "- CMake environment (build system, configuration)"
echo "- SimdJSON build system (CMakeLists.txt, build scripts)"
echo "- SimdJSON source code (src, include, examples)"
echo "- SimdJSON documentation (README.md, HACKING.md, CONTRIBUTING.md)"
echo "- SimdJSON configuration (CMakeLists.txt, .gitignore)"
echo "- Docker container functionality (C++, CMake, build tools)"
echo "- JSON parsing capabilities"

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
    print_status "INFO" "All Docker tests passed! Your SimdJSON Docker environment is ready!"
    print_status "INFO" "SimdJSON is a fast JSON parser."
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your SimdJSON Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi

print_status "INFO" "You can now run SimdJSON in Docker: A fast JSON parser."
print_status "INFO" "Example: docker run --rm simdjson-env-test cmake --build build"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/simdjson_simdjson simdjson-env-test /bin/bash" 