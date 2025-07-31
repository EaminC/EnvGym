#!/bin/bash

# Pony Language Environment Benchmark Test
# This script tests the Docker environment for Pony language development

set -u

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

# Function to print status messages
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
        *)
            echo "[$status] $message"
            ;;
    esac
}

# Cleanup function
cleanup() {
    # Clean up Docker image if it exists
    if docker images | grep -q "pony-env-test"; then
        docker rmi pony-env-test >/dev/null 2>&1
    fi
}

# Set trap for cleanup
trap cleanup EXIT

echo "=========================================="
echo "Pony Language Environment Benchmark Test"
echo "=========================================="

# Check if running inside Docker
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo "Running inside Docker container - performing environment tests..."
    DOCKER_MODE=true
else
    echo "Running on host - checking for Docker and envgym.dockerfile"
    DOCKER_MODE=false
    
    if ! command -v docker &> /dev/null; then
        print_status "FAIL" "Docker not available - cannot test Docker environment"
        echo ""
        echo "=========================================="
        echo "Test Results Summary"
        echo "=========================================="
        echo -e "${GREEN}PASS: 0${NC}"
        echo -e "${RED}FAIL: 1${NC}"
        echo -e "${YELLOW}WARN: 0${NC}"
        echo ""
        print_status "INFO" "Environment Score: 0% (Docker not available)"
        exit 0
    elif [ -f "envgym/envgym.dockerfile" ]; then
        echo "Building Docker image..."
        if timeout 600s docker build -f envgym/envgym.dockerfile -t pony-env-test .; then
            echo "Docker build successful - analyzing build process..."
            DOCKER_BUILD_SUCCESS=true
        else
            echo "WARNING: Docker build failed"
            DOCKER_BUILD_FAILED=true
        fi
    else
        print_status "FAIL" "envgym.dockerfile not found - cannot test Docker environment"
        echo ""
        echo "=========================================="
        echo "Test Results Summary"
        echo "=========================================="
        echo -e "${GREEN}PASS: 0${NC}"
        echo -e "${RED}FAIL: 1${NC}"
        echo -e "${YELLOW}WARN: 0${NC}"
        echo ""
        print_status "INFO" "Environment Score: 0% (Dockerfile not found)"
        exit 0
    fi
fi

# If Docker failed, give 0 score
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ]; then
    echo ""
    echo "=========================================="
    echo "Docker Build Failed - Score: 0%"
    echo "=========================================="
    echo ""
    echo "Summary:"
    echo "--------"
    echo "Docker build failed - environment score is 0%"
    echo ""
    echo "Issue: Docker build failed due to shell compatibility issue"
    echo "Fix: Change 'set -euxo pipefail' to 'set -eux' in the Dockerfile"
    echo ""
    echo "=========================================="
    echo "Test Results Summary"
    echo "=========================================="
    echo -e "${GREEN}PASS: 0${NC}"
    echo -e "${RED}FAIL: 1${NC}"
    echo -e "${YELLOW}WARN: 0${NC}"
    echo ""
    print_status "INFO" "Environment Score: 0% (Docker build failed)"
    echo ""
    print_status "FAIL" "Docker build failed - cannot test environment"
    print_status "INFO" "Fix the Dockerfile issue to enable environment testing"
    echo ""
    print_status "INFO" "For more information, see BUILD.md and the Dockerfile at envgym/envgym.dockerfile"
    exit 0
fi

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
print_status "INFO" "Environment Score: $score_percentage% ($PASS_COUNT/$total_tests tests passed)"
echo ""
if [ $score_percentage -ge 80 ]; then
    print_status "INFO" "Excellent environment configuration!"
elif [ $score_percentage -ge 60 ]; then
    print_status "INFO" "Good environment configuration."
elif [ $score_percentage -ge 40 ]; then
    print_status "WARN" "Environment configuration needs improvement."
else
    print_status "FAIL" "Environment configuration has significant issues."
fi
echo ""
print_status "INFO" "For more information, see BUILD.md and the Dockerfile at envgym/envgym.dockerfile" 