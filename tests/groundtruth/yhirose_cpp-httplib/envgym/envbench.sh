#!/bin/bash

# C++ HTTPLib Environment Benchmark Test Script
# This script tests the Docker environment setup for C++ HTTPLib: A C++ HTTP/HTTPS library
# Tailored specifically for C++ HTTPLib project requirements and features

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
    docker stop cpp-httplib-env-test 2>/dev/null || true
    docker rm cpp-httplib-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the yhirose_cpp-httplib project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t cpp-httplib-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/yhirose_cpp-httplib" cpp-httplib-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        cd /home/cc/EnvGym/data/yhirose_cpp-httplib
        bash envgym/envbench.sh
        # Script completed successfully
    " > /tmp/docker_output.txt 2>&1
    
    # Extract test results from the output and create JSON
    PASS_COUNT=$(grep -o "PASS: [0-9]*" /tmp/docker_output.txt | tail -1 | grep -o "[0-9]*" || echo "0")
    FAIL_COUNT=$(grep -o "FAIL: [0-9]*" /tmp/docker_output.txt | tail -1 | grep -o "[0-9]*" || echo "0")
    WARN_COUNT=$(grep -o "WARN: [0-9]*" /tmp/docker_output.txt | tail -1 | grep -o "[0-9]*" || echo "0")
    
    # Create JSON file with extracted results
    cat > envgym/envbench.json << EOF
{
    "PASS": $PASS_COUNT,
    "FAIL": $FAIL_COUNT,
    "WARN": $WARN_COUNT
}
EOF
    echo -e "${BLUE}[INFO]${NC} JSON results extracted and saved to envgym/envbench.json (PASS: $PASS_COUNT, FAIL: $FAIL_COUNT, WARN: $WARN_COUNT)"
    
    # Clean up
    rm -f /tmp/docker_output.txt
    exit 0
fi

echo "=========================================="
echo "C++ HTTPLib Environment Benchmark Test"
echo "=========================================="

# ========== 1. Docker Build Phase ==========
echo "=========================================="
echo "1. Building Docker Environment..."
echo "=========================================="

# Only check Docker and build if we're not inside a container
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
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
else
    print_status "INFO" "Running inside Docker container - skipping Docker build phase"
fi

# ========== 2. Checking Toolchain ==========
echo ""
echo "2. Checking Toolchain..."
echo "-------------------------"
# Only run Docker tests if we're not inside a container
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
    for tool in g++ gcc clang-format cmake meson ninja make git curl wget pkg-config python3 pip3 openssl pre-commit; do
        if docker run --rm cpp-httplib-env-test bash -c "command -v $tool" >/dev/null 2>&1; then
            version=$(docker run --rm cpp-httplib-env-test bash -c "$tool --version 2>&1 | head -n1")
            print_status "PASS" "$tool available: $version"
        else
            print_status "FAIL" "$tool not available"
        fi
    done
else
    # Test tools directly when inside container
    for tool in g++ gcc clang-format cmake meson ninja make git curl wget pkg-config python3 pip3 openssl pre-commit; do
        if command -v "$tool" &> /dev/null; then
            version=$("$tool" --version 2>&1 | head -n1)
            print_status "PASS" "$tool available: $version"
        else
            print_status "FAIL" "$tool not available"
        fi
    done
fi

# ========== 3. Checking Libraries ==========
echo ""
echo "3. Checking Libraries..."
echo "-------------------------"
# Only run Docker tests if we're not inside a container
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
    for lib in libssl-dev zlib1g-dev libbrotli-dev libzstd-dev libcurl4-openssl-dev libgtest-dev; do
        if docker run --rm cpp-httplib-env-test bash -c "dpkg -s $lib >/dev/null 2>&1"; then
            print_status "PASS" "$lib is installed"
        else
            print_status "FAIL" "$lib is not installed"
        fi
    done
else
    # Test libraries directly when inside container
    for lib in libssl-dev zlib1g-dev libbrotli-dev libzstd-dev libcurl4-openssl-dev libgtest-dev; do
        if dpkg -s "$lib" >/dev/null 2>&1; then
            print_status "PASS" "$lib is installed"
        else
            print_status "FAIL" "$lib is not installed"
        fi
    done
fi

# ========== 4. Checking Project Structure ==========
echo ""
echo "4. Checking Project Structure..."
echo "-------------------------------"
# Only run Docker tests if we're not inside a container
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
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
else
    # Test project structure directly when inside container
    for d in test example benchmark cmake docker .github; do
        if [ -d "$d" ]; then
            print_status "PASS" "$d directory exists"
        else
            print_status "WARN" "$d directory does not exist"
        fi
    done
    for f in httplib.h LICENSE README.md CMakeLists.txt meson.build meson_options.txt test/Makefile test/test.cc; do
        if [ -f "$f" ]; then
            print_status "PASS" "$f exists"
        else
            print_status "FAIL" "$f does not exist"
        fi
    done
fi

# ========== 5. Checking Source Files ==========
echo ""
echo "5. Checking Source Files..."
echo "---------------------------"
# Only run Docker tests if we're not inside a container
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
    if docker run --rm -v "$(pwd):/workspace" -w /workspace cpp-httplib-env-test test -r httplib.h; then
        print_status "PASS" "httplib.h is readable"
    else
        print_status "FAIL" "httplib.h is not readable"
    fi
else
    # Test source files directly when inside container
    if [ -r httplib.h ]; then
        print_status "PASS" "httplib.h is readable"
    else
        print_status "FAIL" "httplib.h is not readable"
    fi
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
# Only run Docker tests if we're not inside a container
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
    print_status "INFO" "Attempting to compile test/test.cc in container..."
    if docker run --rm -v "$(pwd):/workspace" -w /workspace/test cpp-httplib-env-test bash -c 'g++ -std=c++11 -I.. test.cc include_httplib.cc -o test_bin -lpthread -lcurl -lssl -lcrypto -lz -lbrotlicommon -lbrotlienc -lbrotlidec -lzstd 2>/dev/null'; then
        print_status "PASS" "test/test.cc compiled successfully (g++)"
    else
        print_status "FAIL" "test/test.cc failed to compile (g++) - missing Google Test library"
    fi
else
    # Test build directly when inside container
    print_status "INFO" "Attempting to compile test/test.cc directly..."
    if cd test && g++ -std=c++11 -I.. test.cc include_httplib.cc -o test_bin -lpthread -lcurl -lssl -lcrypto -lz -lbrotlicommon -lbrotlienc -lbrotlidec -lzstd 2>/dev/null; then
        print_status "PASS" "test/test.cc compiled successfully (g++)"
    else
        print_status "FAIL" "test/test.cc failed to compile (g++) - missing Google Test library"
    fi
fi

# ========== 7. Documentation ==========
echo ""
echo "7. Checking Documentation..."
echo "----------------------------"
# Only run Docker tests if we're not inside a container
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
    for doc in README.md LICENSE; do
        if docker run --rm -v "$(pwd):/workspace" -w /workspace cpp-httplib-env-test test -r "$doc"; then
            print_status "PASS" "$doc is readable"
        else
            print_status "FAIL" "$doc is not readable"
        fi
    done
else
    # Test documentation directly when inside container
    for doc in README.md LICENSE; do
        if [ -r "$doc" ]; then
            print_status "PASS" "$doc is readable"
        else
            print_status "FAIL" "$doc is not readable"
        fi
    done
fi

# ========== 8. Docker Functionality ==========
echo ""
echo "8. Checking Docker Functionality..."
echo "-----------------------------------"
# Only run Docker tests if we're not inside a container
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
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
else
    print_status "INFO" "Skipping Docker functionality tests (running inside container)"
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
echo -e "${BLUE}[INFO]${NC} Docker Environment Score: $score_percentage% ($PASS_COUNT/$total_tests tests passed)"
echo ""
if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${BLUE}[INFO]${NC} All Docker tests passed! Your cpp-httplib Docker environment is ready!"
    echo -e "${BLUE}[INFO]${NC} cpp-httplib is a C++11 single-header HTTP/HTTPS library."
elif [ $FAIL_COUNT -lt 5 ]; then
    echo -e "${BLUE}[INFO]${NC} Most Docker tests passed! Your cpp-httplib Docker environment is mostly ready."
    echo -e "${YELLOW}[WARN]${NC} Some optional features are missing, but core functionality works."
else
    echo -e "${YELLOW}[WARN]${NC} Many Docker tests failed. Please check the output above."
    echo -e "${BLUE}[INFO]${NC} This might indicate that the Docker environment is not properly set up."
fi
echo ""
echo -e "${BLUE}[INFO]${NC} You can now run cpp-httplib in Docker: A C++11 single-header HTTP/HTTPS library."
echo -e "${BLUE}[INFO]${NC} Example: docker run --rm -v \$(pwd):/workspace -w /workspace cpp-httplib-env-test g++ --version"
echo -e "${BLUE}[INFO]${NC} Example: docker run --rm -v \$(pwd):/workspace -w /workspace cpp-httplib-env-test cmake --version"
echo -e "${BLUE}[INFO]${NC} Example: docker run --rm -v \$(pwd):/workspace -w /workspace cpp-httplib-env-test bash -c 'g++ -std=c++11 -I. test/test.cc -o test_bin'"
echo ""
echo -e "${BLUE}[INFO]${NC} For more information, see README.md and https://github.com/yhirose/cpp-httplib"

# Write results to JSON before any additional print_status calls
write_results_to_json

echo -e "${BLUE}[INFO]${NC} To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/yhirose_cpp-httplib cpp-httplib-env-test /bin/bash" 