#!/bin/bash

# cpp-httplib Environment Benchmark Test Script
# This script tests the Docker environment setup for cpp-httplib: C++11 single-header HTTP/HTTPS library
# Tailored specifically for cpp-httplib project requirements and features

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
    docker stop cpp-httplib-env-test 2>/dev/null || true
    docker rm cpp-httplib-env-test 2>/dev/null || true
    exit 0
}
trap cleanup SIGINT SIGTERM

# ========== 1. Docker Build Phase ==========
echo "=========================================="
echo "1. Building Docker Environment..."
echo "=========================================="

if ! command -v docker &> /dev/null; then
    print_status "FAIL" "Docker is not installed. Cannot test Docker environment."
    echo -e "\n[INFO] Docker Environment Score: 0% (0/0 tests passed)"
    exit 1
fi

if [ ! -f "envgym/envgym.dockerfile" ]; then
    print_status "FAIL" "envgym.dockerfile not found. Cannot test Docker environment."
    echo -e "\n[INFO] Docker Environment Score: 0% (0/0 tests passed)"
    exit 1
fi

print_status "INFO" "Building Docker image..."
if timeout 900s docker build -f envgym/envgym.dockerfile -t cpp-httplib-env-test .; then
    print_status "PASS" "Docker image built successfully."
else
    print_status "FAIL" "Docker image build failed. See above for details."
    echo ""
    echo "=========================================="
    echo "cpp-httplib Environment Test Complete"
    echo "=========================================="
    echo ""
    echo "Summary:"
    echo "--------"
    echo "Docker build failed - environment not ready for cpp-httplib development"
    echo ""
    echo "=========================================="
    echo "Test Results Summary"
    echo "=========================================="
    echo -e "${GREEN}PASS: 0${NC}"
    echo -e "${RED}FAIL: 0${NC}"
    echo -e "${YELLOW}WARN: 0${NC}"
    echo ""
    print_status "INFO" "Docker Environment Score: 0% (0/0 tests passed)"
    echo ""
    print_status "FAIL" "Docker build failed - cpp-httplib environment is not ready!"
    print_status "INFO" "Please fix the Docker build issues before using this environment"
    exit 1
fi

# ========== 2. Checking Toolchain ==========
echo ""
echo "2. Checking Toolchain..."
echo "-------------------------"
for tool in g++ gcc clang-format cmake meson ninja make git curl wget pkg-config python3 pip3 openssl pre-commit; do
    if docker run --rm cpp-httplib-env-test bash -c "command -v $tool" >/dev/null 2>&1; then
        version=$(docker run --rm cpp-httplib-env-test bash -c "$tool --version 2>&1 | head -n1")
        print_status "PASS" "$tool available: $version"
    else
        print_status "FAIL" "$tool not available"
    fi
done

# ========== 3. Checking Libraries ==========
echo ""
echo "3. Checking Libraries..."
echo "-------------------------"
for lib in libssl-dev zlib1g-dev libbrotli-dev libzstd-dev libcurl4-openssl-dev libgtest-dev; do
    if docker run --rm cpp-httplib-env-test bash -c "dpkg -s $lib >/dev/null 2>&1"; then
        print_status "PASS" "$lib is installed"
    else
        print_status "FAIL" "$lib is not installed"
    fi
done

# ========== 4. Checking Project Structure ==========
echo ""
echo "4. Checking Project Structure..."
echo "-------------------------------"
for d in test example benchmark cmake docker .github; do
    if docker run --rm -v "$(pwd):/workspace" -w /workspace cpp-httplib-env-test test -d "$d"; then
        print_status "PASS" "$d directory exists"
    else
        print_status "WARN" "$d directory does not exist"
    fi
done
for f in httplib.h LICENSE README.md CMakeLists.txt meson.build meson_options.txt test/Makefile test/test.cc; do
    if docker run --rm -v "$(pwd):/workspace" -w /workspace cpp-httplib-env-test test -f "$f"; then
        print_status "PASS" "$f exists"
    else
        print_status "FAIL" "$f does not exist"
    fi
done

# ========== 5. Checking Source Files ==========
echo ""
echo "5. Checking Source Files..."
echo "---------------------------"
if docker run --rm -v "$(pwd):/workspace" -w /workspace cpp-httplib-env-test test -r httplib.h; then
    print_status "PASS" "httplib.h is readable"
else
    print_status "FAIL" "httplib.h is not readable"
fi

cpp_files=$(find . -name "*.cc" | wc -l)
h_files=$(find . -name "*.h" | wc -l)
if [ "$cpp_files" -gt 0 ]; then
    print_status "PASS" "Found $cpp_files C++ source files (*.cc)"
else
    print_status "WARN" "No C++ source files (*.cc) found"
fi
if [ "$h_files" -gt 0 ]; then
    print_status "PASS" "Found $h_files header files (*.h)"
else
    print_status "FAIL" "No header files (*.h) found"
fi

# ========== 6. Build/Test in Docker ==========
echo ""
echo "6. Testing Build in Docker..."
echo "-----------------------------"
print_status "INFO" "Attempting to compile test/test.cc in container..."
if docker run --rm -v "$(pwd):/workspace" -w /workspace/test cpp-httplib-env-test bash -c 'g++ -std=c++11 -I.. test.cc include_httplib.cc -o test_bin -lpthread -lcurl -lssl -lcrypto -lz -lbrotlicommon -lbrotlienc -lbrotlidec -lzstd'; then
    print_status "PASS" "test/test.cc compiled successfully (g++)"
else
    print_status "FAIL" "test/test.cc failed to compile (g++)"
fi

# ========== 7. Documentation ==========
echo ""
echo "7. Checking Documentation..."
echo "----------------------------"
for doc in README.md LICENSE; do
    if docker run --rm -v "$(pwd):/workspace" -w /workspace cpp-httplib-env-test test -r "$doc"; then
        print_status "PASS" "$doc is readable"
    else
        print_status "FAIL" "$doc is not readable"
    fi
done

# ========== 8. Docker Functionality ==========
echo ""
echo "8. Checking Docker Functionality..."
echo "-----------------------------------"
# Test if Docker container can run basic commands and access files
if docker run --rm cpp-httplib-env-test g++ --version >/dev/null 2>&1; then
    print_status "PASS" "g++ works in Docker container"
else
    print_status "FAIL" "g++ does not work in Docker container"
fi
if docker run --rm cpp-httplib-env-test cmake --version >/dev/null 2>&1; then
    print_status "PASS" "cmake works in Docker container"
else
    print_status "FAIL" "cmake does not work in Docker container"
fi
if docker run --rm -v "$(pwd):/workspace" cpp-httplib-env-test test -f README.md; then
    print_status "PASS" "README.md is accessible in Docker container"
else
    print_status "FAIL" "README.md is not accessible in Docker container"
fi
if docker run --rm -v "$(pwd):/workspace" cpp-httplib-env-test test -f httplib.h; then
    print_status "PASS" "httplib.h is accessible in Docker container"
else
    print_status "FAIL" "httplib.h is not accessible in Docker container"
fi

# ========== 9. Summary ==========
echo ""
echo "=========================================="
echo "cpp-httplib Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for cpp-httplib:"
echo "- Docker build process (Ubuntu 22.04, g++-13, cmake, meson, ninja, make, git, curl, wget, pkg-config, python3, pip3, openssl, pre-commit)"
echo "- C++ toolchain and libraries (OpenSSL, zlib, brotli, zstd, curl, gtest)"
echo "- Project structure (test, example, benchmark, cmake, docker, .github, key files)"
echo "- Source/header files (*.cc, *.h)"
echo "- Build/test in Docker (g++ compile)"
echo "- Documentation (README.md, LICENSE)"
echo "- Docker container functionality (toolchain, file access)"
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
    print_status "INFO" "All Docker tests passed! Your cpp-httplib Docker environment is ready!"
    print_status "INFO" "cpp-httplib is a C++11 single-header HTTP/HTTPS library."
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your cpp-httplib Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now run cpp-httplib in Docker: A C++11 single-header HTTP/HTTPS library."
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace cpp-httplib-env-test g++ --version"
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace cpp-httplib-env-test cmake --version"
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace cpp-httplib-env-test bash -c 'g++ -std=c++11 -I. test/test.cc -o test_bin'"
echo ""
print_status "INFO" "For more information, see README.md and https://github.com/yhirose/cpp-httplib" 