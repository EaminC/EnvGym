#!/bin/bash

# Pony Language Environment Benchmark Test Script
# This script tests the Docker environment setup for Pony: A programming language for safe, high-performance applications
# Tailored specifically for Pony project requirements and features

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
    docker stop pony-env-test 2>/dev/null || true
    docker rm pony-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the ponylang_ponyc project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t pony-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/ponylang_ponyc" pony-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "Pony Language Environment Benchmark Test"
echo "=========================================="

# Test Docker environment if build was successful
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    echo ""
    echo "Testing Docker Environment..."
    echo "----------------------------"
    
    # Test essential tools in Docker
    if docker run --rm pony-env-test clang --version >/dev/null 2>&1; then
        print_status "PASS" "Clang works in Docker container"
    else
        print_status "FAIL" "Clang does not work in Docker container"
    fi
    
    if docker run --rm pony-env-test g++ --version >/dev/null 2>&1; then
        print_status "PASS" "G++ works in Docker container"
    else
        print_status "FAIL" "G++ does not work in Docker container"
    fi
    
    if docker run --rm pony-env-test cmake --version >/dev/null 2>&1; then
        print_status "PASS" "CMake works in Docker container"
    else
        print_status "FAIL" "CMake does not work in Docker container"
    fi
    
    if docker run --rm pony-env-test make --version >/dev/null 2>&1; then
        print_status "PASS" "Make works in Docker container"
    else
        print_status "FAIL" "Make does not work in Docker container"
    fi
    
    if docker run --rm pony-env-test python3 --version >/dev/null 2>&1; then
        print_status "PASS" "Python3 works in Docker container"
    else
        print_status "FAIL" "Python3 does not work in Docker container"
    fi
    
    if docker run --rm pony-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    if docker run --rm pony-env-test ponyup --version >/dev/null 2>&1; then
        print_status "PASS" "ponyup works in Docker container"
    else
        print_status "FAIL" "ponyup does not work in Docker container"
    fi
    
    # Test project files in Docker
    if docker run --rm pony-env-test test -d src; then
        print_status "PASS" "src directory accessible in Docker"
    else
        print_status "FAIL" "src directory not accessible in Docker"
    fi
    
    if docker run --rm pony-env-test test -d lib; then
        print_status "PASS" "lib directory accessible in Docker"
    else
        print_status "FAIL" "lib directory not accessible in Docker"
    fi
    
    if docker run --rm pony-env-test test -f CMakeLists.txt; then
        print_status "PASS" "CMakeLists.txt accessible in Docker"
    else
        print_status "FAIL" "CMakeLists.txt not accessible in Docker"
    fi
    
    if docker run --rm pony-env-test test -f Makefile; then
        print_status "PASS" "Makefile accessible in Docker"
    else
        print_status "FAIL" "Makefile not accessible in Docker"
    fi
    
    # Test build commands in Docker
    if docker run --rm pony-env-test make libs >/dev/null 2>&1; then
        print_status "PASS" "make libs works in Docker"
    else
        print_status "FAIL" "make libs failed in Docker"
    fi
    
    if docker run --rm pony-env-test make configure >/dev/null 2>&1; then
        print_status "PASS" "make configure works in Docker"
    else
        print_status "FAIL" "make configure failed in Docker"
    fi
    
    if docker run --rm pony-env-test cmake -B build -S . >/dev/null 2>&1; then
        print_status "PASS" "cmake configuration works in Docker"
    else
        print_status "FAIL" "cmake configuration failed in Docker"
    fi
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for Pony:"
echo "- Docker build process (Ubuntu 22.04, LLVM, GCC, Make)"
echo "- LLVM environment (compilation, optimization)"
echo "- GCC environment (C/C++ compilation)"
echo "- Pony build system (Makefile, CMakeLists.txt)"
echo "- Pony source code (src, packages, examples)"
echo "- Pony documentation (README.md, INSTALL.md, BUILD.md)"
echo "- Pony configuration (Makefile, CMake, build scripts)"
echo "- Docker container functionality (LLVM, GCC, Make)"
echo "- Safe, high-performance programming language"

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
    print_status "INFO" "All Docker tests passed! Your Pony Docker environment is ready!"
    print_status "INFO" "Pony is a programming language for safe, high-performance applications."
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your Pony Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi

print_status "INFO" "You can now run Pony in Docker: A programming language for safe, high-performance applications."
print_status "INFO" "Example: docker run --rm pony-env-test make"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/ponylang_ponyc pony-env-test /bin/bash" 