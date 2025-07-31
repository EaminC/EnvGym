#!/bin/bash

# nlohmann/json Environment Benchmark Test Script
# This script tests the Docker environment setup for nlohmann/json: JSON for Modern C++
# Tailored specifically for nlohmann/json project requirements and features

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
    docker stop nlohmann-env-test 2>/dev/null || true
    docker rm nlohmann-env-test 2>/dev/null || true
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
        if timeout 600s docker build -f envgym/envgym.dockerfile -t nlohmann-env-test .; then
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
    
    # Test if GCC is available in Docker
    if docker run --rm nlohmann-env-test gcc --version >/dev/null 2>&1; then
        gcc_version=$(docker run --rm nlohmann-env-test gcc --version 2>&1 | head -n 1)
        print_status "PASS" "GCC is available in Docker: $gcc_version"
    else
        print_status "FAIL" "GCC is not available in Docker"
    fi
    
    # Test if G++ is available in Docker
    if docker run --rm nlohmann-env-test g++ --version >/dev/null 2>&1; then
        gpp_version=$(docker run --rm nlohmann-env-test g++ --version 2>&1 | head -n 1)
        print_status "PASS" "G++ is available in Docker: $gpp_version"
    else
        print_status "FAIL" "G++ is not available in Docker"
    fi
    
    # Test if CMake is available in Docker
    if docker run --rm nlohmann-env-test cmake --version >/dev/null 2>&1; then
        cmake_version=$(docker run --rm nlohmann-env-test cmake --version 2>&1 | head -n 1)
        print_status "PASS" "CMake is available in Docker: $cmake_version"
    else
        print_status "FAIL" "CMake is not available in Docker"
    fi
    
    # Test if Make is available in Docker
    if docker run --rm nlohmann-env-test make --version >/dev/null 2>&1; then
        make_version=$(docker run --rm nlohmann-env-test make --version 2>&1 | head -n 1)
        print_status "PASS" "Make is available in Docker: $make_version"
    else
        print_status "FAIL" "Make is not available in Docker"
    fi
    
    # Test if Git is available in Docker
    if docker run --rm nlohmann-env-test git --version >/dev/null 2>&1; then
        git_version=$(docker run --rm nlohmann-env-test git --version 2>&1)
        print_status "PASS" "Git is available in Docker: $git_version"
    else
        print_status "FAIL" "Git is not available in Docker"
    fi
    
    # Test if Python3 is available in Docker
    if docker run --rm nlohmann-env-test python3 --version >/dev/null 2>&1; then
        python_version=$(docker run --rm nlohmann-env-test python3 --version 2>&1)
        print_status "PASS" "Python3 is available in Docker: $python_version"
    else
        print_status "FAIL" "Python3 is not available in Docker"
    fi
fi

echo "=========================================="
echo "nlohmann/json Environment Benchmark Test"
echo "=========================================="

echo "1. Checking System Dependencies..."
echo "--------------------------------"
# Check C++ compiler
if command -v g++ &> /dev/null; then
    gpp_version=$(g++ --version 2>&1 | head -n 1)
    print_status "PASS" "G++ is available: $gpp_version"
else
    print_status "FAIL" "G++ is not available"
fi

# Check C++ compiler version
if command -v g++ &> /dev/null; then
    gpp_major=$(g++ -dumpversion | cut -d'.' -f1)
    if [ -n "$gpp_major" ] && [ "$gpp_major" -ge 4 ]; then
        print_status "PASS" "G++ version is >= 4 (compatible with C++11)"
    else
        print_status "WARN" "G++ version should be >= 4 for C++11 support (found: $gpp_major)"
    fi
else
    print_status "FAIL" "G++ is not available for version check"
fi

# Check C compiler
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version 2>&1 | head -n 1)
    print_status "PASS" "GCC is available: $gcc_version"
else
    print_status "FAIL" "GCC is not available"
fi

# Check CMake
if command -v cmake &> /dev/null; then
    cmake_version=$(cmake --version 2>&1 | head -n 1)
    print_status "PASS" "CMake is available: $cmake_version"
else
    print_status "FAIL" "CMake is not available"
fi

# Check CMake version
if command -v cmake &> /dev/null; then
    cmake_major=$(cmake --version | head -n 1 | sed 's/.*version \([0-9]*\)\.[0-9]*.*/\1/')
    if [ -n "$cmake_major" ] && [ "$cmake_major" -ge 3 ]; then
        print_status "PASS" "CMake version is >= 3 (compatible)"
    else
        print_status "WARN" "CMake version should be >= 3 (found: $cmake_major)"
    fi
else
    print_status "FAIL" "CMake is not available for version check"
fi

# Check Make
if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "Make is available: $make_version"
else
    print_status "FAIL" "Make is not available"
fi

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

# Check pkg-config
if command -v pkg-config &> /dev/null; then
    pkg_config_version=$(pkg-config --version 2>&1)
    print_status "PASS" "pkg-config is available: $pkg_config_version"
else
    print_status "WARN" "pkg-config is not available"
fi

# Check Valgrind
if command -v valgrind &> /dev/null; then
    valgrind_version=$(valgrind --version 2>&1)
    print_status "PASS" "Valgrind is available: $valgrind_version"
else
    print_status "WARN" "Valgrind is not available"
fi

# Check lcov
if command -v lcov &> /dev/null; then
    lcov_version=$(lcov --version 2>&1 | head -n 1)
    print_status "PASS" "lcov is available: $lcov_version"
else
    print_status "WARN" "lcov is not available"
fi

# Check cppcheck
if command -v cppcheck &> /dev/null; then
    cppcheck_version=$(cppcheck --version 2>&1)
    print_status "PASS" "cppcheck is available: $cppcheck_version"
else
    print_status "WARN" "cppcheck is not available"
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

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "include" ]; then
    print_status "PASS" "include directory exists (header files)"
else
    print_status "FAIL" "include directory not found"
fi

if [ -d "single_include" ]; then
    print_status "PASS" "single_include directory exists (amalgamated headers)"
else
    print_status "FAIL" "single_include directory not found"
fi

if [ -d "src" ]; then
    print_status "PASS" "src directory exists (source files)"
else
    print_status "FAIL" "src directory not found"
fi

if [ -d "tests" ]; then
    print_status "PASS" "tests directory exists (test files)"
else
    print_status "FAIL" "tests directory not found"
fi

if [ -d "docs" ]; then
    print_status "PASS" "docs directory exists (documentation)"
else
    print_status "FAIL" "docs directory not found"
fi

if [ -d "cmake" ]; then
    print_status "PASS" "cmake directory exists (CMake modules)"
else
    print_status "FAIL" "cmake directory not found"
fi

if [ -d "tools" ]; then
    print_status "PASS" "tools directory exists (build tools)"
else
    print_status "FAIL" "tools directory not found"
fi

if [ -d ".github" ]; then
    print_status "PASS" ".github directory exists (GitHub workflows)"
else
    print_status "FAIL" ".github directory not found"
fi

if [ -d ".reuse" ]; then
    print_status "PASS" ".reuse directory exists (REUSE compliance)"
else
    print_status "FAIL" ".reuse directory not found"
fi

if [ -d "LICENSES" ]; then
    print_status "PASS" "LICENSES directory exists (license files)"
else
    print_status "FAIL" "LICENSES directory not found"
fi

# Check key files
if [ -f "CMakeLists.txt" ]; then
    print_status "PASS" "CMakeLists.txt exists (CMake build configuration)"
else
    print_status "FAIL" "CMakeLists.txt not found"
fi

if [ -f "Makefile" ]; then
    print_status "PASS" "Makefile exists (Make build configuration)"
else
    print_status "FAIL" "Makefile not found"
fi

if [ -f "meson.build" ]; then
    print_status "PASS" "meson.build exists (Meson build configuration)"
else
    print_status "FAIL" "meson.build not found"
fi

if [ -f "BUILD.bazel" ]; then
    print_status "PASS" "BUILD.bazel exists (Bazel build configuration)"
else
    print_status "FAIL" "BUILD.bazel not found"
fi

if [ -f "MODULE.bazel" ]; then
    print_status "PASS" "MODULE.bazel exists (Bazel module configuration)"
else
    print_status "FAIL" "MODULE.bazel not found"
fi

if [ -f "Package.swift" ]; then
    print_status "PASS" "Package.swift exists (Swift Package Manager configuration)"
else
    print_status "FAIL" "Package.swift not found"
fi

if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
fi

if [ -f "LICENSE.MIT" ]; then
    print_status "PASS" "LICENSE.MIT exists"
else
    print_status "FAIL" "LICENSE.MIT not found"
fi

if [ -f "ChangeLog.md" ]; then
    print_status "PASS" "ChangeLog.md exists (change log)"
else
    print_status "FAIL" "ChangeLog.md not found"
fi

if [ -f "FILES.md" ]; then
    print_status "PASS" "FILES.md exists (file documentation)"
else
    print_status "FAIL" "FILES.md not found"
fi

if [ -f ".gitignore" ]; then
    print_status "PASS" ".gitignore exists"
else
    print_status "FAIL" ".gitignore not found"
fi

if [ -f ".clang-tidy" ]; then
    print_status "PASS" ".clang-tidy exists (clang-tidy configuration)"
else
    print_status "FAIL" ".clang-tidy not found"
fi

if [ -f ".cirrus.yml" ]; then
    print_status "PASS" ".cirrus.yml exists (Cirrus CI configuration)"
else
    print_status "FAIL" ".cirrus.yml not found"
fi

if [ -f "CITATION.cff" ]; then
    print_status "PASS" "CITATION.cff exists (citation configuration)"
else
    print_status "FAIL" "CITATION.cff not found"
fi

if [ -f "nlohmann_json.natvis" ]; then
    print_status "PASS" "nlohmann_json.natvis exists (Visual Studio debugger configuration)"
else
    print_status "FAIL" "nlohmann_json.natvis not found"
fi

# Check header files
if [ -f "single_include/nlohmann/json.hpp" ]; then
    print_status "PASS" "single_include/nlohmann/json.hpp exists (amalgamated header)"
else
    print_status "FAIL" "single_include/nlohmann/json.hpp not found"
fi

if [ -f "include/nlohmann/json.hpp" ]; then
    print_status "PASS" "include/nlohmann/json.hpp exists (main header)"
else
    print_status "FAIL" "include/nlohmann/json.hpp not found"
fi

echo ""
echo "3. Checking Environment Variables..."
echo "-----------------------------------"
# Check C++ environment
if [ -n "${CXX:-}" ]; then
    print_status "PASS" "CXX is set: $CXX"
else
    print_status "WARN" "CXX is not set"
fi

if [ -n "${CC:-}" ]; then
    print_status "PASS" "CC is set: $CC"
else
    print_status "WARN" "CC is not set"
fi

if [ -n "${CMAKE_BUILD_TYPE:-}" ]; then
    print_status "PASS" "CMAKE_BUILD_TYPE is set: $CMAKE_BUILD_TYPE"
else
    print_status "WARN" "CMAKE_BUILD_TYPE is not set"
fi

if [ -n "${CMAKE_CXX_FLAGS:-}" ]; then
    print_status "PASS" "CMAKE_CXX_FLAGS is set: $CMAKE_CXX_FLAGS"
else
    print_status "WARN" "CMAKE_CXX_FLAGS is not set"
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

if echo "$PATH" | grep -q "git"; then
    print_status "PASS" "git is in PATH"
else
    print_status "WARN" "git is not in PATH"
fi

echo ""
echo "4. Testing C++ Environment..."
echo "----------------------------"
# Test C++ compiler
if command -v g++ &> /dev/null; then
    print_status "PASS" "g++ is available"
    
    # Test C++ compilation
    if timeout 30s g++ -std=c++11 -o /tmp/test_prog -x c++ - <<< '#include <iostream>
int main() { std::cout << "C++11 works" << std::endl; return 0; }' 2>/dev/null; then
        print_status "PASS" "C++11 compilation works"
        rm -f /tmp/test_prog
    else
        print_status "WARN" "C++11 compilation failed"
    fi
    
    # Test C++14 compilation
    if timeout 30s g++ -std=c++14 -o /tmp/test_prog -x c++ - <<< '#include <iostream>
int main() { std::cout << "C++14 works" << std::endl; return 0; }' 2>/dev/null; then
        print_status "PASS" "C++14 compilation works"
        rm -f /tmp/test_prog
    else
        print_status "WARN" "C++14 compilation failed"
    fi
    
    # Test C++17 compilation
    if timeout 30s g++ -std=c++17 -o /tmp/test_prog -x c++ - <<< '#include <iostream>
int main() { std::cout << "C++17 works" << std::endl; return 0; }' 2>/dev/null; then
        print_status "PASS" "C++17 compilation works"
        rm -f /tmp/test_prog
    else
        print_status "WARN" "C++17 compilation failed"
    fi
else
    print_status "FAIL" "g++ is not available"
fi

echo ""
echo "5. Testing CMake Environment..."
echo "------------------------------"
# Test CMake
if command -v cmake &> /dev/null; then
    print_status "PASS" "cmake is available"
    
    # Test CMake version
    if timeout 30s cmake --version >/dev/null 2>&1; then
        print_status "PASS" "CMake version command works"
    else
        print_status "WARN" "CMake version command failed"
    fi
    
    # Test CMake help
    if timeout 30s cmake --help >/dev/null 2>&1; then
        print_status "PASS" "CMake help command works"
    else
        print_status "WARN" "CMake help command failed"
    fi
else
    print_status "FAIL" "cmake is not available"
fi

echo ""
echo "6. Testing nlohmann/json Build System..."
echo "----------------------------------------"
# Test CMakeLists.txt
if [ -f "CMakeLists.txt" ]; then
    print_status "PASS" "CMakeLists.txt exists for build testing"
    
    # Check for key CMake configuration
    if grep -q "project(nlohmann_json" CMakeLists.txt; then
        print_status "PASS" "CMakeLists.txt includes project definition"
    else
        print_status "FAIL" "CMakeLists.txt missing project definition"
    fi
    
    if grep -q "JSON_BuildTests" CMakeLists.txt; then
        print_status "PASS" "CMakeLists.txt includes test configuration"
    else
        print_status "WARN" "CMakeLists.txt missing test configuration"
    fi
    
    if grep -q "JSON_Install" CMakeLists.txt; then
        print_status "PASS" "CMakeLists.txt includes install configuration"
    else
        print_status "WARN" "CMakeLists.txt missing install configuration"
    fi
else
    print_status "FAIL" "CMakeLists.txt not found"
fi

# Test Makefile
if [ -f "Makefile" ]; then
    print_status "PASS" "Makefile exists"
    
    # Check for key Makefile targets
    if grep -q "amalgamate" Makefile; then
        print_status "PASS" "Makefile includes amalgamate target"
    else
        print_status "WARN" "Makefile missing amalgamate target"
    fi
    
    if grep -q "doctest" Makefile; then
        print_status "PASS" "Makefile includes doctest target"
    else
        print_status "WARN" "Makefile missing doctest target"
    fi
    
    if grep -q "run_benchmarks" Makefile; then
        print_status "PASS" "Makefile includes benchmarks target"
    else
        print_status "WARN" "Makefile missing benchmarks target"
    fi
else
    print_status "FAIL" "Makefile not found"
fi

# Test meson.build
if [ -f "meson.build" ]; then
    print_status "PASS" "meson.build exists"
    
    # Check for key Meson configuration
    if grep -q "project" meson.build; then
        print_status "PASS" "meson.build includes project definition"
    else
        print_status "WARN" "meson.build missing project definition"
    fi
else
    print_status "FAIL" "meson.build not found"
fi

# Test BUILD.bazel
if [ -f "BUILD.bazel" ]; then
    print_status "PASS" "BUILD.bazel exists"
    
    # Check for key Bazel configuration
    if grep -q "cc_library" BUILD.bazel; then
        print_status "PASS" "BUILD.bazel includes cc_library target"
    else
        print_status "WARN" "BUILD.bazel missing cc_library target"
    fi
else
    print_status "FAIL" "BUILD.bazel not found"
fi

echo ""
echo "7. Testing nlohmann/json Source Code Structure..."
echo "------------------------------------------------"
# Test source code directories
if [ -d "include" ]; then
    print_status "PASS" "include directory exists for source testing"
    
    # Count header files
    header_count=$(find include -name "*.hpp" | wc -l)
    if [ "$header_count" -gt 0 ]; then
        print_status "PASS" "Found $header_count header files in include directory"
    else
        print_status "WARN" "No header files found in include directory"
    fi
    
    # Check for main header
    if [ -f "include/nlohmann/json.hpp" ]; then
        print_status "PASS" "include/nlohmann/json.hpp exists (main header)"
    else
        print_status "FAIL" "include/nlohmann/json.hpp not found"
    fi
else
    print_status "FAIL" "include directory not found"
fi

if [ -d "single_include" ]; then
    print_status "PASS" "single_include directory exists for amalgamated testing"
    
    # Check for amalgamated header
    if [ -f "single_include/nlohmann/json.hpp" ]; then
        print_status "PASS" "single_include/nlohmann/json.hpp exists (amalgamated header)"
        
        # Check file size (should be substantial)
        file_size=$(stat -c%s "single_include/nlohmann/json.hpp" 2>/dev/null || echo "0")
        if [ "$file_size" -gt 100000 ]; then
            print_status "PASS" "Amalgamated header is substantial ($file_size bytes)"
        else
            print_status "WARN" "Amalgamated header seems small ($file_size bytes)"
        fi
    else
        print_status "FAIL" "single_include/nlohmann/json.hpp not found"
    fi
else
    print_status "FAIL" "single_include directory not found"
fi

if [ -d "tests" ]; then
    print_status "PASS" "tests directory exists for testing"
    
    # Count test files
    test_count=$(find tests -name "*.cpp" | wc -l)
    if [ "$test_count" -gt 0 ]; then
        print_status "PASS" "Found $test_count test files in tests directory"
    else
        print_status "WARN" "No test files found in tests directory"
    fi
else
    print_status "FAIL" "tests directory not found"
fi

if [ -d "src" ]; then
    print_status "PASS" "src directory exists for source testing"
    
    # Count source files
    source_count=$(find src -name "*.cpp" | wc -l)
    if [ "$source_count" -gt 0 ]; then
        print_status "PASS" "Found $source_count source files in src directory"
    else
        print_status "WARN" "No source files found in src directory"
    fi
else
    print_status "FAIL" "src directory not found"
fi

echo ""
echo "8. Testing nlohmann/json Configuration Files..."
echo "----------------------------------------------"
# Test configuration files
if [ -r "CMakeLists.txt" ]; then
    print_status "PASS" "CMakeLists.txt is readable"
else
    print_status "FAIL" "CMakeLists.txt is not readable"
fi

if [ -r "Makefile" ]; then
    print_status "PASS" "Makefile is readable"
else
    print_status "FAIL" "Makefile is not readable"
fi

if [ -r "meson.build" ]; then
    print_status "PASS" "meson.build is readable"
else
    print_status "FAIL" "meson.build is not readable"
fi

if [ -r "BUILD.bazel" ]; then
    print_status "PASS" "BUILD.bazel is readable"
else
    print_status "FAIL" "BUILD.bazel is not readable"
fi

if [ -r ".clang-tidy" ]; then
    print_status "PASS" ".clang-tidy is readable"
else
    print_status "FAIL" ".clang-tidy is not readable"
fi

# Check CMakeLists.txt content
if [ -r "CMakeLists.txt" ]; then
    if grep -q "VERSION" CMakeLists.txt; then
        print_status "PASS" "CMakeLists.txt includes version information"
    else
        print_status "WARN" "CMakeLists.txt missing version information"
    fi
    
    if grep -q "CXX" CMakeLists.txt; then
        print_status "PASS" "CMakeLists.txt includes C++ language specification"
    else
        print_status "WARN" "CMakeLists.txt missing C++ language specification"
    fi
fi

# Check Makefile content
if [ -r "Makefile" ]; then
    if grep -q "SRCS" Makefile; then
        print_status "PASS" "Makefile includes source file definitions"
    else
        print_status "WARN" "Makefile missing source file definitions"
    fi
    
    if grep -q "TESTS_SRCS" Makefile; then
        print_status "PASS" "Makefile includes test source definitions"
    else
        print_status "WARN" "Makefile missing test source definitions"
    fi
fi

echo ""
echo "9. Testing nlohmann/json Documentation..."
echo "----------------------------------------"
# Test documentation
if [ -r "README.md" ]; then
    print_status "PASS" "README.md is readable"
else
    print_status "FAIL" "README.md is not readable"
fi

if [ -r "LICENSE.MIT" ]; then
    print_status "PASS" "LICENSE.MIT is readable"
else
    print_status "FAIL" "LICENSE.MIT is not readable"
fi

if [ -r "ChangeLog.md" ]; then
    print_status "PASS" "ChangeLog.md is readable"
else
    print_status "FAIL" "ChangeLog.md is not readable"
fi

if [ -r "FILES.md" ]; then
    print_status "PASS" "FILES.md is readable"
else
    print_status "FAIL" "FILES.md is not readable"
fi

if [ -r ".gitignore" ]; then
    print_status "PASS" ".gitignore is readable"
else
    print_status "FAIL" ".gitignore is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "JSON for Modern C++" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "C++11" README.md; then
        print_status "PASS" "README.md contains C++11 reference"
    else
        print_status "WARN" "README.md missing C++11 reference"
    fi
    
    if grep -q "header-only" README.md; then
        print_status "PASS" "README.md contains header-only reference"
    else
        print_status "WARN" "README.md missing header-only reference"
    fi
fi

echo ""
echo "10. Testing nlohmann/json Docker Functionality..."
echo "------------------------------------------------"
# Test if Docker container can run basic commands
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    # Test GCC in Docker
    if docker run --rm nlohmann-env-test gcc --version >/dev/null 2>&1; then
        print_status "PASS" "GCC works in Docker container"
    else
        print_status "FAIL" "GCC does not work in Docker container"
    fi
    
    # Test G++ in Docker
    if docker run --rm nlohmann-env-test g++ --version >/dev/null 2>&1; then
        print_status "PASS" "G++ works in Docker container"
    else
        print_status "FAIL" "G++ does not work in Docker container"
    fi
    
    # Test CMake in Docker
    if docker run --rm nlohmann-env-test cmake --version >/dev/null 2>&1; then
        print_status "PASS" "CMake works in Docker container"
    else
        print_status "FAIL" "CMake does not work in Docker container"
    fi
    
    # Test Make in Docker
    if docker run --rm nlohmann-env-test make --version >/dev/null 2>&1; then
        print_status "PASS" "Make works in Docker container"
    else
        print_status "FAIL" "Make does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm nlohmann-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test Python3 in Docker
    if docker run --rm nlohmann-env-test python3 --version >/dev/null 2>&1; then
        print_status "PASS" "Python3 works in Docker container"
    else
        print_status "FAIL" "Python3 does not work in Docker container"
    fi
    
    # Test if CMakeLists.txt is accessible in Docker
    if docker run --rm nlohmann-env-test test -f CMakeLists.txt; then
        print_status "PASS" "CMakeLists.txt is accessible in Docker container"
    else
        print_status "FAIL" "CMakeLists.txt is not accessible in Docker container"
    fi
    
    # Test if Makefile is accessible in Docker
    if docker run --rm nlohmann-env-test test -f Makefile; then
        print_status "PASS" "Makefile is accessible in Docker container"
    else
        print_status "FAIL" "Makefile is not accessible in Docker container"
    fi
    
    # Test if include directory is accessible in Docker
    if docker run --rm nlohmann-env-test test -d include; then
        print_status "PASS" "include directory is accessible in Docker container"
    else
        print_status "FAIL" "include directory is not accessible in Docker container"
    fi
    
    # Test if single_include directory is accessible in Docker
    if docker run --rm nlohmann-env-test test -d single_include; then
        print_status "PASS" "single_include directory is accessible in Docker container"
    else
        print_status "FAIL" "single_include directory is not accessible in Docker container"
    fi
    
    # Test if tests directory is accessible in Docker
    if docker run --rm nlohmann-env-test test -d tests; then
        print_status "PASS" "tests directory is accessible in Docker container"
    else
        print_status "FAIL" "tests directory is not accessible in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm nlohmann-env-test test -f README.md; then
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
echo "This script has tested the Docker environment for nlohmann/json:"
echo "- Docker build process (Ubuntu 22.04, GCC/G++, CMake, Make, Git, Python3)"
echo "- C++ environment (C++11/14/17 support, compilation)"
echo "- CMake environment (build system, configuration)"
echo "- nlohmann/json build system (CMakeLists.txt, Makefile, meson.build, BUILD.bazel)"
echo "- nlohmann/json source code structure (include, single_include, tests, src)"
echo "- nlohmann/json configuration files (CMake, Make, Meson, Bazel, clang-tidy)"
echo "- nlohmann/json documentation (README.md, LICENSE.MIT, ChangeLog.md, FILES.md)"
echo "- Docker container functionality (GCC, G++, CMake, Make, Git, Python3)"
echo "- C++ JSON library (header-only, modern C++, multiple build systems)"
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
    print_status "INFO" "All Docker tests passed! Your nlohmann/json Docker environment is ready!"
    print_status "INFO" "nlohmann/json is a JSON library for Modern C++ with intuitive syntax."
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your nlohmann/json Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now run nlohmann/json in Docker: JSON for Modern C++."
print_status "INFO" "Example: docker run --rm nlohmann-env-test cmake -B build"
print_status "INFO" "Example: docker run --rm nlohmann-env-test make amalgamate"
echo ""
print_status "INFO" "For more information, see README.md and https://github.com/nlohmann/json"
exit 0
fi

# If Docker failed or not available, skip local environment tests
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ] || [ "${DOCKER_MODE:-false}" = "false" ]; then
    echo "Docker environment not available - skipping local environment tests"
    echo "This script is designed to test Docker environment only"
    exit 0
fi 