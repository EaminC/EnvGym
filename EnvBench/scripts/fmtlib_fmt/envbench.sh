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

# Function to print proportional status with scoring
print_proportional_status() {
    local actual=$1
    local total=$2
    local max_points=$3
    local message=$4
    
    # Pure bash arithmetic approach - more reliable across environments
    # Calculate score using integer arithmetic
    if [ "$total" -ne "0" ]; then
        # Use bc for floating point if available
        if command -v bc &>/dev/null; then
            # Calculate with bc but ensure we get a value (or default to 0)
            local raw_score=$(echo "scale=6; ($actual * $max_points) / $total" | bc 2>/dev/null || echo "0")
            # Round to nearest integer by adding 0.5 and truncating
            local rounded_score=$(echo "$raw_score + 0.5" | bc | cut -d. -f1)
        else
            # Fallback to bash arithmetic (less precise)
            local pct=$(( actual * 100 / total ))
            local rounded_score=$(( pct * max_points / 100 ))
        fi
    else
        local rounded_score=0
    fi
    
    # Ensure score is within bounds
    if [ "$rounded_score" -gt "$max_points" ]; then
        rounded_score=$max_points
    elif [ "$rounded_score" -lt "0" ]; then
        rounded_score=0
    fi
    
    # Add to PASS_COUNT (treating as positive achievement)
    PASS_COUNT=$((PASS_COUNT + rounded_score))
    
    # Add remaining points to FAIL_COUNT
    local fail_points=$((max_points - rounded_score))
    FAIL_COUNT=$((FAIL_COUNT + fail_points))
    
    # Print with color based on performance
    if [ "$actual" -eq "$total" ]; then
        echo -e "${GREEN}[PASS]${NC} $message (Score: $rounded_score/$max_points)"
    elif [ "$actual" -gt "$((total / 2))" ]; then
        echo -e "${YELLOW}[PARTIAL]${NC} $message (Score: $rounded_score/$max_points)"  
    else
        echo -e "${RED}[LOW]${NC} $message (Score: $rounded_score/$max_points)"
    fi
}

# Cleanup function
cleanup() {
    echo "Cleaning up..."
    # Kill any background processes
    jobs -p | xargs -r kill
    # Remove temporary files
    rm -f docker_build.log
    # Remove temporary test directories
    rm -rf fmt_test_build fmt_test_header_only fmt_test_shared fmt_basic_test
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
            print_status "INFO" "Dockerfile structure looks good."
        else
            print_status "WARN" "Dockerfile has some issues that should be fixed."
        fi
        echo ""
    else
        print_status "FAIL" "envgym/envgym.dockerfile not found"
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

echo ""
echo "2. Checking Required Project Files..."
echo "-----------------------------------"

# Check key files and directories (reduced from previous version to avoid "free scores")
required_dirs=("include/fmt" "src" "test")
required_count=0
found_count=0

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        print_status "PASS" "$dir directory exists"
        ((found_count++))
    else
        print_status "FAIL" "$dir directory not found"
    fi
    ((required_count++))
done

critical_files=("CMakeLists.txt" "include/fmt/format.h" "include/fmt/core.h" "src/format.cc")
for file in "${critical_files[@]}"; do
    if [ -f "$file" ]; then
        print_status "PASS" "$file exists"
        ((found_count++))
    else
        print_status "FAIL" "$file not found"
    fi
    ((required_count++))
done

# Score based on required project files found
print_proportional_status $found_count $required_count 5 "Required project files check"

echo ""
echo "3. Testing C/C++ Compilation..."
echo "-------------------------------"
# Test C++ compilation with std::format compatibility
if command -v g++ &> /dev/null; then
    print_status "PASS" "g++ is available"
    
    # Create a simple test program that uses fmt
    mkdir -p fmt_basic_test
    cat > fmt_basic_test/basic_test.cpp << 'EOF'
#include <iostream>
#include "fmt/core.h"

int main() {
    std::string name = "world";
    fmt::print("Hello, {}!\n", name);
    
    // Test formatting integers
    fmt::print("The answer is {}\n", 42);
    
    // Test formatting floats
    fmt::print("Pi is approximately {:.2f}\n", 3.14159);
    
    // Test formatting with positional arguments
    fmt::print("I'd rather be {1} than {0}.\n", "right", "happy");
    
    return 0;
}
EOF

    # Try to compile and run with different C++ standards
    cpp_standards=("c++11" "c++14" "c++17")
    cpp_passed=0
    cpp_total=${#cpp_standards[@]}
    
    for std in "${cpp_standards[@]}"; do
        # Try header-only mode first (more reliable)
        if timeout 60s g++ -std=$std -DFMT_HEADER_ONLY -Iinclude fmt_basic_test/basic_test.cpp -o fmt_basic_test/basic_test_$std 2>/dev/null; then
            print_status "PASS" "Compilation with $std standard succeeded"
            if timeout 30s ./fmt_basic_test/basic_test_$std >/dev/null 2>&1; then
                print_status "PASS" "Execution with $std standard succeeded"
                ((cpp_passed++))
            else
                print_status "FAIL" "Execution with $std standard failed"
            fi
        else
            # Fallback: try linking with built library if available
            if [ -f "fmt_test_build/libfmt.a" ]; then
                if timeout 60s g++ -std=$std -Iinclude fmt_basic_test/basic_test.cpp fmt_test_build/libfmt.a -o fmt_basic_test/basic_test_$std 2>/dev/null; then
                    print_status "PASS" "Compilation with $std standard succeeded (using built library)"
                    if timeout 30s ./fmt_basic_test/basic_test_$std >/dev/null 2>&1; then
                        print_status "PASS" "Execution with $std standard succeeded"
                        ((cpp_passed++))
                    else
                        print_status "FAIL" "Execution with $std standard failed"
                    fi
                else
                    print_status "FAIL" "Compilation with $std standard failed"
                fi
            else
                print_status "FAIL" "Compilation with $std standard failed"
            fi
        fi
    done
    
    # Score based on C++ standards compatibility
    print_proportional_status $cpp_passed $cpp_total 6 "C++ standards compatibility tests"
    
else
    print_status "FAIL" "g++ is not available for compilation tests"
fi

echo ""
echo "4. Testing Library Build Configurations..."
echo "----------------------------------------"

# Test standard static library build
if command -v cmake &> /dev/null && command -v make &> /dev/null; then
    build_configs=("standard" "header_only" "shared")
    build_passed=0
    build_total=${#build_configs[@]}
    
    # Standard build
    mkdir -p fmt_test_build
    cd fmt_test_build
    if timeout 300s cmake .. -DCMAKE_BUILD_TYPE=Release >/dev/null 2>&1; then
        print_status "PASS" "CMake configuration for standard build succeeded"
        if timeout 300s make -j$(nproc) >/dev/null 2>&1; then
            print_status "PASS" "Standard build succeeded"
            ((build_passed++))
        else
            print_status "FAIL" "Standard build failed"
        fi
    else
        print_status "FAIL" "CMake configuration for standard build failed"
    fi
    cd ..
    
    # Header-only build
    mkdir -p fmt_test_header_only
    cd fmt_test_header_only
    if timeout 300s cmake .. -DCMAKE_BUILD_TYPE=Release -DFMT_HEADER_ONLY=ON >/dev/null 2>&1; then
        print_status "PASS" "CMake configuration for header-only build succeeded"
        if timeout 300s make -j$(nproc) >/dev/null 2>&1; then
            print_status "PASS" "Header-only build succeeded"
            ((build_passed++))
        else
            print_status "FAIL" "Header-only build failed"
        fi
    else
        print_status "FAIL" "CMake configuration for header-only build failed"
    fi
    cd ..
    
    # Shared library build
    mkdir -p fmt_test_shared
    cd fmt_test_shared
    if timeout 300s cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON >/dev/null 2>&1; then
        print_status "PASS" "CMake configuration for shared library build succeeded"
        if timeout 300s make -j$(nproc) >/dev/null 2>&1; then
            print_status "PASS" "Shared library build succeeded"
            ((build_passed++))
        else
            print_status "FAIL" "Shared library build failed"
        fi
    else
        print_status "FAIL" "CMake configuration for shared library build failed"
    fi
    cd ..
    
    # Score based on build configuration tests
    print_proportional_status $build_passed $build_total 10 "Build configuration tests"
    
else
    print_status "FAIL" "CMake or Make is not available for build tests"
fi

echo ""
echo "5. Testing Advanced Library Features..."
echo "--------------------------------------"

# Create a test file for advanced fmt features
mkdir -p fmt_basic_test
cat > fmt_basic_test/advanced_test.cpp << 'EOF'
#include <iostream>
#include <vector>
#include <map>
#include "fmt/core.h"
#include "fmt/color.h"
#include "fmt/chrono.h"
#include "fmt/ranges.h"

int main() {
    // Test 1: Basic formatting
    std::string name = "world";
    fmt::print("Hello, {}!\n", name);
    
    // Test 2: Colored output
    fmt::print(fmt::fg(fmt::color::crimson), "This should be in crimson color\n");
    
    // Test 3: Chrono formatting
    auto now = std::chrono::system_clock::now();
    fmt::print("Current time: {:%Y-%m-%d %H:%M:%S}\n", now);
    
    // Test 4: Container formatting
    std::vector<int> v = {1, 2, 3};
    fmt::print("Vector contents: {}\n", v);
    
    // Test 5: Map formatting
    std::map<std::string, int> map{{"one", 1}, {"two", 2}};
    fmt::print("Map contents: {}\n", map);
    
    return 0;
}
EOF

feature_tests=0
feature_passed=0

if command -v g++ &> /dev/null; then
    # Test 1: Advanced formatting
    ((feature_tests++))
    # Try header-only mode first (more reliable for advanced features)
    if timeout 60s g++ -std=c++17 -DFMT_HEADER_ONLY -Iinclude fmt_basic_test/advanced_test.cpp -o fmt_basic_test/advanced_test 2>/dev/null; then
        print_status "PASS" "Advanced features compilation succeeded"
        if timeout 30s ./fmt_basic_test/advanced_test >/dev/null 2>&1; then
            print_status "PASS" "Advanced features execution succeeded"
            ((feature_passed++))
        else
            print_status "FAIL" "Advanced features execution failed"
        fi
    else
        # Fallback: try linking with built library if available
        if [ -f "fmt_test_build/libfmt.a" ]; then
            if timeout 60s g++ -std=c++17 -Iinclude fmt_basic_test/advanced_test.cpp fmt_test_build/libfmt.a -o fmt_basic_test/advanced_test 2>/dev/null; then
                print_status "PASS" "Advanced features compilation succeeded (using built library)"
                if timeout 30s ./fmt_basic_test/advanced_test >/dev/null 2>&1; then
                    print_status "PASS" "Advanced features execution succeeded"
                    ((feature_passed++))
                else
                    print_status "FAIL" "Advanced features execution failed"
                fi
            else
                print_status "FAIL" "Advanced features compilation failed"
            fi
        else
            print_status "FAIL" "Advanced features compilation failed"
        fi
    fi
    
    # Score based on advanced feature tests
    print_proportional_status $feature_passed $feature_tests 5 "Advanced library features test"
else
    print_status "FAIL" "g++ is not available for advanced feature tests"
fi

echo ""
echo "6. Running Test Suite..."
echo "-----------------------"

if command -v cmake &> /dev/null && [ -d "fmt_test_build" ]; then
    cd fmt_test_build
    
    # Build tests if they haven't been built yet
    if ! [ -f "bin/format-test" ] && ! [ -f "test/format-test" ]; then
        print_status "INFO" "Building tests..."
        if timeout 300s make -j$(nproc) >/dev/null 2>&1; then
            print_status "PASS" "Test build succeeded"
        else
            print_status "FAIL" "Test build failed"
        fi
    fi
    
    # Count total tests
    test_count=$(ls bin/*-test test/*-test 2>/dev/null | wc -l)
    if [ "$test_count" -eq 0 ]; then
        test_count=$(find . -name "*-test" -type f -executable | wc -l)
    fi
    
    if [ "$test_count" -eq 0 ]; then
        print_status "FAIL" "No test executables found"
        test_passed=0
        # Try to run CTest anyway
        if timeout 600s ctest --output-on-failure >/dev/null 2>&1; then
            print_status "PASS" "CTest execution succeeded but no test count available"
        else
            print_status "FAIL" "CTest execution failed"
        fi
    else
        print_status "INFO" "Found $test_count test executables"
        
        # Run tests with ctest
        test_output=$(timeout 600s ctest --output-on-failure 2>&1) || true
        
        # Check how many tests passed
        if echo "$test_output" | grep -q "[0-9]*% tests passed"; then
            test_percent=$(echo "$test_output" | grep "[0-9]*% tests passed" | sed 's/^.*\([0-9][0-9]*\)% tests passed.*$/\1/')
            test_passed=$(( test_count * test_percent / 100 ))
            print_status "INFO" "$test_percent% of tests passed ($test_passed/$test_count)"
        else
            # Fall back to just checking if ctest ran successfully
            if echo "$test_output" | grep -q "100% tests passed" || timeout 600s make test >/dev/null 2>&1; then
                test_passed=$test_count
                print_status "PASS" "All tests passed ($test_passed/$test_count)"
            else
                # Conservatively estimate half the tests passed
                test_passed=$(( test_count / 2 ))
                print_status "WARN" "Some tests failed, estimating $test_passed/$test_count passed"
            fi
        fi
        
        # Score based on test suite results
        print_proportional_status $test_passed $test_count 15 "Test suite execution"
    fi
    
    cd ..
else
    print_status "FAIL" "Cannot run test suite - build directory or cmake not available"
fi

echo ""
echo "7. Testing Header-Only Mode Integration..."
echo "----------------------------------------"

# Create a simple test program using header-only mode
mkdir -p fmt_basic_test
cat > fmt_basic_test/header_only_test.cpp << 'EOF'
#define FMT_HEADER_ONLY
#include "fmt/core.h"

int main() {
    fmt::print("Header-only mode works: {}\n", 42);
    return 0;
}
EOF

if command -v g++ &> /dev/null; then
    if timeout 60s g++ -std=c++11 -Iinclude fmt_basic_test/header_only_test.cpp -o fmt_basic_test/header_only_test 2>/dev/null; then
        print_status "PASS" "Header-only mode compilation succeeded"
        if timeout 30s ./fmt_basic_test/header_only_test >/dev/null 2>&1; then
            print_status "PASS" "Header-only mode execution succeeded"
            # Award 5 points directly for header-only mode
            PASS_COUNT=$((PASS_COUNT + 5))
            print_status "INFO" "Header-only mode integration test passed (Score: 5 points)"
        else
            print_status "FAIL" "Header-only mode execution failed"
        fi
    else
        print_status "FAIL" "Header-only mode compilation failed"
    fi
else
    print_status "FAIL" "g++ is not available for header-only mode test"
fi

echo ""
echo "8. Testing System Integration..."
echo "------------------------------"

# Test if fmt library can be found with pkg-config (if available)
if command -v pkg-config &> /dev/null; then
    if [ -d "fmt_test_build" ]; then
        cd fmt_test_build
        if [ -f "fmt.pc" ]; then
            print_status "PASS" "fmt.pc file exists"
            # Try to run pkg-config
            export PKG_CONFIG_PATH=$(pwd):$PKG_CONFIG_PATH
            if pkg-config --exists fmt 2>/dev/null; then
                print_status "PASS" "pkg-config finds fmt"
                # Award 2 points directly for pkg-config integration
                PASS_COUNT=$((PASS_COUNT + 2))
                print_status "INFO" "System integration via pkg-config works (Score: 2 points)"
            else
                print_status "FAIL" "pkg-config cannot find fmt"
            fi
        else
            print_status "WARN" "fmt.pc file not found"
        fi
        cd ..
    else
        print_status "WARN" "Build directory not available for pkg-config test"
    fi
else
    print_status "WARN" "pkg-config not available for system integration test"
fi

# Check if cmake config files are generated
if [ -d "fmt_test_build" ]; then
    if [ -f "fmt_test_build/fmt-config.cmake" ] || [ -f "fmt_test_build/fmtConfig.cmake" ]; then
        print_status "PASS" "CMake config files are generated"
        # Award 2 points directly for cmake integration
        PASS_COUNT=$((PASS_COUNT + 2))
        print_status "INFO" "System integration via CMake works (Score: 2 points)"
    else
        print_status "WARN" "CMake config files are not generated"
    fi
else
    print_status "WARN" "Build directory not available for CMake integration test"
fi

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (GCC, G++, Clang, CMake, Make, Ninja, Git)"
echo "- Required project files structure"
echo "- C++ compilation with different standards (C++11, C++14, C++17)"
echo "- Library build configurations (Standard, Header-only, Shared)"
echo "- Advanced library features (chrono, color, ranges)"
echo "- Test suite execution"
echo "- Header-only mode integration"
echo "- System integration (pkg-config, CMake)"

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
