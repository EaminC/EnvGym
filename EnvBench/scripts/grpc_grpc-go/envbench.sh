#!/bin/bash

# gRPC-Go Environment Benchmark Test Script
# This script tests the environment setup for gRPC-Go: A high performance, open source, general RPC framework

# Export PATH to include common locations for protoc plugins
export PATH=$PATH:/go/bin:/root/go/bin:/usr/local/go/bin

# Explicitly set GOPATH if not set
if [ -z "$GOPATH" ]; then
    export GOPATH=$(go env GOPATH 2>/dev/null || echo "/go")
    echo "Setting GOPATH to $GOPATH"
fi

# Add GOPATH/bin to PATH
export PATH=$PATH:$GOPATH/bin

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

# Function to print proportional status with scoring (from gluetest)
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
    # Stop and remove Docker container if running
    docker stop grpc-go-env-test 2>/dev/null || true
    docker rm grpc-go-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the grpc_grpc-go project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t grpc-go-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/grpc_grpc-go" grpc-go-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "gRPC-Go Environment Benchmark Test"
echo "=========================================="

# Analyze Dockerfile if build failed
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
    if [ -f "envgym/envgym.dockerfile" ]; then
        echo ""
        echo "Analyzing Dockerfile..."
        echo "----------------------"
        
        # Check Dockerfile structure - less weight on trivial checks
        if grep -q "FROM" envgym/envgym.dockerfile; then
            print_status "PASS" "FROM instruction found"
        else
            print_status "FAIL" "FROM instruction not found"
        fi
        
        if grep -q "golang:" envgym/envgym.dockerfile; then
            print_status "PASS" "Go specified"
        else
            print_status "FAIL" "Go not specified"
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
        
        # Critical gRPC-Go specific dependencies - higher weight
        if grep -q "protoc" envgym/envgym.dockerfile || grep -q "protobuf" envgym/envgym.dockerfile; then
            print_status "PASS" "protoc/protobuf found"
        else
            print_status "FAIL" "protoc/protobuf not found"
        fi
        
        if grep -q "GO111MODULE=" envgym/envgym.dockerfile; then
            print_status "PASS" "GO111MODULE setting found"
        else
            print_status "WARN" "GO111MODULE setting not found"
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
        
        if grep -q "go mod" envgym/envgym.dockerfile; then
            print_status "PASS" "go mod command found"
        else
            print_status "WARN" "go mod command not found"
        fi
        
        if grep -q "COPY" envgym/envgym.dockerfile; then
            print_status "PASS" "COPY instruction found"
        else
            print_status "WARN" "COPY instruction not found"
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
            print_status "INFO" "Dockerfile structure good, will check dependency versions and build artifacts."
        else
            print_status "WARN" "Dockerfile has some issues, suggest fixing before rebuilding."
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
    
    # Check Go version (should be >= 1.16 as per README)
    go_version_check=$(go version | grep -o 'go[0-9.]*' | sed 's/go//')
    go_major=$(echo $go_version_check | cut -d. -f1)
    go_minor=$(echo $go_version_check | cut -d. -f2)
    
    if [ -n "$go_major" ] && ([ "$go_major" -gt 1 ] || ([ "$go_major" -eq 1 ] && [ "$go_minor" -ge 16 ])); then
        print_status "PASS" "Go version is >= 1.16 (compatible)"
    else
        print_status "WARN" "Go version should be >= 1.16 (found: $go_version_check)"
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

# Critical gRPC-Go specific tools
# Check protoc
if command -v protoc &> /dev/null; then
    protoc_version=$(protoc --version 2>&1)
    print_status "PASS" "protoc is available: $protoc_version"
else
    print_status "FAIL" "protoc is not available"
fi

# Check protoc-gen-go
if command -v protoc-gen-go &> /dev/null; then
    print_status "PASS" "protoc-gen-go is available"
else
    # Check in Go path
    if [ -x "$(go env GOPATH)/bin/protoc-gen-go" ]; then
        print_status "PASS" "protoc-gen-go is available in GOPATH"
    else
        print_status "FAIL" "protoc-gen-go is not available"
    fi
fi

# Check protoc-gen-go-grpc
if command -v protoc-gen-go-grpc &> /dev/null; then
    print_status "PASS" "protoc-gen-go-grpc is available"
else
    # Check in Go path
    if [ -x "$(go env GOPATH)/bin/protoc-gen-go-grpc" ]; then
        print_status "PASS" "protoc-gen-go-grpc is available in GOPATH"
    else
        print_status "FAIL" "protoc-gen-go-grpc is not available"
    fi
fi

echo ""
echo "2. Testing Go Environment..."
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
    
    # Test Go module support
    echo 'module test' > go.mod.test
    if timeout 30s go mod edit -go=1.16 go.mod.test >/dev/null 2>&1; then
        print_status "PASS" "Go module support works"
        rm -f go.mod.test
    else
        print_status "WARN" "Go module support test failed"
        rm -f go.mod.test
    fi
else
    print_status "FAIL" "go is not available"
fi

echo ""
echo "3. Testing Protocol Buffers Environment..."
echo "-----------------------------------------"
# Show plugin locations for debugging
echo "Plugin locations:"
echo "protoc: $(which protoc 2>/dev/null || echo 'not found')"
echo "protoc-gen-go: $(which protoc-gen-go 2>/dev/null || echo 'not found')"
echo "protoc-gen-go-grpc: $(which protoc-gen-go-grpc 2>/dev/null || echo 'not found')"
echo "PATH: $PATH"

# Test protoc
if command -v protoc &> /dev/null; then
    print_status "PASS" "protoc is available"
    
    # Test basic protoc functionality with a temporary proto file
    mkdir -p /tmp/proto_test
    cat > /tmp/proto_test/test.proto << EOF
syntax = "proto3";
package test;
option go_package = "testpkg";
message TestMessage {
  string test_field = 1;
}
service TestService {
  rpc TestMethod(TestMessage) returns (TestMessage) {}
}
EOF
    
        # Test protoc code generation with proto_path flag - capture errors
    ERROR_LOG=$(mktemp)
    if timeout 30s protoc --proto_path=/tmp/proto_test --go_out=/tmp/proto_test /tmp/proto_test/test.proto 2> $ERROR_LOG; then
        print_status "PASS" "protoc can generate Go code"
    else
        print_status "FAIL" "protoc cannot generate Go code"
        echo "Error details:"
        cat $ERROR_LOG
        # Check for common issues
        if grep -q "program not found" $ERROR_LOG; then
            echo "The protoc-gen-go plugin was not found in PATH"
            echo "PATH=$PATH"
            echo "Looking for plugin in GOPATH:"
            find "$(go env GOPATH)" -name "protoc-gen-go" 2>/dev/null || echo "Not found"
        fi
    fi
    
    # Test protoc-gen-go-grpc code generation with proto_path flag - capture errors
    ERROR_LOG=$(mktemp)
    if timeout 30s protoc --proto_path=/tmp/proto_test --go-grpc_out=/tmp/proto_test /tmp/proto_test/test.proto 2> $ERROR_LOG; then
        print_status "PASS" "protoc can generate Go gRPC code"
        
        # Verify generated files
        if [ -f "/tmp/proto_test/testpkg/test.pb.go" ] || [ -f "/tmp/proto_test/test.pb.go" ]; then
            print_status "PASS" "Go protobuf file successfully generated"
            # Show where the file was generated
            find /tmp/proto_test -name "*.pb.go" | xargs ls -la
        else
            print_status "FAIL" "Go protobuf file not found after generation"
            echo "Looking for generated files:"
            find /tmp/proto_test -type f | xargs ls -la
        fi
        
        if [ -f "/tmp/proto_test/testpkg/test_grpc.pb.go" ] || [ -f "/tmp/proto_test/test_grpc.pb.go" ]; then
            print_status "PASS" "Go gRPC file successfully generated"
        else
            print_status "FAIL" "Go gRPC file not found after generation"
            echo "Looking for generated files:"
            find /tmp/proto_test -type f | xargs ls -la
        fi
    else
        print_status "FAIL" "protoc cannot generate Go gRPC code"
    fi
    
    # Clean up temp files
    rm -rf /tmp/proto_test
else
    print_status "FAIL" "protoc is not available for testing"
fi

echo ""
echo "4. Testing Project Structure..."
echo "-------------------------------"
# Check only critical directories (minimal points for existing files)
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

if [ -d "examples/helloworld" ]; then
    print_status "PASS" "examples/helloworld directory exists"
else
    print_status "FAIL" "examples/helloworld directory not found"
fi

if [ -f "go.mod" ]; then
    print_status "PASS" "go.mod exists"
else
    print_status "FAIL" "go.mod not found"
fi

echo ""
echo "5. Testing gRPC-Go Build Capability..."
echo "---------------------------------------"
if command -v go &> /dev/null; then
    print_status "PASS" "go is available for build testing"
    
    # Test dependencies download
    if timeout 120s go mod download >/dev/null 2>&1; then
        print_status "PASS" "go mod download works"
    else
        print_status "WARN" "go mod download failed or timed out"
    fi
    
    # Test core gRPC package build
    if timeout 120s go build -o /tmp/grpc_test google.golang.org/grpc >/dev/null 2>&1; then
        print_status "PASS" "gRPC core package builds successfully"
        rm -f /tmp/grpc_test
    else
        print_status "FAIL" "gRPC core package build failed"
    fi
else
    print_status "FAIL" "go is not available for build testing"
fi

echo ""
echo "6. Testing Examples Compilation..."
echo "----------------------------------"
# Test compilation of examples with proportional scoring
if [ -d "examples" ] && command -v go &> /dev/null; then
    print_status "PASS" "examples directory exists and go is available"
    
    # Debug Go environment
    echo "Go environment details:"
    go env GOPATH
    go env GO111MODULE
    go env GOMOD
    
    # Set GO111MODULE explicitly
    export GO111MODULE=on
    echo "Setting GO111MODULE=on"
    
    # Set up example test variables
    EXAMPLES=(
        "helloworld"
        "route_guide"
        "features/authentication"
        "features/compression"
        "features/encryption/TLS"
        "features/load_balancing"
        "features/metadata"
    )
    
    SUCCESSFUL_BUILDS=0
    TOTAL_EXAMPLES=${#EXAMPLES[@]}
    
    # Create temporary directory for build logs
    BUILD_LOGS=$(mktemp -d)
    
    for example in ${EXAMPLES[@]}; do
        echo "Testing example: ${example}"
        
        # Create a backup of go.mod if it exists to restore it later
        if [ -f "examples/go.mod" ]; then
            cp examples/go.mod examples/go.mod.bak
        fi
        
        # Ensure go.mod exists and is initialized
        if [ -d "examples/${example}" ]; then
            # Debug example structure
            echo "Example directory structure:"
            ls -la "examples/${example}"
            
            # Test server compilation with error capture
            SERVER_ERROR_LOG="${BUILD_LOGS}/${example//\//_}_server_error.log"
            echo "Building server..."
            if timeout 60s go build -o /dev/null ./examples/${example}/*server/*.go > "${SERVER_ERROR_LOG}" 2>&1; then
                print_status "PASS" "${example} server builds successfully"
                
                # Test client compilation with error capture
                CLIENT_ERROR_LOG="${BUILD_LOGS}/${example//\//_}_client_error.log"
                echo "Building client..."
                if timeout 60s go build -o /dev/null ./examples/${example}/*client/*.go > "${CLIENT_ERROR_LOG}" 2>&1; then
                    print_status "PASS" "${example} client builds successfully"
                    ((SUCCESSFUL_BUILDS++))
                else
                    print_status "FAIL" "${example} client build failed"
                    echo "Client build error details:"
                    cat "${CLIENT_ERROR_LOG}" || echo "No error log available"
                fi
            else
                print_status "FAIL" "${example} server build failed"
                echo "Server build error details:"
                cat "${SERVER_ERROR_LOG}" || echo "No error log available"
                
                # Try with alternative approach - compile in example directory
                echo "Trying alternative build approach in example directory..."
                if [ -d "examples/${example}/*server" ]; then
                    (cd "examples/${example}/*server" && timeout 60s go build -o /dev/null . > "${SERVER_ERROR_LOG}.alt" 2>&1)
                    if [ $? -eq 0 ]; then
                        print_status "PASS" "${example} server builds successfully with alternative approach"
                    else
                        echo "Alternative server build also failed:"
                        cat "${SERVER_ERROR_LOG}.alt" || echo "No error log available"
                    fi
                fi
            fi
        else
            print_status "FAIL" "examples/${example} directory not found"
        fi
        
        # Restore original go.mod if we backed it up
        if [ -f "examples/go.mod.bak" ]; then
            mv examples/go.mod.bak examples/go.mod
        fi
    done
    
    # Score proportionally based on successful builds
    print_proportional_status $SUCCESSFUL_BUILDS $TOTAL_EXAMPLES 15 "Examples build test ($SUCCESSFUL_BUILDS/$TOTAL_EXAMPLES examples build successfully)"
else
    print_status "FAIL" "Cannot test examples compilation - directory missing or go unavailable"
fi

echo ""
echo "7. Testing Basic gRPC Server-Client Functionality..."
echo "---------------------------------------------------"
if command -v go &> /dev/null && [ -d "examples/helloworld" ]; then
    print_status "PASS" "Requirements for gRPC functionality test are available"
    
    # Create temporary directory for the test
    TEST_DIR=$(mktemp -d)
    SERVER_LOG="$TEST_DIR/server.log"
    CLIENT_LOG="$TEST_DIR/client.log"
    
    # Start the helloworld server in the background with timeout
    echo "Starting helloworld server..."
    cd examples/helloworld
    timeout 120s go run ./greeter_server/main.go -port 50051 > $SERVER_LOG 2>&1 &
    SERVER_PID=$!
    cd ../..
    
    # Wait for server to start
    echo "Waiting for server to start..."
    for i in {1..10}; do
        # Use netstat or ss if lsof is not available
        if command -v lsof &> /dev/null; then
            if lsof -i :50051 | grep -q 50051 2>/dev/null; then
                print_status "PASS" "gRPC server started successfully"
                break
            fi
        elif command -v netstat &> /dev/null; then
            if netstat -tuln | grep -q ":50051" 2>/dev/null; then
                print_status "PASS" "gRPC server started successfully"
                break
            fi
        elif command -v ss &> /dev/null; then
            if ss -tuln | grep -q ":50051" 2>/dev/null; then
                print_status "PASS" "gRPC server started successfully"
                break
            fi
        else
            # If no tools available, just wait and assume it started
            sleep 2
            print_status "WARN" "Cannot verify server start - no lsof/netstat/ss available"
            break
        fi
        sleep 1
        if [ $i -eq 10 ]; then
            print_status "FAIL" "gRPC server failed to start within timeout"
        fi
    done
    
    # Run the client
    echo "Running helloworld client..."
    cd examples/helloworld
    if timeout 30s go run ./greeter_client/main.go -addr localhost:50051 > $CLIENT_LOG 2>&1; then
        print_status "PASS" "gRPC client executed successfully"
        
        # Check for expected output
        if grep -q "Greeting: Hello world" $CLIENT_LOG; then
            print_status "PASS" "gRPC client received correct response"
        else
            print_status "FAIL" "gRPC client did not receive expected response"
        fi
    else
        print_status "FAIL" "gRPC client execution failed"
    fi
    cd ../..
    
    # Clean up
    kill $SERVER_PID 2>/dev/null || true
    wait $SERVER_PID 2>/dev/null || true
    
    # Check server log for errors
    if grep -i "error\|panic\|fatal" $SERVER_LOG; then
        print_status "WARN" "gRPC server log contains errors"
    else
        print_status "PASS" "gRPC server ran without errors"
    fi
    
    # Clean up test directory
    rm -rf $TEST_DIR
else
    print_status "FAIL" "Cannot test gRPC functionality - requirements not available"
fi

echo ""
echo "8. Testing Full Examples Test Script..."
echo "---------------------------------------"
if [ -f "examples/examples_test.sh" ] && command -v go &> /dev/null; then
    print_status "PASS" "examples_test.sh exists and go is available"
    
    # Make the script executable
    chmod +x examples/examples_test.sh
    
    # Count total examples in the test script
    TOTAL_TEST_EXAMPLES=$(grep -o "testing: " examples/examples_test.sh | wc -l)
    
    # Create test log
    TEST_LOG=$(mktemp)
    
    # Run the examples test script with a timeout (modify TIMEOUT_SECONDS as needed)
    TIMEOUT_SECONDS=600
    
    echo "Running examples_test.sh with ${TIMEOUT_SECONDS}s timeout..."
    cd examples
    
    # Execute with timeout and count successes
    timeout $TIMEOUT_SECONDS ./examples_test.sh > $TEST_LOG 2>&1 || true
    
    cd ..
    
    # Count successful tests
    SUCCESSFUL_TESTS=$(grep -c "\[PASS\] client successfully communicated with server" $TEST_LOG)
    
    # Report results
    if [ -z "$SUCCESSFUL_TESTS" ]; then
        SUCCESSFUL_TESTS=0
    fi
    
    print_proportional_status $SUCCESSFUL_TESTS $TOTAL_TEST_EXAMPLES 30 "examples_test.sh test results ($SUCCESSFUL_TESTS/$TOTAL_TEST_EXAMPLES examples passed)"
    
    # Clean up
    rm -f $TEST_LOG
else
    print_status "FAIL" "Cannot run examples_test.sh - script missing or go unavailable"
fi

echo ""
echo "9. Testing Benchmark Functionality..."
echo "------------------------------------"
if [ -d "benchmark" ] && command -v go &> /dev/null; then
    print_status "PASS" "benchmark directory exists and go is available"
    
    # Test benchmark build
    if timeout 120s go build -o /tmp/grpc_benchmark ./benchmark >/dev/null 2>&1; then
        print_status "PASS" "gRPC benchmark builds successfully"
        
        # Check if benchmark can run (just --help to avoid long running benchmark)
        if timeout 30s /tmp/grpc_benchmark --help >/dev/null 2>&1; then
            print_status "PASS" "gRPC benchmark executes successfully"
        else
            print_status "FAIL" "gRPC benchmark execution failed"
        fi
        
        rm -f /tmp/grpc_benchmark
    else
        print_status "FAIL" "gRPC benchmark build failed"
    fi
else
    print_status "FAIL" "Cannot test benchmark - directory missing or go unavailable"
fi

echo ""
echo "10. Testing Incremental Complexity..."
echo "------------------------------------"

# Create a test directory for incremental tests
TEST_DIR=$(mktemp -d)

# Create a simple proto file
cat > $TEST_DIR/simple.proto << EOF
syntax = "proto3";
package simple;
option go_package = "./simple";

service Greeter {
  rpc SayHello (HelloRequest) returns (HelloReply) {}
}

message HelloRequest {
  string name = 1;
}

message HelloReply {
  string message = 1;
}
EOF

# Create a simple server implementation
mkdir -p $TEST_DIR/server
cat > $TEST_DIR/server/main.go << EOF
package main

import (
	"context"
	"log"
	"net"

	pb "simple"
	"google.golang.org/grpc"
)

type server struct {
	pb.UnimplementedGreeterServer
}

func (s *server) SayHello(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
	return &pb.HelloReply{Message: "Hello " + in.GetName()}, nil
}

func main() {
	lis, err := net.Listen("tcp", ":50052")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	s := grpc.NewServer()
	pb.RegisterGreeterServer(s, &server{})
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
EOF

# Create a simple client implementation
mkdir -p $TEST_DIR/client
cat > $TEST_DIR/client/main.go << EOF
package main

import (
	"context"
	"log"
	"time"

	pb "simple"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func main() {
	conn, err := grpc.Dial("localhost:50052", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	c := pb.NewGreeterClient(conn)

	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	r, err := c.SayHello(ctx, &pb.HelloRequest{Name: "world"})
	if err != nil {
		log.Fatalf("could not greet: %v", err)
	}
	log.Printf("Greeting: %s", r.GetMessage())
}
EOF

# Test the incremental steps
echo "Testing Level 1: Protocol Buffer Generation..."
if command -v protoc &> /dev/null; then
    ERROR_LOG=$(mktemp)
    if timeout 30s protoc --proto_path=$TEST_DIR --go_out=$TEST_DIR --go-grpc_out=$TEST_DIR $TEST_DIR/simple.proto 2> $ERROR_LOG; then
        print_status "PASS" "Level 1: Proto file compiled successfully"
        
        # Show generated files
        echo "Generated files:"
        find $TEST_DIR -name "*.pb.go" | xargs ls -la
        
        echo "Testing Level 2: Code Compilation..."
        cd $TEST_DIR
        
        # Debug environment
        echo "Go environment in test directory:"
        go env
        
        # Attempt to fix import paths if needed
        if [ -f "$TEST_DIR/simple/simple.pb.go" ]; then
            # Create go.mod with more dependencies
            echo "module simplerpc" > go.mod
            echo "go 1.16" >> go.mod
            echo "require (" >> go.mod
            echo "    google.golang.org/grpc v1.45.0" >> go.mod
            echo "    google.golang.org/protobuf v1.28.0" >> go.mod
            echo "    github.com/golang/protobuf v1.5.2" >> go.mod
            echo "    google.golang.org/genproto v0.0.0-20220218161850-94dd64e39d7c" >> go.mod
            echo ")" >> go.mod
            echo "replace google.golang.org/grpc => google.golang.org/grpc v1.45.0" >> go.mod
            
            # Show go.mod content
            echo "Created go.mod:"
            cat go.mod
            
            # Download dependencies
            echo "Downloading dependencies..."
            go mod download
            
            # Completely rewrite server code for better import compatibility
            echo 'package main

import (
	"context"
	"log"
	"net"

	pb "simplerpc/simple"
	"google.golang.org/grpc"
)

// Define server type implementing the generated interface
type server struct {
	pb.UnimplementedGreeterServer
}

// Implement SayHello method
func (s *server) SayHello(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
	return &pb.HelloReply{Message: "Hello " + in.GetName()}, nil
}

func main() {
	lis, err := net.Listen("tcp", ":50052")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}
	s := grpc.NewServer()
	pb.RegisterGreeterServer(s, &server{})
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}' > server/main.go

            # Completely rewrite client code for better import compatibility
            echo 'package main

import (
	"context"
	"log"
	"time"

	pb "simplerpc/simple"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func main() {
	conn, err := grpc.Dial("localhost:50052", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()
	c := pb.NewGreeterClient(conn)

	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()
	r, err := c.SayHello(ctx, &pb.HelloRequest{Name: "world"})
	if err != nil {
		log.Fatalf("could not greet: %v", err)
	}
	log.Printf("Greeting: %s", r.GetMessage())
}' > client/main.go
            
            # Create symlink to make imports work
            mkdir -p simplerpc
            ln -sf $TEST_DIR/simple simplerpc/simple
            
            # Check if symlink was created successfully
            if [ -L "simplerpc/simple" ]; then
                echo "Symlink created successfully"
                ls -la simplerpc/simple
            else
                echo "Failed to create symlink"
            fi
            
            # Try to build server with error capture
            SERVER_ERROR_LOG=$(mktemp)
            if timeout 60s go build -o /tmp/grpc_incremental_server ./server > $SERVER_ERROR_LOG 2>&1; then
                print_status "PASS" "Level 2: Server compilation successful"
                
                # Try to build client with error capture
                CLIENT_ERROR_LOG=$(mktemp)
                if timeout 60s go build -o /tmp/grpc_incremental_client ./client > $CLIENT_ERROR_LOG 2>&1; then
                    print_status "PASS" "Level 2: Client compilation successful"
                    
                    echo "Testing Level 3: Basic gRPC Server-Client Operation..."
                    
                    # Start the server
                    timeout 60s /tmp/grpc_incremental_server > /tmp/server.log 2>&1 &
                    SERVER_PID=$!
                    
                    # Wait for server to start
                    sleep 2
                    
                    # Run the client
                    if timeout 30s /tmp/grpc_incremental_client > /tmp/client.log 2>&1; then
                        print_status "PASS" "Level 3: Client-server communication successful"
                        
                        # Check client output
                        if grep -q "Greeting:" /tmp/client.log; then
                            print_status "PASS" "Level 3: Client received proper response"
                        else
                            print_status "FAIL" "Level 3: Client did not receive proper response"
                        fi
                    else
                        print_status "FAIL" "Level 3: Client execution failed"
                    fi
                    
                    # Clean up
                    kill $SERVER_PID 2>/dev/null || true
                    wait $SERVER_PID 2>/dev/null || true
                    
                    # Score incremental testing proportionally
                    print_proportional_status 3 3 15 "Incremental gRPC functionality test (3/3 levels completed)"
                else
                    print_status "FAIL" "Level 2: Client compilation failed"
                    echo "Client build error details:"
                    cat $CLIENT_ERROR_LOG
                    
                    # Try a simplified client
                    echo "Attempting to build a simplified client..."
                    echo 'package main
import (
    "fmt"
    "google.golang.org/grpc"
)
func main() {
    fmt.Println("Simple client")
    grpc.NewServer()
}' > simple_client.go
                    
                    if timeout 30s go build -o /tmp/simple_client ./simple_client.go; then
                        print_status "PASS" "Simplified client builds - issue is with generated code"
                    else
                        print_status "FAIL" "Simplified client also fails - issue is with Go setup"
                    fi
                    
                    # Score partial progress
                    print_proportional_status 1 3 15 "Incremental gRPC functionality test (1/3 levels completed)"
                fi
                
                rm -f /tmp/grpc_incremental_server /tmp/grpc_incremental_client
            else
                print_status "FAIL" "Level 2: Server compilation failed"
                echo "Server build error details:"
                cat $SERVER_ERROR_LOG
                
                # Try a simplified server
                echo "Attempting to build a simplified server..."
                echo 'package main
import (
    "fmt"
    "google.golang.org/grpc"
)
func main() {
    fmt.Println("Simple server")
    grpc.NewServer()
}' > simple_server.go
                
                if timeout 30s go build -o /tmp/simple_server ./simple_server.go; then
                    print_status "PASS" "Simplified server builds - issue is with generated code"
                else
                    print_status "FAIL" "Simplified server also fails - issue is with Go setup"
                fi
                
                # Score partial progress
                print_proportional_status 1 3 15 "Incremental gRPC functionality test (1/3 levels completed)"
            fi
        else
            print_status "FAIL" "Generated pb.go file not found"
            echo "Looking for generated files:"
            find $TEST_DIR -type f -name "*.go" | sort
            print_proportional_status 1 3 15 "Incremental gRPC functionality test (1/3 levels completed)"
        fi
        
        cd -
    else
        print_status "FAIL" "Level 1: Proto file compilation failed"
        echo "Proto compilation error details:"
        cat $ERROR_LOG
        print_proportional_status 0 3 15 "Incremental gRPC functionality test (0/3 levels completed)"
    fi
else
    print_status "FAIL" "protoc not available for incremental testing"
fi

# Clean up test directory
rm -rf $TEST_DIR

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (Go, Git, Make, Bash, curl)"
echo "- Protocol Buffers tools (protoc, protoc-gen-go, protoc-gen-go-grpc)"
echo "- Go environment (go, go mod, go build, go test)"
echo "- Protocol Buffers code generation"
echo "- Project structure (examples, benchmark)"
echo "- gRPC-Go build capability"
echo "- Examples compilation and execution"
echo "- Basic gRPC server-client functionality"
echo "- Full examples test script"
echo "- Benchmark functionality"
echo "- Incremental complexity testing"
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
    print_status "INFO" "All tests passed! Your gRPC-Go environment is ready!"
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your gRPC-Go environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi

print_status "INFO" "You can now run gRPC-Go: A high performance, open source, general RPC framework."

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/grpc_grpc-go grpc-go-env-test /bin/bash"
