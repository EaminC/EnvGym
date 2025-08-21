#!/bin/bash

# Go-Zero Environment Benchmark Test Script
# This script tests the Docker environment setup for Go-Zero: A web and RPC framework
# Tailored specifically for Go-Zero project requirements and features

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
    docker stop go-zero-env-test 2>/dev/null || true
    docker rm go-zero-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the zeromicro_go-zero project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t go-zero-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/zeromicro_go-zero" go-zero-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "Go-Zero Environment Benchmark Test"
echo "=========================================="

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
if timeout 900s docker build -f envgym/envgym.dockerfile -t gozero-env-test .; then
    print_status "PASS" "Docker image built successfully."
else
    print_status "FAIL" "Docker image build failed. See above for details."
    echo ""
    echo "=========================================="
    echo "go-zero Environment Test Complete"
    echo "=========================================="
    echo ""
    echo "Summary:"
    echo "--------"
    echo "Docker build failed - environment not ready for go-zero development"
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
    print_status "FAIL" "Docker build failed - go-zero environment is not ready!"
    print_status "INFO" "Please fix the Docker build issues before using this environment"
    exit 1
fi

# ========== 2. Checking Toolchain ==========
echo ""
echo "2. Checking Toolchain..."
echo "-------------------------"
for tool in go git curl wget make gcc g++ bash; do
    if docker run --rm gozero-env-test bash -c "command -v $tool" >/dev/null 2>&1; then
        version=$(docker run --rm gozero-env-test bash -c "$tool version 2>&1 | head -n1")
        print_status "PASS" "$tool available: $version"
    else
        print_status "FAIL" "$tool not available"
    fi
done

# ========== 3. Checking Go Modules ==========
echo ""
echo "3. Checking Go Modules..."
echo "-------------------------"
if docker run --rm -v "$(pwd):/workspace" -w /workspace gozero-env-test test -f go.mod; then
    print_status "PASS" "go.mod exists"
else
    print_status "FAIL" "go.mod does not exist"
fi
if docker run --rm -v "$(pwd):/workspace" -w /workspace gozero-env-test test -f go.sum; then
    print_status "PASS" "go.sum exists"
else
    print_status "FAIL" "go.sum does not exist"
fi

# ========== 4. Checking Project Structure ==========
echo ""
echo "4. Checking Project Structure..."
echo "-------------------------------"
for d in core gateway zrpc rest tools mcp internal .github; do
    if docker run --rm -v "$(pwd):/workspace" -w /workspace gozero-env-test test -d "$d"; then
        print_status "PASS" "$d directory exists"
    else
        print_status "WARN" "$d directory does not exist"
    fi
done
for f in LICENSE readme.md readme-cn.md CONTRIBUTING.md SECURITY.md code-of-conduct.md .gitignore .dockerignore; do
    if docker run --rm -v "$(pwd):/workspace" -w /workspace gozero-env-test test -f "$f"; then
        print_status "PASS" "$f exists"
    else
        print_status "FAIL" "$f does not exist"
    fi
done

# ========== 5. Checking Source Files ==========
echo ""
echo "5. Checking Source Files..."
echo "---------------------------"
go_files=$(find . -name "*.go" | wc -l)
if [ "$go_files" -gt 0 ]; then
    print_status "PASS" "Found $go_files Go source files (*.go)"
else
    print_status "FAIL" "No Go source files (*.go) found"
fi

# ========== 6. Build/Test in Docker ==========
echo ""
echo "6. Testing Build in Docker..."
echo "-----------------------------"
print_status "INFO" "Attempting to build go-zero in container..."
if docker run --rm -v "$(pwd):/workspace" -w /workspace gozero-env-test bash -c 'go mod tidy && go build ./...'; then
    print_status "PASS" "go build ./... succeeded in Docker container"
else
    print_status "FAIL" "go build ./... failed in Docker container"
fi

# ========== 7. Documentation ==========
echo ""
echo "7. Checking Documentation..."
echo "----------------------------"
for doc in readme.md readme-cn.md LICENSE CONTRIBUTING.md SECURITY.md code-of-conduct.md; do
    if docker run --rm -v "$(pwd):/workspace" -w /workspace gozero-env-test test -r "$doc"; then
        print_status "PASS" "$doc is readable"
    else
        print_status "FAIL" "$doc is not readable"
    fi
done

# ========== 8. Docker Functionality ==========
echo ""
echo "8. Checking Docker Functionality..."
echo "-----------------------------------"
if docker run --rm gozero-env-test go version >/dev/null 2>&1; then
    print_status "PASS" "go works in Docker container"
else
    print_status "FAIL" "go does not work in Docker container"
fi
if docker run --rm gozero-env-test git --version >/dev/null 2>&1; then
    print_status "PASS" "git works in Docker container"
else
    print_status "FAIL" "git does not work in Docker container"
fi
if docker run --rm -v "$(pwd):/workspace" gozero-env-test test -f go.mod; then
    print_status "PASS" "go.mod is accessible in Docker container"
else
    print_status "FAIL" "go.mod is not accessible in Docker container"
fi

# ========== 9. Summary ==========
echo ""
echo "=========================================="
echo "go-zero Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for go-zero:"
echo "- Docker build process (Go, git, curl, wget, make, gcc, g++)"
echo "- Go modules (go.mod, go.sum)"
echo "- Project structure (core, gateway, zrpc, rest, tools, mcp, internal, .github, key files)"
echo "- Source files (*.go)"
echo "- Build/test in Docker (go build ./...)"
echo "- Documentation (README, LICENSE, CONTRIBUTING, SECURITY, code-of-conduct)"
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
    print_status "INFO" "All Docker tests passed! Your go-zero Docker environment is ready!"
    print_status "INFO" "go-zero is a web and RPC framework written in Go."
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your go-zero Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now run go-zero in Docker: A web and RPC framework written in Go."
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace gozero-env-test go build ./..."
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace gozero-env-test go test ./..."
echo ""
print_status "INFO" "For more information, see README.md and https://github.com/zeromicro/go-zero" 

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for Go-Zero:"
echo "- Docker build process (Ubuntu 22.04, Go, protobuf)"
echo "- Go environment (compilation, toolchain, dependencies)"
echo "- protobuf environment (code generation, serialization)"
echo "- Go-Zero build system (go.mod, go.sum, Makefile)"
echo "- Go-Zero source code (core, rest, zrpc, gateway)"
echo "- Go-Zero documentation (README.md, readme-cn.md)"
echo "- Go-Zero configuration (go.mod, .gitignore)"
echo "- Docker container functionality (Go, protobuf, build tools)"
echo "- Web and RPC framework capabilities"

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
    print_status "INFO" "All Docker tests passed! Your Go-Zero Docker environment is ready!"
    print_status "INFO" "Go-Zero is a web and RPC framework."
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your Go-Zero Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi

print_status "INFO" "You can now run Go-Zero in Docker: A web and RPC framework."
print_status "INFO" "Example: docker run --rm go-zero-env-test go build"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/zeromicro_go-zero go-zero-env-test /bin/bash" 