#!/bin/bash
# cli_cli Environment Benchmark Test
# Tests if the environment is properly set up for the GitHub CLI Go project
# Don't exit on error - continue testing even if some tests fail
# set -e  # Exit on any error
trap 'echo -e "\n\033[0;31m[ERROR] Script interrupted by user\033[0m"; exit 1' INT TERM

# Function to ensure clean exit
cleanup() {
    echo -e "\n\033[0;34m[INFO] Cleaning up...\033[0m"
    # Kill any background processes
    jobs -p | xargs -r kill
    exit 1
}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test result counters
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
        *)
            echo "[$status] $message"
            ;;
    esac
}

# Function to check if a command exists
check_command() {
    local cmd=$1
    local name=$2
    
    if command -v "$cmd" &> /dev/null; then
        print_status "PASS" "$name is installed"
        return 0
    else
        print_status "FAIL" "$name is not installed"
        return 1
    fi
}

# Function to check Go version
check_go_version() {
    local go_version=$(go version 2>&1)
    print_status "INFO" "Go version: $go_version"
    
    # Extract version number
    local version=$(go version | sed 's/go version go//' | sed 's/ .*//')
    local major=$(echo $version | cut -d'.' -f1)
    local minor=$(echo $version | cut -d'.' -f2)
    
    if [ "$major" -eq 1 ] && [ "$minor" -ge 24 ]; then
        print_status "PASS" "Go version >= 1.24 (found $version)"
    else
        print_status "FAIL" "Go version < 1.24 (found $version)"
    fi
}

# Check if we're running inside Docker container
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo "Running inside Docker container - proceeding with environment test..."
else
    echo "Not running in Docker container - building and running Docker test..."
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        echo "ERROR: Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "envgym/envgym.dockerfile" ]; then
        echo "ERROR: envgym.dockerfile not found. Please run this script from the cli_cli project root directory."
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    docker build -f envgym/envgym.dockerfile -t cli-env-test .
    
    # Run this script inside Docker container
    echo "Running environment test in Docker container..."
    docker run --rm -v "$(pwd):/home/cc/cli" cli-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        cd /home/cc/cli && ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "cli_cli Environment Benchmark Test"
echo "=========================================="
echo ""

echo "1. Checking System Dependencies..."
echo "--------------------------------"
# Check system commands
check_command "go" "Go"
check_command "git" "Git"
check_command "make" "Make"
check_command "bash" "Bash"
check_command "curl" "cURL"

echo ""
echo "2. Checking Go Environment..."
echo "----------------------------"
check_go_version

# Check Go environment
if [ -n "$GOPATH" ]; then
    print_status "PASS" "GOPATH is set: $GOPATH"
else
    print_status "WARN" "GOPATH is not set"
fi

if [ -n "$GOROOT" ]; then
    print_status "PASS" "GOROOT is set: $GOROOT"
else
    print_status "WARN" "GOROOT is not set"
fi

# Check Go modules
if go env GOMOD 2>/dev/null | grep -q "go.mod"; then
    print_status "PASS" "Go modules are enabled"
else
    print_status "FAIL" "Go modules are not enabled"
fi

echo ""
echo "3. Checking Project Structure..."
echo "-------------------------------"
# Check if we're in the right directory
if [ -f "go.mod" ]; then
    print_status "PASS" "go.mod found"
else
    print_status "FAIL" "go.mod not found"
    exit 1
fi

if [ -f "go.sum" ]; then
    print_status "PASS" "go.sum found"
else
    print_status "FAIL" "go.sum missing"
fi

# Check if we're in the cli project
if grep -q "github.com/cli/cli" go.mod 2>/dev/null; then
    print_status "PASS" "cli project detected"
else
    print_status "FAIL" "Not a cli project"
fi

# Check project structure
print_status "INFO" "Checking project structure..."

if [ -d "cmd" ]; then
    print_status "PASS" "cmd directory exists"
else
    print_status "FAIL" "cmd directory missing"
fi

if [ -d "pkg" ]; then
    print_status "PASS" "pkg directory exists"
else
    print_status "FAIL" "pkg directory missing"
fi

if [ -d "internal" ]; then
    print_status "PASS" "internal directory exists"
else
    print_status "FAIL" "internal directory missing"
fi

if [ -d "test" ]; then
    print_status "PASS" "test directory exists"
else
    print_status "FAIL" "test directory missing"
fi

if [ -d "acceptance" ]; then
    print_status "PASS" "acceptance directory exists"
else
    print_status "FAIL" "acceptance directory missing"
fi

if [ -d "docs" ]; then
    print_status "PASS" "docs directory exists"
else
    print_status "FAIL" "docs directory missing"
fi

if [ -d "script" ]; then
    print_status "PASS" "script directory exists"
else
    print_status "FAIL" "script directory missing"
fi

if [ -d "utils" ]; then
    print_status "PASS" "utils directory exists"
else
    print_status "FAIL" "utils directory missing"
fi

if [ -d "api" ]; then
    print_status "PASS" "api directory exists"
else
    print_status "FAIL" "api directory missing"
fi

if [ -d "context" ]; then
    print_status "PASS" "context directory exists"
else
    print_status "FAIL" "context directory missing"
fi

if [ -d "git" ]; then
    print_status "PASS" "git directory exists"
else
    print_status "FAIL" "git directory missing"
fi

if [ -d "build" ]; then
    print_status "PASS" "build directory exists"
else
    print_status "FAIL" "build directory missing"
fi

if [ -d "third-party" ]; then
    print_status "PASS" "third-party directory exists"
else
    print_status "FAIL" "third-party directory missing"
fi

echo ""
echo "4. Checking Command Structure..."
echo "-------------------------------"
# Check command structure
if [ -d "cmd/gh" ]; then
    print_status "PASS" "cmd/gh directory exists"
else
    print_status "FAIL" "cmd/gh directory missing"
fi

if [ -d "cmd/gen-docs" ]; then
    print_status "PASS" "cmd/gen-docs directory exists"
else
    print_status "FAIL" "cmd/gen-docs directory missing"
fi

# Check for main.go files
if [ -f "cmd/gh/main.go" ]; then
    print_status "PASS" "cmd/gh/main.go exists"
else
    print_status "FAIL" "cmd/gh/main.go missing"
fi

if [ -f "cmd/gen-docs/main.go" ]; then
    print_status "PASS" "cmd/gen-docs/main.go exists"
else
    print_status "FAIL" "cmd/gen-docs/main.go missing"
fi

echo ""
echo "5. Testing Go Build..."
echo "---------------------"
# Test go build
if go mod download 2>/dev/null; then
    print_status "PASS" "go mod download successful"
else
    print_status "FAIL" "go mod download failed"
fi

if go mod verify 2>/dev/null; then
    print_status "PASS" "go mod verify successful"
else
    print_status "FAIL" "go mod verify failed"
fi

if go build ./cmd/gh 2>/dev/null; then
    print_status "PASS" "go build ./cmd/gh successful"
else
    print_status "FAIL" "go build ./cmd/gh failed"
fi

if go build ./cmd/gen-docs 2>/dev/null; then
    print_status "PASS" "go build ./cmd/gen-docs successful"
else
    print_status "FAIL" "go build ./cmd/gen-docs failed"
fi

echo ""
echo "6. Testing Go Dependencies..."
echo "----------------------------"
# Check if go.mod has required dependencies
if grep -q "github.com/spf13/cobra" go.mod 2>/dev/null; then
    print_status "PASS" "cobra dependency found in go.mod"
else
    print_status "FAIL" "cobra dependency missing in go.mod"
fi

if grep -q "github.com/cli/go-gh" go.mod 2>/dev/null; then
    print_status "PASS" "go-gh dependency found in go.mod"
else
    print_status "FAIL" "go-gh dependency missing in go.mod"
fi

if grep -q "github.com/cli/oauth" go.mod 2>/dev/null; then
    print_status "PASS" "oauth dependency found in go.mod"
else
    print_status "FAIL" "oauth dependency missing in go.mod"
fi

if grep -q "github.com/charmbracelet/glamour" go.mod 2>/dev/null; then
    print_status "PASS" "glamour dependency found in go.mod"
else
    print_status "FAIL" "glamour dependency missing in go.mod"
fi

if grep -q "github.com/stretchr/testify" go.mod 2>/dev/null; then
    print_status "PASS" "testify dependency found in go.mod"
else
    print_status "FAIL" "testify dependency missing in go.mod"
fi

echo ""
echo "7. Testing Source Code Structure..."
echo "-----------------------------------"
# Check source code structure
if [ -d "pkg" ]; then
    go_files=$(find pkg -name "*.go" | wc -l)
    print_status "INFO" "Found $go_files Go files in pkg directory"
    if [ "$go_files" -gt 0 ]; then
        print_status "PASS" "Go source files found in pkg"
    else
        print_status "FAIL" "No Go source files found in pkg"
    fi
fi

if [ -d "internal" ]; then
    go_files=$(find internal -name "*.go" | wc -l)
    print_status "INFO" "Found $go_files Go files in internal directory"
    if [ "$go_files" -gt 0 ]; then
        print_status "PASS" "Go source files found in internal"
    else
        print_status "FAIL" "No Go source files found in internal"
    fi
fi

echo ""
echo "8. Testing Build Scripts..."
echo "---------------------------"
# Check build scripts
if [ -f "script/build.go" ]; then
    print_status "PASS" "script/build.go exists"
else
    print_status "FAIL" "script/build.go missing"
fi

# Test if build script compiles
if go build script/build.go 2>/dev/null; then
    print_status "PASS" "script/build.go compiles"
else
    print_status "FAIL" "script/build.go does not compile"
fi

echo ""
echo "9. Testing Makefile Targets..."
echo "-------------------------------"
# Test Makefile targets
if [ -f "Makefile" ]; then
    print_status "INFO" "Testing Makefile targets..."
    
    # Check if make can parse the Makefile
    if make -n test 2>/dev/null; then
        print_status "PASS" "Makefile test target is valid"
    else
        print_status "WARN" "Makefile test target is not valid"
    fi
    
    if make -n clean 2>/dev/null; then
        print_status "PASS" "Makefile clean target is valid"
    else
        print_status "WARN" "Makefile clean target is not valid"
    fi
    
    if make -n manpages 2>/dev/null; then
        print_status "PASS" "Makefile manpages target is valid"
    else
        print_status "WARN" "Makefile manpages target is not valid"
    fi
    
    if make -n completions 2>/dev/null; then
        print_status "PASS" "Makefile completions target is valid"
    else
        print_status "WARN" "Makefile completions target is not valid"
    fi
fi

echo ""
echo "10. Testing Tests..."
echo "-------------------"
# Check tests
if [ -d "test" ]; then
    test_count=$(find test -name "*.go" | wc -l)
    print_status "INFO" "Found $test_count test files in test/"
    
    if [ "$test_count" -gt 0 ]; then
        print_status "PASS" "Test files found"
        
        # Test specific test categories
        if [ -d "test/integration" ]; then
            print_status "PASS" "test/integration directory exists"
        else
            print_status "FAIL" "test/integration directory missing"
        fi
        
        if [ -f "test/helpers.go" ]; then
            print_status "PASS" "test/helpers.go exists"
        else
            print_status "FAIL" "test/helpers.go missing"
        fi
    else
        print_status "FAIL" "No test files found"
    fi
fi

# Check acceptance tests
if [ -d "acceptance" ]; then
    acceptance_count=$(find acceptance -name "*.go" | wc -l)
    print_status "INFO" "Found $acceptance_count acceptance test files"
    
    if [ "$acceptance_count" -gt 0 ]; then
        print_status "PASS" "Acceptance test files found"
        
        if [ -f "acceptance/acceptance_test.go" ]; then
            print_status "PASS" "acceptance/acceptance_test.go exists"
        else
            print_status "FAIL" "acceptance/acceptance_test.go missing"
        fi
        
        if [ -d "acceptance/testdata" ]; then
            print_status "PASS" "acceptance/testdata directory exists"
        else
            print_status "FAIL" "acceptance/testdata directory missing"
        fi
    else
        print_status "FAIL" "No acceptance test files found"
    fi
fi

echo ""
echo "11. Testing Documentation..."
echo "----------------------------"
# Check documentation
if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md missing"
fi

if [ -f "LICENSE" ]; then
    print_status "PASS" "LICENSE exists"
else
    print_status "FAIL" "LICENSE missing"
fi

if [ -d "docs" ]; then
    doc_count=$(find docs -type f | wc -l)
    print_status "INFO" "Found $doc_count files in docs/"
    if [ "$doc_count" -gt 0 ]; then
        print_status "PASS" "Documentation files found"
    else
        print_status "WARN" "No documentation files found"
    fi
fi

# Check if documentation mentions GitHub CLI
if grep -q "GitHub CLI" README.md 2>/dev/null; then
    print_status "PASS" "README.md contains GitHub CLI references"
else
    print_status "WARN" "README.md missing GitHub CLI references"
fi

echo ""
echo "12. Testing Configuration Files..."
echo "----------------------------------"
# Check configuration files
if [ -f ".golangci.yml" ]; then
    print_status "PASS" ".golangci.yml exists"
else
    print_status "FAIL" ".golangci.yml missing"
fi

if [ -f ".goreleaser.yml" ]; then
    print_status "PASS" ".goreleaser.yml exists"
else
    print_status "FAIL" ".goreleaser.yml missing"
fi

if [ -f ".gitignore" ]; then
    print_status "PASS" ".gitignore exists"
else
    print_status "FAIL" ".gitignore missing"
fi

if [ -f ".gitattributes" ]; then
    print_status "PASS" ".gitattributes exists"
else
    print_status "FAIL" ".gitattributes missing"
fi

echo ""
echo "13. Testing Third Party Licenses..."
echo "-----------------------------------"
# Check third party licenses
if [ -f "third-party-licenses.linux.md" ]; then
    print_status "PASS" "third-party-licenses.linux.md exists"
else
    print_status "FAIL" "third-party-licenses.linux.md missing"
fi

if [ -f "third-party-licenses.darwin.md" ]; then
    print_status "PASS" "third-party-licenses.darwin.md exists"
else
    print_status "FAIL" "third-party-licenses.darwin.md missing"
fi

if [ -f "third-party-licenses.windows.md" ]; then
    print_status "PASS" "third-party-licenses.windows.md exists"
else
    print_status "FAIL" "third-party-licenses.windows.md missing"
fi

echo ""
echo "14. Testing Go.toml Configuration..."
echo "------------------------------------"
# Check go.mod configuration
if grep -q 'go 1.24' go.mod 2>/dev/null; then
    print_status "PASS" "Go version 1.24 is specified"
else
    print_status "FAIL" "Go version 1.24 is not specified"
fi

if grep -q 'toolchain go1.24.5' go.mod 2>/dev/null; then
    print_status "PASS" "Go toolchain 1.24.5 is specified"
else
    print_status "FAIL" "Go toolchain 1.24.5 is not specified"
fi

if grep -q 'module github.com/cli/cli/v2' go.mod 2>/dev/null; then
    print_status "PASS" "Module name is correctly set"
else
    print_status "FAIL" "Module name is not correctly set"
fi

echo ""
echo "15. Testing Basic Go Functionality..."
echo "-------------------------------------"
# Test basic Go functionality
if go version >/dev/null 2>&1; then
    print_status "PASS" "Go basic functionality works"
else
    print_status "FAIL" "Go basic functionality failed"
fi

if go env >/dev/null 2>&1; then
    print_status "PASS" "Go environment is accessible"
else
    print_status "FAIL" "Go environment is not accessible"
fi

echo ""
echo "16. Testing Git Configuration..."
echo "--------------------------------"
# Check Git configuration
if git --version >/dev/null 2>&1; then
    print_status "PASS" "Git is properly configured"
else
    print_status "FAIL" "Git is not properly configured"
fi

# Check if this is a Git repository
if [ -d ".git" ]; then
    print_status "PASS" "This is a Git repository"
else
    print_status "WARN" "This is not a Git repository"
fi

echo ""
echo "17. Testing Locale Configuration..."
echo "-----------------------------------"
# Test locale configuration
if [ "$LANG" = "C.UTF-8" ] || [ "$LANG" = "en_US.UTF-8" ]; then
    print_status "PASS" "LANG is set to UTF-8 locale"
else
    print_status "WARN" "LANG is not set to UTF-8 locale (current: $LANG)"
fi

if [ "$LC_ALL" = "C.UTF-8" ] || [ "$LC_ALL" = "en_US.UTF-8" ]; then
    print_status "PASS" "LC_ALL is set to UTF-8 locale"
else
    print_status "WARN" "LC_ALL is not set to UTF-8 locale (current: $LC_ALL)"
fi

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="

# Summary
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (Go 1.24+, Git, Make, cURL)"
echo "- Go environment and modules"
echo "- Project structure and directories"
echo "- Command structure and main files"
echo "- Go build and dependencies"
echo "- Source code organization"
echo "- Build scripts and Makefile targets"
echo "- Test structure (unit and acceptance tests)"
echo "- Documentation and licenses"
echo "- Configuration files"
echo "- Third party licenses"
echo "- Go.mod configuration"
echo "- Basic tool functionality"
echo "- Git repository setup"
echo "- Locale configuration"
echo ""

echo ""
echo "=========================================="
echo "Test Results Summary"
echo "=========================================="
echo -e "${GREEN}PASS: $PASS_COUNT${NC}"
echo -e "${RED}FAIL: $FAIL_COUNT${NC}"
echo -e "${YELLOW}WARN: $WARN_COUNT${NC}"

if [ $FAIL_COUNT -eq 0 ]; then
    print_status "INFO" "All tests passed! Your GitHub CLI environment is ready!"
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your GitHub CLI environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi

print_status "INFO" "You can now build and test GitHub CLI."
print_status "INFO" "Example: go build ./cmd/gh"
print_status "INFO" "Example: make test"
print_status "INFO" "Example: go test ./..."

echo ""
print_status "INFO" "For more information, see README.md"
print_status "INFO" "For acceptance tests, see acceptance/README.md" 