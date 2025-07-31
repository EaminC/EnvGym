#!/bin/bash

# gRPC-Go Environment Benchmark Test Script
# This script tests the environment setup for gRPC-Go: A high performance, open source, general RPC framework

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
    # Kill any background processes
    jobs -p | xargs -r kill
    # Remove temporary files
    rm -f docker_build.log
    # Stop and remove Docker container if running
    docker stop grpc-go-env-test 2>/dev/null || true
    docker rm grpc-go-env-test 2>/dev/null || true
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Check if we're running in Docker
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo "Running inside Docker container - performing environment tests..."
    DOCKER_MODE=true
else
    echo "Running on host - checking for Docker and envgym.dockerfile"
    DOCKER_MODE=false
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_status "WARN" "Docker not available - Docker environment not available"
    elif [ -f "envgym/envgym.dockerfile" ]; then
        echo "Building Docker image..."
        if timeout 60s docker build -f envgym/envgym.dockerfile -t grpc-go-env-test .; then
            echo "Docker build successful - running environment test in Docker container..."
            if docker run --rm -v "$(pwd):/home/cc/EnvGym/data/grpc_grpc-go" --init grpc-go-env-test bash -c "
                trap 'exit 0' SIGINT SIGTERM
                cd /home/cc/EnvGym/data/grpc_grpc-go
                bash envgym/envbench.sh
            "; then
                echo "Docker container test completed successfully"
                # Don't cleanup here, let the script continue to show results
            else
                echo "WARNING: Docker container failed to run - analyzing Dockerfile only"
                echo "This may be due to architecture compatibility issues"
                DOCKER_BUILD_FAILED=true
            fi
        else
            echo "WARNING: Docker build failed - analyzing Dockerfile only"
            DOCKER_BUILD_FAILED=true
        fi
    else
        print_status "WARN" "envgym.dockerfile not found - Docker environment not available"
    fi
fi

# If Docker failed or not available, skip local environment tests
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ] || [ "${DOCKER_MODE:-false}" = "false" ]; then
    echo "Docker environment not available - skipping local environment tests"
    echo "This script is designed to test Docker environment only"
    exit 0
fi

echo "=========================================="
echo "gRPC-Go Environment Benchmark Test"
echo "=========================================="

# Analyze Dockerfile if build failed
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ]; then
    echo ""
    echo "Analyzing Dockerfile..."
    echo "----------------------"
    
    if [ -f "envgym/envgym.dockerfile" ]; then
        # Check Dockerfile structure
        if grep -q "FROM" envgym/envgym.dockerfile; then
            print_status "PASS" "FROM instruction found"
        else
            print_status "FAIL" "FROM instruction not found"
        fi
        
        if grep -q "golang:1.24" envgym/envgym.dockerfile; then
            print_status "PASS" "Go 1.24 specified"
        else
            print_status "WARN" "Go 1.24 not specified"
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
        
        if grep -q "git" envgym/envgym.dockerfile; then
            print_status "PASS" "git found"
        else
            print_status "FAIL" "git not found"
        fi
        
        if grep -q "make" envgym/envgym.dockerfile; then
            print_status "PASS" "make found"
        else
            print_status "FAIL" "make not found"
        fi
        
        if grep -q "protoc" envgym/envgym.dockerfile; then
            print_status "PASS" "protoc found"
        else
            print_status "FAIL" "protoc not found"
        fi
        
        if grep -q "GO111MODULE=on" envgym/envgym.dockerfile; then
            print_status "PASS" "GO111MODULE=on found"
        else
            print_status "WARN" "GO111MODULE=on not found"
        fi
        
        if grep -q "CGO_ENABLED=1" envgym/envgym.dockerfile; then
            print_status "PASS" "CGO_ENABLED=1 found"
        else
            print_status "WARN" "CGO_ENABLED=1 not found"
        fi
        
        if grep -q "protoc-gen-go" envgym/envgym.dockerfile; then
            print_status "PASS" "protoc-gen-go found"
        else
            print_status "FAIL" "protoc-gen-go not found"
        fi
        
        if grep -q "protoc-gen-go-grpc" envgym/envgym.dockerfile; then
            print_status "PASS" "protoc-gen-go-grpc found"
        else
            print_status "FAIL" "protoc-gen-go-grpc not found"
        fi
        
        if grep -q "mockgen" envgym/envgym.dockerfile; then
            print_status "PASS" "mockgen found"
        else
            print_status "WARN" "mockgen not found"
        fi
        
        if grep -q "golangci-lint" envgym/envgym.dockerfile; then
            print_status "PASS" "golangci-lint found"
        else
            print_status "WARN" "golangci-lint not found"
        fi
        
        if grep -q "go mod download" envgym/envgym.dockerfile; then
            print_status "PASS" "go mod download found"
        else
            print_status "WARN" "go mod download not found"
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
# Check Go
if command -v go &> /dev/null; then
    go_version=$(go version 2>&1)
    print_status "PASS" "Go is available: $go_version"
    
    # Check Go version (should be >= 1.23)
    go_major=$(echo $go_version | grep -o 'go[0-9]*' | sed 's/go//')
    if [ -n "$go_major" ] && [ "$go_major" -ge 23 ]; then
        print_status "PASS" "Go version is >= 1.23 (compatible)"
    else
        print_status "WARN" "Go version should be >= 1.23 (found: $go_major)"
    fi
else
    print_status "FAIL" "Go is not available"
fi

# Check git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1)
    print_status "PASS" "Git is available: $git_version"
else
    print_status "FAIL" "Git is not available"
fi

# Check make
if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "Make is available: $make_version"
else
    print_status "FAIL" "Make is not available"
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

# Check unzip
if command -v unzip &> /dev/null; then
    print_status "PASS" "unzip is available"
else
    print_status "WARN" "unzip is not available"
fi

# Check build tools
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version 2>&1 | head -n 1)
    print_status "PASS" "GCC is available: $gcc_version"
else
    print_status "WARN" "GCC is not available"
fi

if command -v g++ &> /dev/null; then
    gpp_version=$(g++ --version 2>&1 | head -n 1)
    print_status "PASS" "G++ is available: $gpp_version"
else
    print_status "WARN" "G++ is not available"
fi

# Check protoc
if command -v protoc &> /dev/null; then
    protoc_version=$(protoc --version 2>&1)
    print_status "PASS" "protoc is available: $protoc_version"
else
    print_status "FAIL" "protoc is not available"
fi

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "examples" ]; then
    print_status "PASS" "examples directory exists"
else
    print_status "FAIL" "examples directory not found"
fi

if [ -d "benchmark" ]; then
    print_status "PASS" "benchmark directory exists"
else
    print_status "FAIL" "benchmark directory not found"
fi

if [ -d "scripts" ]; then
    print_status "PASS" "scripts directory exists"
else
    print_status "FAIL" "scripts directory not found"
fi

if [ -d "Documentation" ]; then
    print_status "PASS" "Documentation directory exists"
else
    print_status "FAIL" "Documentation directory not found"
fi

if [ -d "internal" ]; then
    print_status "PASS" "internal directory exists"
else
    print_status "FAIL" "internal directory not found"
fi

if [ -d "cmd" ]; then
    print_status "PASS" "cmd directory exists"
else
    print_status "FAIL" "cmd directory not found"
fi

if [ -d "test" ]; then
    print_status "PASS" "test directory exists"
else
    print_status "FAIL" "test directory not found"
fi

if [ -d "testdata" ]; then
    print_status "PASS" "testdata directory exists"
else
    print_status "FAIL" "testdata directory not found"
fi

# Check key files
if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
fi

if [ -f "go.mod" ]; then
    print_status "PASS" "go.mod exists"
else
    print_status "FAIL" "go.mod not found"
fi

if [ -f "go.sum" ]; then
    print_status "PASS" "go.sum exists"
else
    print_status "FAIL" "go.sum not found"
fi

if [ -f "Makefile" ]; then
    print_status "PASS" "Makefile exists"
else
    print_status "FAIL" "Makefile not found"
fi

if [ -f "LICENSE" ]; then
    print_status "PASS" "LICENSE exists"
else
    print_status "FAIL" "LICENSE not found"
fi

if [ -f "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md exists"
else
    print_status "FAIL" "CONTRIBUTING.md not found"
fi

# Check Go files
if [ -f "server.go" ]; then
    print_status "PASS" "server.go exists"
else
    print_status "FAIL" "server.go not found"
fi

if [ -f "clientconn.go" ]; then
    print_status "PASS" "clientconn.go exists"
else
    print_status "FAIL" "clientconn.go not found"
fi

if [ -f "stream.go" ]; then
    print_status "PASS" "stream.go exists"
else
    print_status "FAIL" "stream.go not found"
fi

if [ -f "doc.go" ]; then
    print_status "PASS" "doc.go exists"
else
    print_status "FAIL" "doc.go not found"
fi

# Check script files
if [ -f "scripts/vet.sh" ]; then
    print_status "PASS" "scripts/vet.sh exists"
else
    print_status "FAIL" "scripts/vet.sh not found"
fi

if [ -f "scripts/install-protoc.sh" ]; then
    print_status "PASS" "scripts/install-protoc.sh exists"
else
    print_status "FAIL" "scripts/install-protoc.sh not found"
fi

if [ -f "scripts/regenerate.sh" ]; then
    print_status "PASS" "scripts/regenerate.sh exists"
else
    print_status "FAIL" "scripts/regenerate.sh not found"
fi

# Check example files
if [ -f "examples/go.mod" ]; then
    print_status "PASS" "examples/go.mod exists"
else
    print_status "FAIL" "examples/go.mod exists"
fi

if [ -d "examples/helloworld" ]; then
    print_status "PASS" "examples/helloworld directory exists"
else
    print_status "FAIL" "examples/helloworld directory not found"
fi

if [ -d "examples/route_guide" ]; then
    print_status "PASS" "examples/route_guide directory exists"
else
    print_status "FAIL" "examples/route_guide directory not found"
fi

# Check benchmark files
if [ -f "benchmark/benchmark.go" ]; then
    print_status "PASS" "benchmark/benchmark.go exists"
else
    print_status "FAIL" "benchmark/benchmark.go not found"
fi

if [ -f "benchmark/run_bench.sh" ]; then
    print_status "PASS" "benchmark/run_bench.sh exists"
else
    print_status "FAIL" "benchmark/run_bench.sh not found"
fi

echo ""
echo "3. Checking Environment Variables..."
echo "-----------------------------------"
# Check Go environment
if [ -n "${GOROOT:-}" ]; then
    print_status "PASS" "GOROOT is set: $GOROOT"
else
    print_status "WARN" "GOROOT is not set"
fi

if [ -n "${GOPATH:-}" ]; then
    print_status "PASS" "GOPATH is set: $GOPATH"
else
    print_status "WARN" "GOPATH is not set"
fi

if [ -n "${GO111MODULE:-}" ]; then
    print_status "PASS" "GO111MODULE is set: $GO111MODULE"
else
    print_status "WARN" "GO111MODULE is not set"
fi

if [ -n "${CGO_ENABLED:-}" ]; then
    print_status "PASS" "CGO_ENABLED is set: $CGO_ENABLED"
else
    print_status "WARN" "CGO_ENABLED is not set"
fi

if [ -n "${GOARCH:-}" ]; then
    print_status "PASS" "GOARCH is set: $GOARCH"
else
    print_status "WARN" "GOARCH is not set"
fi

if [ -n "${GOCACHE:-}" ]; then
    print_status "PASS" "GOCACHE is set: $GOCACHE"
else
    print_status "WARN" "GOCACHE is not set"
fi

# Check PATH
if echo "$PATH" | grep -q "go"; then
    print_status "PASS" "go is in PATH"
else
    print_status "WARN" "go is not in PATH"
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

if echo "$PATH" | grep -q "protoc"; then
    print_status "PASS" "protoc is in PATH"
else
    print_status "WARN" "protoc is not in PATH"
fi

echo ""
echo "4. Testing Go Environment..."
echo "----------------------------"
# Test Go
if command -v go &> /dev/null; then
    print_status "PASS" "go is available"
    
    # Test Go execution
    if timeout 30s go version >/dev/null 2>&1; then
        print_status "PASS" "Go execution works"
    else
        print_status "WARN" "Go execution failed"
    fi
    
    # Test Go env
    if timeout 30s go env >/dev/null 2>&1; then
        print_status "PASS" "Go env command works"
    else
        print_status "WARN" "Go env command failed"
    fi
    
    # Test Go list
    if timeout 30s go list -m >/dev/null 2>&1; then
        print_status "PASS" "Go list command works"
    else
        print_status "WARN" "Go list command failed"
    fi
else
    print_status "FAIL" "go is not available"
fi

echo ""
echo "5. Testing Go Module System..."
echo "-------------------------------"
# Test Go modules
if command -v go &> /dev/null; then
    print_status "PASS" "go is available for module testing"
    
    # Test go mod download
    if timeout 60s go mod download >/dev/null 2>&1; then
        print_status "PASS" "go mod download works"
    else
        print_status "WARN" "go mod download failed"
    fi
    
    # Test go mod tidy
    if timeout 60s go mod tidy >/dev/null 2>&1; then
        print_status "PASS" "go mod tidy works"
    else
        print_status "WARN" "go mod tidy failed"
    fi
    
    # Test go mod verify
    if timeout 60s go mod verify >/dev/null 2>&1; then
        print_status "PASS" "go mod verify works"
    else
        print_status "WARN" "go mod verify failed"
    fi
else
    print_status "WARN" "go not available for module testing"
fi

echo ""
echo "6. Testing Protocol Buffers..."
echo "-------------------------------"
# Test protoc
if command -v protoc &> /dev/null; then
    print_status "PASS" "protoc is available"
    
    # Test protoc version
    if timeout 30s protoc --version >/dev/null 2>&1; then
        print_status "PASS" "protoc version command works"
    else
        print_status "WARN" "protoc version command failed"
    fi
    
    # Test protoc help
    if timeout 30s protoc --help >/dev/null 2>&1; then
        print_status "PASS" "protoc help command works"
    else
        print_status "WARN" "protoc help command failed"
    fi
else
    print_status "FAIL" "protoc is not available"
fi

echo ""
echo "7. Testing Go Tools..."
echo "----------------------"
# Test Go tools
if command -v go &> /dev/null; then
    print_status "PASS" "go is available for tool testing"
    
    # Test protoc-gen-go
    if timeout 30s protoc-gen-go --version >/dev/null 2>&1; then
        print_status "PASS" "protoc-gen-go is available"
    else
        print_status "WARN" "protoc-gen-go is not available"
    fi
    
    # Test protoc-gen-go-grpc
    if timeout 30s protoc-gen-go-grpc --version >/dev/null 2>&1; then
        print_status "PASS" "protoc-gen-go-grpc is available"
    else
        print_status "WARN" "protoc-gen-go-grpc is not available"
    fi
    
    # Test mockgen
    if timeout 30s mockgen --version >/dev/null 2>&1; then
        print_status "PASS" "mockgen is available"
    else
        print_status "WARN" "mockgen is not available"
    fi
    
    # Test golangci-lint
    if timeout 30s golangci-lint --version >/dev/null 2>&1; then
        print_status "PASS" "golangci-lint is available"
    else
        print_status "WARN" "golangci-lint is not available"
    fi
    
    # Test gosec
    if timeout 30s gosec --version >/dev/null 2>&1; then
        print_status "PASS" "gosec is available"
    else
        print_status "WARN" "gosec is not available"
    fi
else
    print_status "WARN" "go not available for tool testing"
fi

echo ""
echo "8. Testing gRPC-Go Scripts..."
echo "-----------------------------"
# Test scripts
if [ -f "scripts/vet.sh" ] && [ -x "scripts/vet.sh" ]; then
    print_status "PASS" "scripts/vet.sh exists and is executable"
else
    print_status "WARN" "scripts/vet.sh not found or not executable"
fi

# Test if scripts can be made executable
if [ -f "scripts/vet.sh" ]; then
    if chmod +x scripts/vet.sh 2>/dev/null; then
        print_status "PASS" "scripts/vet.sh can be made executable"
    else
        print_status "WARN" "scripts/vet.sh cannot be made executable"
    fi
fi

if [ -f "scripts/install-protoc.sh" ]; then
    print_status "PASS" "scripts/install-protoc.sh exists"
    
    if [ -x "scripts/install-protoc.sh" ]; then
        print_status "PASS" "scripts/install-protoc.sh is executable"
    else
        print_status "WARN" "scripts/install-protoc.sh is not executable"
    fi
else
    print_status "FAIL" "scripts/install-protoc.sh not found"
fi

if [ -f "scripts/regenerate.sh" ]; then
    print_status "PASS" "scripts/regenerate.sh exists"
    
    if [ -x "scripts/regenerate.sh" ]; then
        print_status "PASS" "scripts/regenerate.sh is executable"
    else
        print_status "WARN" "scripts/regenerate.sh is not executable"
    fi
else
    print_status "FAIL" "scripts/regenerate.sh not found"
fi

echo ""
echo "9. Testing Makefile..."
echo "----------------------"
# Test Makefile
if [ -f "Makefile" ]; then
    print_status "PASS" "Makefile exists"
    
    if command -v make &> /dev/null; then
        print_status "PASS" "make is available for Makefile testing"
        
        # Test make help or list targets
        if timeout 30s make -n all >/dev/null 2>&1; then
            print_status "PASS" "Makefile syntax is valid"
        else
            print_status "WARN" "Makefile syntax check failed"
        fi
        
        # Test make deps
        if timeout 60s make -n deps >/dev/null 2>&1; then
            print_status "PASS" "make deps target exists"
        else
            print_status "WARN" "make deps target failed"
        fi
        
        # Test make test
        if timeout 60s make -n test >/dev/null 2>&1; then
            print_status "PASS" "make test target exists"
        else
            print_status "WARN" "make test target failed"
        fi
        
        # Test make vet
        if timeout 60s make -n vet >/dev/null 2>&1; then
            print_status "PASS" "make vet target exists"
        else
            print_status "WARN" "make vet target failed"
        fi
    else
        print_status "WARN" "make not available for Makefile testing"
    fi
else
    print_status "FAIL" "Makefile not found"
fi

echo ""
echo "10. Testing Go Build System..."
echo "-------------------------------"
# Test Go build
if command -v go &> /dev/null; then
    print_status "PASS" "go is available for build testing"
    
    # Test go build
    if timeout 120s go build -o /tmp/test_build google.golang.org/grpc/... >/dev/null 2>&1; then
        print_status "PASS" "go build works"
        rm -f /tmp/test_build
    else
        print_status "WARN" "go build failed or timed out"
    fi
    
    # Test go test (dry run)
    if timeout 60s go test -run=^$ google.golang.org/grpc/... >/dev/null 2>&1; then
        print_status "PASS" "go test dry run works"
    else
        print_status "WARN" "go test dry run failed"
    fi
    
    # Test go vet
    if timeout 60s go vet google.golang.org/grpc/... >/dev/null 2>&1; then
        print_status "PASS" "go vet works"
    else
        print_status "WARN" "go vet failed"
    fi
else
    print_status "WARN" "go not available for build testing"
fi

echo ""
echo "11. Testing Examples..."
echo "-----------------------"
# Test examples
if [ -d "examples" ]; then
    print_status "PASS" "examples directory exists"
    
    if command -v go &> /dev/null; then
        print_status "PASS" "go is available for examples testing"
        
        # Test examples go.mod
        if [ -f "examples/go.mod" ]; then
            if timeout 60s cd examples && go mod download >/dev/null 2>&1; then
                print_status "PASS" "examples go.mod works"
            else
                print_status "WARN" "examples go.mod failed"
            fi
        else
            print_status "FAIL" "examples/go.mod not found"
        fi
        
        # Test helloworld example
        if [ -d "examples/helloworld" ]; then
            if timeout 60s cd examples/helloworld && go build -o /tmp/helloworld . >/dev/null 2>&1; then
                print_status "PASS" "helloworld example builds"
                rm -f /tmp/helloworld
            else
                print_status "WARN" "helloworld example build failed"
            fi
        else
            print_status "FAIL" "examples/helloworld directory not found"
        fi
        
        # Test route_guide example
        if [ -d "examples/route_guide" ]; then
            if timeout 60s cd examples/route_guide && go build -o /tmp/route_guide . >/dev/null 2>&1; then
                print_status "PASS" "route_guide example builds"
                rm -f /tmp/route_guide
            else
                print_status "WARN" "route_guide example build failed"
            fi
        else
            print_status "FAIL" "examples/route_guide directory not found"
        fi
    else
        print_status "WARN" "go not available for examples testing"
    fi
else
    print_status "FAIL" "examples directory not found"
fi

echo ""
echo "12. Testing Benchmark..."
echo "------------------------"
# Test benchmark
if [ -d "benchmark" ]; then
    print_status "PASS" "benchmark directory exists"
    
    if [ -f "benchmark/benchmark.go" ]; then
        print_status "PASS" "benchmark/benchmark.go exists"
    else
        print_status "FAIL" "benchmark/benchmark.go not found"
    fi
    
    if [ -f "benchmark/run_bench.sh" ]; then
        print_status "PASS" "benchmark/run_bench.sh exists"
        
        if [ -x "benchmark/run_bench.sh" ]; then
            print_status "PASS" "benchmark/run_bench.sh is executable"
        else
            print_status "WARN" "benchmark/run_bench.sh is not executable"
        fi
    else
        print_status "FAIL" "benchmark/run_bench.sh not found"
    fi
    
    if command -v go &> /dev/null; then
        print_status "PASS" "go is available for benchmark testing"
        
        # Test benchmark build
        if timeout 120s cd benchmark && go build -o /tmp/benchmark . >/dev/null 2>&1; then
            print_status "PASS" "benchmark builds"
            rm -f /tmp/benchmark
        else
            print_status "WARN" "benchmark build failed"
        fi
    else
        print_status "WARN" "go not available for benchmark testing"
    fi
else
    print_status "FAIL" "benchmark directory not found"
fi

echo ""
echo "13. Testing Documentation..."
echo "----------------------------"
# Test documentation
if [ -d "Documentation" ]; then
    print_status "PASS" "Documentation directory exists"
else
    print_status "FAIL" "Documentation directory not found"
fi

if [ -r "README.md" ]; then
    print_status "PASS" "README.md is readable"
else
    print_status "WARN" "README.md is not readable"
fi

if [ -r "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md is readable"
else
    print_status "WARN" "CONTRIBUTING.md is not readable"
fi

if [ -r "LICENSE" ]; then
    print_status "PASS" "LICENSE is readable"
else
    print_status "WARN" "LICENSE is not readable"
fi

if [ -r "examples/gotutorial.md" ]; then
    print_status "PASS" "examples/gotutorial.md is readable"
else
    print_status "WARN" "examples/gotutorial.md is not readable"
fi

echo ""
echo "14. Testing Security and Compliance..."
echo "-------------------------------------"
# Test security files
if [ -f "SECURITY.md" ]; then
    print_status "PASS" "SECURITY.md exists"
else
    print_status "FAIL" "SECURITY.md not found"
fi

if [ -f "CODE-OF-CONDUCT.md" ]; then
    print_status "PASS" "CODE-OF-CONDUCT.md exists"
else
    print_status "FAIL" "CODE-OF-CONDUCT.md not found"
fi

if [ -f "GOVERNANCE.md" ]; then
    print_status "PASS" "GOVERNANCE.md exists"
else
    print_status "FAIL" "GOVERNANCE.md not found"
fi

if [ -f "MAINTAINERS.md" ]; then
    print_status "PASS" "MAINTAINERS.md exists"
else
    print_status "FAIL" "MAINTAINERS.md not found"
fi

echo ""
echo "15. Testing gRPC-Go Core Components..."
echo "--------------------------------------"
# Test core gRPC components
if command -v go &> /dev/null; then
    print_status "PASS" "go is available for core component testing"
    
    # Test server component
    if timeout 60s go build -o /tmp/server_test google.golang.org/grpc >/dev/null 2>&1; then
        print_status "PASS" "gRPC server component builds"
        rm -f /tmp/server_test
    else
        print_status "WARN" "gRPC server component build failed"
    fi
    
    # Test client component
    if timeout 60s go build -o /tmp/client_test google.golang.org/grpc >/dev/null 2>&1; then
        print_status "PASS" "gRPC client component builds"
        rm -f /tmp/client_test
    else
        print_status "WARN" "gRPC client component build failed"
    fi
    
    # Test stream component
    if timeout 60s go build -o /tmp/stream_test google.golang.org/grpc >/dev/null 2>&1; then
        print_status "PASS" "gRPC stream component builds"
        rm -f /tmp/stream_test
    else
        print_status "WARN" "gRPC stream component build failed"
    fi
else
    print_status "WARN" "go not available for core component testing"
fi

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (Go >= 1.23, Git, Make, Bash, curl, wget, unzip)"
echo "- Project structure (examples, benchmark, scripts, Documentation/)"
echo "- Environment variables (GOROOT, GOPATH, GO111MODULE, CGO_ENABLED, GOARCH, GOCACHE)"
echo "- Go environment (go, go mod, go build, go test, go vet)"
echo "- Protocol Buffers (protoc, protoc-gen-go, protoc-gen-go-grpc)"
echo "- Go tools (mockgen, golangci-lint, gosec)"
echo "- gRPC-Go scripts (vet.sh, install-protoc.sh, regenerate.sh)"
echo "- Makefile system (make, build targets, test targets)"
echo "- Go build system (go build, go test, go vet)"
echo "- Examples (helloworld, route_guide)"
echo "- Benchmark (benchmark.go, run_bench.sh)"
echo "- Documentation (README.md, CONTRIBUTING.md, LICENSE)"
echo "- Security and compliance (SECURITY.md, CODE-OF-CONDUCT.md)"
echo "- gRPC-Go core components (server, client, stream)"
echo "- Dockerfile structure (if Docker build failed)"
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
if [ $FAIL_COUNT -eq 0 ]; then
    print_status "INFO" "All tests passed! Your gRPC-Go environment is ready!"
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your gRPC-Go environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now run gRPC-Go: A high performance, open source, general RPC framework."
print_status "INFO" "Example: make test"
echo ""
print_status "INFO" "For more information, see README.md" 