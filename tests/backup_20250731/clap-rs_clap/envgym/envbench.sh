#!/bin/bash
# clap-rs_clap Environment Benchmark Test
# Tests if the environment is properly set up for the clap Rust command line argument parser project
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

# Function to check Rust version
check_rust_version() {
    local rust_version=$(rustc --version 2>&1)
    print_status "INFO" "Rust version: $rust_version"
    
    # Extract version number
    local version=$(rustc --version | sed 's/rustc //' | sed 's/ .*//')
    local major=$(echo $version | cut -d'.' -f1)
    local minor=$(echo $version | cut -d'.' -f2)
    
    if [ "$major" -eq 1 ] && [ "$minor" -ge 74 ]; then
        print_status "PASS" "Rust version >= 1.74 (found $version)"
    else
        print_status "FAIL" "Rust version < 1.74 (found $version)"
    fi
}

# Function to check Cargo version
check_cargo_version() {
    local cargo_version=$(cargo --version 2>&1)
    print_status "INFO" "Cargo version: $cargo_version"
    
    # Extract version number
    local version=$(cargo --version | sed 's/cargo //' | sed 's/ .*//')
    local major=$(echo $version | cut -d'.' -f1)
    local minor=$(echo $version | cut -d'.' -f2)
    
    if [ "$major" -eq 1 ] && [ "$minor" -ge 74 ]; then
        print_status "PASS" "Cargo version >= 1.74 (found $version)"
    else
        print_status "FAIL" "Cargo version < 1.74 (found $version)"
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the clap-rs_clap project root directory."
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    docker build -f envgym/envgym.dockerfile -t clap-env-test .
    
    # Run this script inside Docker container
    echo "Running environment test in Docker container..."
    docker run --rm -v "$(pwd):/home/cc/clap" clap-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        cd /home/cc/clap && ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "clap-rs_clap Environment Benchmark Test"
echo "=========================================="
echo ""

echo "1. Checking System Dependencies..."
echo "--------------------------------"
# Check system commands
check_command "rustc" "Rust Compiler"
check_command "cargo" "Cargo"
check_command "git" "Git"
check_command "make" "Make"
check_command "bash" "Bash"

echo ""
echo "2. Checking Rust Toolchain..."
echo "-----------------------------"
check_rust_version
check_cargo_version

# Check Rust toolchain configuration
if [ -f "rust-toolchain.toml" ]; then
    print_status "PASS" "rust-toolchain.toml exists"
    
    # Check if toolchain version matches
    toolchain_version=$(grep "channel = " rust-toolchain.toml | sed 's/.*channel = "//' | sed 's/".*//')
    print_status "INFO" "Toolchain version in rust-toolchain.toml: $toolchain_version"
    
    if [ "$toolchain_version" = "1.88" ]; then
        print_status "PASS" "Toolchain version matches required 1.88"
    else
        print_status "FAIL" "Toolchain version mismatch (expected 1.88, found $toolchain_version)"
    fi
else
    print_status "WARN" "rust-toolchain.toml missing (using system default)"
fi

# Check Rust target
if rustup target list --installed | grep -q "x86_64-unknown-linux-gnu"; then
    print_status "PASS" "x86_64-unknown-linux-gnu target is installed"
else
    print_status "FAIL" "x86_64-unknown-linux-gnu target is not installed"
fi

echo ""
echo "3. Checking Project Structure..."
echo "-------------------------------"
# Check if we're in the right directory
if [ -f "Cargo.toml" ]; then
    print_status "PASS" "Cargo.toml found"
else
    print_status "FAIL" "Cargo.toml not found"
    exit 1
fi

# Check if we're in the clap project
if grep -q "clap" Cargo.toml 2>/dev/null; then
    print_status "PASS" "clap project detected"
else
    print_status "FAIL" "Not a clap project"
fi

# Check project structure
print_status "INFO" "Checking project structure..."

if [ -d "src" ]; then
    print_status "PASS" "src directory exists"
else
    print_status "FAIL" "src directory missing"
fi

if [ -d "examples" ]; then
    print_status "PASS" "examples directory exists"
else
    print_status "FAIL" "examples directory missing"
fi

if [ -d "tests" ]; then
    print_status "PASS" "tests directory exists"
else
    print_status "FAIL" "tests directory missing"
fi

if [ -d "assets" ]; then
    print_status "PASS" "assets directory exists"
else
    print_status "FAIL" "assets directory missing"
fi

if [ -d ".cargo" ]; then
    print_status "PASS" ".cargo directory exists"
else
    print_status "FAIL" ".cargo directory missing"
fi

echo ""
echo "4. Checking Workspace Members..."
echo "-------------------------------"
# Check workspace members
if [ -d "clap_builder" ]; then
    print_status "PASS" "clap_builder directory exists"
else
    print_status "FAIL" "clap_builder directory missing"
fi

if [ -d "clap_derive" ]; then
    print_status "PASS" "clap_derive directory exists"
else
    print_status "FAIL" "clap_derive directory missing"
fi

if [ -d "clap_lex" ]; then
    print_status "PASS" "clap_lex directory exists"
else
    print_status "FAIL" "clap_lex directory missing"
fi

if [ -d "clap_complete" ]; then
    print_status "PASS" "clap_complete directory exists"
else
    print_status "FAIL" "clap_complete directory missing"
fi

if [ -d "clap_complete_nushell" ]; then
    print_status "PASS" "clap_complete_nushell directory exists"
else
    print_status "FAIL" "clap_complete_nushell directory missing"
fi

if [ -d "clap_mangen" ]; then
    print_status "PASS" "clap_mangen directory exists"
else
    print_status "FAIL" "clap_mangen directory missing"
fi

if [ -d "clap_bench" ]; then
    print_status "PASS" "clap_bench directory exists"
else
    print_status "FAIL" "clap_bench directory missing"
fi

echo ""
echo "5. Testing Cargo Build..."
echo "------------------------"
# Test cargo build
if cargo check --quiet 2>/dev/null; then
    print_status "PASS" "cargo check successful"
else
    print_status "FAIL" "cargo check failed"
fi

echo ""
echo "6. Testing Workspace Build..."
echo "-----------------------------"
# Test workspace build
if cargo check --workspace --quiet 2>/dev/null; then
    print_status "PASS" "cargo check --workspace successful"
else
    print_status "FAIL" "cargo check --workspace failed"
fi

echo ""
echo "7. Testing Examples..."
echo "---------------------"
# Check examples
if [ -d "examples" ]; then
    example_count=$(find examples -name "*.rs" | wc -l)
    print_status "INFO" "Found $example_count example files"
    
    if [ "$example_count" -gt 0 ]; then
        print_status "PASS" "Example files found"
        
        # Test a few specific examples
        if [ -f "examples/demo.rs" ]; then
            print_status "INFO" "Testing examples/demo.rs compilation..."
            if cargo check --example demo --quiet 2>/dev/null; then
                print_status "PASS" "examples/demo.rs compiles"
            else
                print_status "FAIL" "examples/demo.rs does not compile"
            fi
        fi
        
        if [ -f "examples/git.rs" ]; then
            print_status "INFO" "Testing examples/git.rs compilation..."
            if cargo check --example git --quiet 2>/dev/null; then
                print_status "PASS" "examples/git.rs compiles"
            else
                print_status "FAIL" "examples/git.rs does not compile"
            fi
        fi
        
        if [ -f "examples/find.rs" ]; then
            print_status "INFO" "Testing examples/find.rs compilation..."
            if cargo check --example find --quiet 2>/dev/null; then
                print_status "PASS" "examples/find.rs compiles"
            else
                print_status "FAIL" "examples/find.rs does not compile"
            fi
        fi
    else
        print_status "FAIL" "No example files found"
    fi
fi

echo ""
echo "8. Testing Tests..."
echo "------------------"
# Check tests
if [ -d "tests" ]; then
    test_count=$(find tests -name "*.rs" | wc -l)
    print_status "INFO" "Found $test_count test files"
    
    if [ "$test_count" -gt 0 ]; then
        print_status "PASS" "Test files found"
        
        # Test specific test categories
        if [ -d "tests/derive" ]; then
            print_status "PASS" "tests/derive directory exists"
        else
            print_status "FAIL" "tests/derive directory missing"
        fi
        
        if [ -d "tests/builder" ]; then
            print_status "PASS" "tests/builder directory exists"
        else
            print_status "FAIL" "tests/builder directory missing"
        fi
        
        if [ -d "tests/ui" ]; then
            print_status "PASS" "tests/ui directory exists"
        else
            print_status "FAIL" "tests/ui directory missing"
        fi
    else
        print_status "FAIL" "No test files found"
    fi
fi

echo ""
echo "9. Testing Features..."
echo "---------------------"
# Test different feature combinations
print_status "INFO" "Testing feature combinations..."

# Test minimal features
if cargo check --no-default-features --features "std" --quiet 2>/dev/null; then
    print_status "PASS" "minimal features (std) compile"
else
    print_status "FAIL" "minimal features (std) do not compile"
fi

# Test default features
if cargo check --quiet 2>/dev/null; then
    print_status "PASS" "default features compile"
else
    print_status "FAIL" "default features do not compile"
fi

# Test full features
if cargo check --features "deprecated derive cargo env unicode string wrap_help unstable-ext" --quiet 2>/dev/null; then
    print_status "PASS" "full features compile"
else
    print_status "WARN" "full features do not compile"
fi

echo ""
echo "10. Testing Documentation..."
echo "----------------------------"
# Check documentation
if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md missing"
fi

if [ -f "CHANGELOG.md" ]; then
    print_status "PASS" "CHANGELOG.md exists"
else
    print_status "FAIL" "CHANGELOG.md missing"
fi

if [ -f "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md exists"
else
    print_status "FAIL" "CONTRIBUTING.md missing"
fi

if [ -f "LICENSE-APACHE" ]; then
    print_status "PASS" "LICENSE-APACHE exists"
else
    print_status "FAIL" "LICENSE-APACHE missing"
fi

if [ -f "LICENSE-MIT" ]; then
    print_status "PASS" "LICENSE-MIT exists"
else
    print_status "FAIL" "LICENSE-MIT missing"
fi

# Check if documentation mentions clap
if grep -q "clap" README.md 2>/dev/null; then
    print_status "PASS" "README.md contains clap references"
else
    print_status "WARN" "README.md missing clap references"
fi

echo ""
echo "11. Testing Configuration Files..."
echo "----------------------------------"
# Check configuration files
if [ -f "Makefile" ]; then
    print_status "PASS" "Makefile exists"
else
    print_status "FAIL" "Makefile missing"
fi

if [ -f ".clippy.toml" ]; then
    print_status "PASS" ".clippy.toml exists"
else
    print_status "FAIL" ".clippy.toml missing"
fi

if [ -f "deny.toml" ]; then
    print_status "PASS" "deny.toml exists"
else
    print_status "FAIL" "deny.toml missing"
fi

if [ -f "typos.toml" ]; then
    print_status "PASS" "typos.toml exists"
else
    print_status "FAIL" "typos.toml missing"
fi

if [ -f ".pre-commit-config.yaml" ]; then
    print_status "PASS" ".pre-commit-config.yaml exists"
else
    print_status "FAIL" ".pre-commit-config.yaml missing"
fi

echo ""
echo "12. Testing Cargo.toml Configuration..."
echo "---------------------------------------"
# Check Cargo.toml configuration
if grep -q 'edition = "2021"' Cargo.toml 2>/dev/null; then
    print_status "PASS" "Rust 2021 edition is specified"
else
    print_status "FAIL" "Rust 2021 edition is not specified"
fi

if grep -q 'rust-version = "1.74"' Cargo.toml 2>/dev/null; then
    print_status "PASS" "Rust version 1.74 is specified"
else
    print_status "FAIL" "Rust version 1.74 is not specified"
fi

if grep -q 'resolver = "2"' Cargo.toml 2>/dev/null; then
    print_status "PASS" "Workspace resolver 2 is specified"
else
    print_status "FAIL" "Workspace resolver 2 is not specified"
fi

echo ""
echo "13. Testing Makefile Targets..."
echo "-------------------------------"
# Test Makefile targets
if [ -f "Makefile" ]; then
    print_status "INFO" "Testing Makefile targets..."
    
    # Check if make can parse the Makefile
    if make -n check-default 2>/dev/null; then
        print_status "PASS" "Makefile check-default target is valid"
    else
        print_status "WARN" "Makefile check-default target is not valid"
    fi
    
    if make -n build-default 2>/dev/null; then
        print_status "PASS" "Makefile build-default target is valid"
    else
        print_status "WARN" "Makefile build-default target is not valid"
    fi
    
    if make -n test-default 2>/dev/null; then
        print_status "PASS" "Makefile test-default target is valid"
    else
        print_status "WARN" "Makefile test-default target is not valid"
    fi
fi

echo ""
echo "14. Testing Basic Rust Functionality..."
echo "---------------------------------------"
# Test basic Rust functionality
if rustc --version >/dev/null 2>&1; then
    print_status "PASS" "Rust compiler basic functionality works"
else
    print_status "FAIL" "Rust compiler basic functionality failed"
fi

if cargo --version >/dev/null 2>&1; then
    print_status "PASS" "Cargo basic functionality works"
else
    print_status "FAIL" "Cargo basic functionality failed"
fi

echo ""
echo "15. Testing Git Configuration..."
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
echo "16. Testing Locale Configuration..."
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
echo "- System dependencies (Rust 1.74+, Cargo, Git, Make)"
echo "- Rust toolchain and workspace configuration"
echo "- Project structure and workspace members"
echo "- Cargo build and workspace build"
echo "- Examples compilation"
echo "- Test structure and categories"
echo "- Feature combinations"
echo "- Documentation and licenses"
echo "- Configuration files"
echo "- Makefile targets"
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
    print_status "INFO" "All tests passed! Your clap environment is ready!"
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your clap environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi

print_status "INFO" "You can now build and test clap."
print_status "INFO" "Example: cargo check --workspace"
print_status "INFO" "Example: cargo test"
print_status "INFO" "Example: make check-default"

echo ""
print_status "INFO" "For more information, see README.md and CONTRIBUTING.md"
print_status "INFO" "For examples, see examples/ directory" 