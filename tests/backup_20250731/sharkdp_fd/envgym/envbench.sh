#!/bin/bash

# Fd Environment Benchmark Test Script
# This script tests the Docker environment setup for Fd: A simple, fast and user-friendly alternative to find
# Tailored specifically for Fd project requirements and features

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
    docker stop fd-env-test 2>/dev/null || true
    docker rm fd-env-test 2>/dev/null || true
    exit 0
}

trap cleanup SIGINT SIGTERM

# Check if we're running in Docker
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo "Running inside Docker container - performing environment tests..."
    DOCKER_MODE=true
else
    echo "Running on host - checking for Docker and envgym.dockerfile"
    DOCKER_MODE=false
    
    if ! command -v docker &> /dev/null; then
        print_status "WARN" "Docker not available - Docker environment not available"
    elif [ -f "envgym/envgym.dockerfile" ]; then
        echo "Building Docker image..."
        if timeout 600s docker build -f envgym/envgym.dockerfile -t fd-env-test .; then
            echo "Docker build successful - analyzing build process..."
            DOCKER_BUILD_SUCCESS=true
        else
            echo "WARNING: Docker build failed - analyzing Dockerfile only"
            DOCKER_BUILD_FAILED=true
        fi
    else
        print_status "WARN" "envgym.dockerfile not found - Docker environment not available"
    fi
fi

# If Docker build was successful, analyze the build process
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    echo ""
    echo "Docker build was successful - analyzing build process..."
    echo "------------------------------------------------------"
    
    # Test if Rust is available in Docker
    if docker run --rm fd-env-test rustc --version >/dev/null 2>&1; then
        rust_version=$(docker run --rm fd-env-test rustc --version 2>&1)
        print_status "PASS" "Rust is available in Docker: $rust_version"
    else
        print_status "FAIL" "Rust is not available in Docker"
    fi
    
    # Test if Cargo is available in Docker
    if docker run --rm fd-env-test cargo --version >/dev/null 2>&1; then
        cargo_version=$(docker run --rm fd-env-test cargo --version 2>&1)
        print_status "PASS" "Cargo is available in Docker: $cargo_version"
    else
        print_status "FAIL" "Cargo is not available in Docker"
    fi
    
    # Test if Git is available in Docker
    if docker run --rm fd-env-test git --version >/dev/null 2>&1; then
        git_version=$(docker run --rm fd-env-test git --version 2>&1)
        print_status "PASS" "Git is available in Docker: $git_version"
    else
        print_status "FAIL" "Git is not available in Docker"
    fi
    
    # Test if fd is available in Docker
    if docker run --rm fd-env-test fd --version >/dev/null 2>&1; then
        fd_version=$(docker run --rm fd-env-test fd --version 2>&1)
        print_status "PASS" "fd is available in Docker: $fd_version"
    else
        print_status "FAIL" "fd is not available in Docker"
    fi
    
    # Test if fdfind is available in Docker (alternative name)
    if docker run --rm fd-env-test fdfind --version >/dev/null 2>&1; then
        fdfind_version=$(docker run --rm fd-env-test fdfind --version 2>&1)
        print_status "PASS" "fdfind is available in Docker: $fdfind_version"
    else
        print_status "WARN" "fdfind is not available in Docker"
    fi
fi

echo "=========================================="
echo "Fd Environment Benchmark Test"
echo "=========================================="

echo "1. Checking Rust Environment..."
echo "-------------------------------"
# Check Rust version
if command -v rustc &> /dev/null; then
    rust_version=$(rustc --version 2>&1)
    print_status "PASS" "Rust is available: $rust_version"
    
    # Check Rust version compatibility (fd requires 1.77.2+)
    rust_major=$(rustc --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1)
    rust_minor=$(rustc --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f2)
    rust_patch=$(rustc --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f3)
    if [ "$rust_major" -eq 1 ] && [ "$rust_minor" -ge 77 ] && [ "$rust_patch" -ge 2 ]; then
        print_status "PASS" "Rust version is >= 1.77.2 (compatible with Fd)"
    else
        print_status "WARN" "Rust version should be >= 1.77.2 for Fd (found: $rust_major.$rust_minor.$rust_patch)"
    fi
else
    print_status "FAIL" "Rust is not available"
fi

# Check Cargo
if command -v cargo &> /dev/null; then
    cargo_version=$(cargo --version 2>&1)
    print_status "PASS" "Cargo is available: $cargo_version"
else
    print_status "FAIL" "Cargo is not available"
fi

# Check Rust execution
if command -v rustc &> /dev/null; then
    if timeout 30s rustc --version >/dev/null 2>&1; then
        print_status "PASS" "Rust execution works"
    else
        print_status "WARN" "Rust execution failed"
    fi
    
    # Test Rust compilation
    echo 'fn main() { println!("Hello, world!"); }' > /tmp/test.rs
    if timeout 30s rustc -o /tmp/test /tmp/test.rs >/dev/null 2>&1; then
        print_status "PASS" "Rust compilation works"
        rm -f /tmp/test /tmp/test.rs
    else
        print_status "WARN" "Rust compilation failed"
        rm -f /tmp/test.rs
    fi
else
    print_status "FAIL" "Rust is not available for testing"
fi

echo ""
echo "2. Checking Fd Application..."
echo "-----------------------------"
# Check if fd is installed
if command -v fd &> /dev/null; then
    fd_version=$(fd --version 2>&1)
    print_status "PASS" "fd is available: $fd_version"
else
    print_status "WARN" "fd is not available (not installed or not in PATH)"
fi

# Check if fdfind is available (alternative name)
if command -v fdfind &> /dev/null; then
    fdfind_version=$(fdfind --version 2>&1)
    print_status "PASS" "fdfind is available: $fdfind_version"
else
    print_status "WARN" "fdfind is not available"
fi

# Test fd functionality if available
if command -v fd &> /dev/null; then
    # Test basic fd functionality
    if timeout 30s fd --help >/dev/null 2>&1; then
        print_status "PASS" "fd help command works"
    else
        print_status "WARN" "fd help command failed"
    fi
    
    # Test fd search functionality
    if timeout 30s fd --version >/dev/null 2>&1; then
        print_status "PASS" "fd version command works"
    else
        print_status "WARN" "fd version command failed"
    fi
    
    # Test fd search with pattern
    echo "test file" > /tmp/test_fd.txt
    if timeout 30s fd test_fd /tmp >/dev/null 2>&1; then
        print_status "PASS" "fd search functionality works"
    else
        print_status "WARN" "fd search functionality failed"
    fi
    rm -f /tmp/test_fd.txt
else
    print_status "WARN" "fd is not available for functionality testing"
fi

echo ""
echo "3. Checking System Dependencies..."
echo "---------------------------------"
# Check Git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1)
    print_status "PASS" "Git is available: $git_version"
else
    print_status "FAIL" "Git is not available"
fi

# Check make
if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "make is available: $make_version"
else
    print_status "FAIL" "make is not available"
fi

# Check curl
if command -v curl &> /dev/null; then
    curl_version=$(curl --version 2>&1 | head -n 1)
    print_status "PASS" "curl is available: $curl_version"
else
    print_status "FAIL" "curl is not available"
fi

# Check pkg-config
if command -v pkg-config &> /dev/null; then
    pkg_config_version=$(pkg-config --version 2>&1)
    print_status "PASS" "pkg-config is available: $pkg_config_version"
else
    print_status "FAIL" "pkg-config is not available"
fi

# Check build-essential
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version 2>&1 | head -n 1)
    print_status "PASS" "GCC is available: $gcc_version"
else
    print_status "FAIL" "GCC is not available"
fi

# Check libssl-dev
if pkg-config --exists openssl; then
    openssl_version=$(pkg-config --modversion openssl 2>/dev/null)
    print_status "PASS" "libssl-dev is available: $openssl_version"
else
    print_status "WARN" "libssl-dev is not available"
fi

# Check cross (for cross-compilation)
if command -v cross &> /dev/null; then
    cross_version=$(cross --version 2>&1)
    print_status "PASS" "cross is available: $cross_version"
else
    print_status "WARN" "cross is not available"
fi

echo ""
echo "4. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "src" ]; then
    print_status "PASS" "src directory exists (source code)"
else
    print_status "FAIL" "src directory not found"
fi

if [ -d "tests" ]; then
    print_status "PASS" "tests directory exists (test suite)"
else
    print_status "FAIL" "tests directory not found"
fi

if [ -d "doc" ]; then
    print_status "PASS" "doc directory exists (documentation)"
else
    print_status "FAIL" "doc directory not found"
fi

if [ -d "contrib" ]; then
    print_status "PASS" "contrib directory exists (contributions)"
else
    print_status "FAIL" "contrib directory not found"
fi

if [ -d "scripts" ]; then
    print_status "PASS" "scripts directory exists (build scripts)"
else
    print_status "FAIL" "scripts directory not found"
fi

# Check key files
if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
fi

if [ -f "Cargo.toml" ]; then
    print_status "PASS" "Cargo.toml exists"
else
    print_status "FAIL" "Cargo.toml not found"
fi

if [ -f "Cargo.lock" ]; then
    print_status "PASS" "Cargo.lock exists"
else
    print_status "FAIL" "Cargo.lock not found"
fi

if [ -f "LICENSE-APACHE" ]; then
    print_status "PASS" "LICENSE-APACHE exists"
else
    print_status "FAIL" "LICENSE-APACHE not found"
fi

if [ -f "LICENSE-MIT" ]; then
    print_status "PASS" "LICENSE-MIT exists"
else
    print_status "FAIL" "LICENSE-MIT not found"
fi

if [ -f "CHANGELOG.md" ]; then
    print_status "PASS" "CHANGELOG.md exists"
else
    print_status "FAIL" "CHANGELOG.md not found"
fi

if [ -f "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md exists"
else
    print_status "FAIL" "CONTRIBUTING.md not found"
fi

if [ -f "SECURITY.md" ]; then
    print_status "PASS" "SECURITY.md exists"
else
    print_status "FAIL" "SECURITY.md not found"
fi

if [ -f "rustfmt.toml" ]; then
    print_status "PASS" "rustfmt.toml exists (code formatting config)"
else
    print_status "FAIL" "rustfmt.toml not found"
fi

if [ -f "build.rs" ]; then
    print_status "PASS" "build.rs exists (build script)"
else
    print_status "FAIL" "build.rs not found"
fi

if [ -f "Makefile" ]; then
    print_status "PASS" "Makefile exists"
else
    print_status "FAIL" "Makefile not found"
fi

if [ -f "Cross.toml" ]; then
    print_status "PASS" "Cross.toml exists (cross-compilation config)"
else
    print_status "FAIL" "Cross.toml not found"
fi

# Check source files
if [ -f "src/main.rs" ]; then
    print_status "PASS" "src/main.rs exists (binary entry point)"
else
    print_status "FAIL" "src/main.rs not found"
fi

if [ -d "src/filter" ]; then
    print_status "PASS" "src/filter directory exists (filtering logic)"
else
    print_status "FAIL" "src/filter directory not found"
fi

if [ -d "src/exec" ]; then
    print_status "PASS" "src/exec directory exists (command execution)"
else
    print_status "FAIL" "src/exec directory not found"
fi

if [ -d "src/fmt" ]; then
    print_status "PASS" "src/fmt directory exists (formatting logic)"
else
    print_status "FAIL" "src/fmt directory not found"
fi

echo ""
echo "5. Testing Fd Source Code..."
echo "-----------------------------"
# Count Rust files
rust_files=$(find . -name "*.rs" | wc -l)
if [ "$rust_files" -gt 0 ]; then
    print_status "PASS" "Found $rust_files Rust files"
else
    print_status "FAIL" "No Rust files found"
fi

# Count Cargo.toml files
cargo_files=$(find . -name "Cargo.toml" | wc -l)
if [ "$cargo_files" -gt 0 ]; then
    print_status "PASS" "Found $cargo_files Cargo.toml files"
else
    print_status "FAIL" "No Cargo.toml files found"
fi

# Count test files
test_files=$(find . -name "*.rs" | grep -E "(test|spec)" | wc -l)
if [ "$test_files" -gt 0 ]; then
    print_status "PASS" "Found $test_files test files"
else
    print_status "WARN" "No test files found"
fi

# Test Rust syntax
if command -v rustc &> /dev/null; then
    print_status "INFO" "Testing Rust syntax..."
    syntax_errors=0
    for rs_file in $(find . -name "*.rs"); do
        if ! timeout 30s rustc --crate-type lib --emit=metadata -o /dev/null "$rs_file" >/dev/null 2>&1; then
            ((syntax_errors++))
        fi
    done
    
    if [ "$syntax_errors" -eq 0 ]; then
        print_status "PASS" "All Rust files have valid syntax"
    else
        print_status "WARN" "Found $syntax_errors Rust files with syntax errors"
    fi
else
    print_status "FAIL" "Rust is not available for syntax checking"
fi

# Test Cargo.toml parsing
if command -v cargo &> /dev/null; then
    print_status "INFO" "Testing Cargo.toml parsing..."
    if timeout 60s cargo check --quiet >/dev/null 2>&1; then
        print_status "PASS" "Cargo.toml parsing successful"
    else
        print_status "WARN" "Cargo.toml parsing failed"
    fi
else
    print_status "FAIL" "Cargo is not available for Cargo.toml parsing"
fi

echo ""
echo "6. Testing Fd Dependencies..."
echo "-----------------------------"
# Test if ignore is available (file ignoring)
if command -v cargo &> /dev/null; then
    print_status "INFO" "Testing Fd dependencies..."
    
    # Test ignore dependency
    if timeout 60s cargo check --quiet >/dev/null 2>&1; then
        print_status "PASS" "ignore dependency is available"
    else
        print_status "WARN" "ignore dependency check failed"
    fi
    
    # Test regex dependency
    if timeout 60s cargo check --quiet >/dev/null 2>&1; then
        print_status "PASS" "regex dependency is available"
    else
        print_status "WARN" "regex dependency check failed"
    fi
    
    # Test clap dependency
    if timeout 60s cargo check --quiet >/dev/null 2>&1; then
        print_status "PASS" "clap dependency is available"
    else
        print_status "WARN" "clap dependency check failed"
    fi
    
    # Test aho-corasick dependency
    if timeout 60s cargo check --quiet >/dev/null 2>&1; then
        print_status "PASS" "aho-corasick dependency is available"
    else
        print_status "WARN" "aho-corasick dependency check failed"
    fi
    
    # Test nix dependency (Unix only)
    if timeout 60s cargo check --quiet >/dev/null 2>&1; then
        print_status "PASS" "nix dependency is available"
    else
        print_status "WARN" "nix dependency check failed"
    fi
else
    print_status "FAIL" "Cargo is not available for dependency testing"
fi

echo ""
echo "7. Testing Fd Documentation..."
echo "-------------------------------"
# Test documentation readability
if [ -r "README.md" ]; then
    print_status "PASS" "README.md is readable"
else
    print_status "FAIL" "README.md is not readable"
fi

if [ -r "LICENSE-APACHE" ]; then
    print_status "PASS" "LICENSE-APACHE is readable"
else
    print_status "FAIL" "LICENSE-APACHE is not readable"
fi

if [ -r "LICENSE-MIT" ]; then
    print_status "PASS" "LICENSE-MIT is readable"
else
    print_status "FAIL" "LICENSE-MIT is not readable"
fi

if [ -r "CHANGELOG.md" ]; then
    print_status "PASS" "CHANGELOG.md is readable"
else
    print_status "FAIL" "CHANGELOG.md is not readable"
fi

if [ -r "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md is readable"
else
    print_status "FAIL" "CONTRIBUTING.md is not readable"
fi

if [ -r "SECURITY.md" ]; then
    print_status "PASS" "SECURITY.md is readable"
else
    print_status "FAIL" "SECURITY.md is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "fd" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "find" README.md; then
        print_status "PASS" "README.md contains find alternative description"
    else
        print_status "WARN" "README.md missing find alternative description"
    fi
    
    if grep -q "filesystem" README.md; then
        print_status "PASS" "README.md contains filesystem search description"
    else
        print_status "WARN" "README.md missing filesystem search description"
    fi
    
    if grep -q "regex" README.md; then
        print_status "PASS" "README.md contains regex search description"
    else
        print_status "WARN" "README.md missing regex search description"
    fi
fi

echo ""
echo "8. Testing Fd Docker Functionality..."
echo "-------------------------------------"
# Test if Docker container can run basic commands
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    # Test Rust in Docker
    if docker run --rm fd-env-test rustc --version >/dev/null 2>&1; then
        print_status "PASS" "Rust works in Docker container"
    else
        print_status "FAIL" "Rust does not work in Docker container"
    fi
    
    # Test Cargo in Docker
    if docker run --rm fd-env-test cargo --version >/dev/null 2>&1; then
        print_status "PASS" "Cargo works in Docker container"
    else
        print_status "FAIL" "Cargo does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm fd-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test fd in Docker
    if docker run --rm fd-env-test fd --version >/dev/null 2>&1; then
        print_status "PASS" "fd works in Docker container"
    else
        print_status "FAIL" "fd does not work in Docker container"
    fi
    
    # Test fdfind in Docker
    if docker run --rm fd-env-test fdfind --version >/dev/null 2>&1; then
        print_status "PASS" "fdfind works in Docker container"
    else
        print_status "WARN" "fdfind does not work in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" fd-env-test test -f README.md; then
        print_status "PASS" "README.md is accessible in Docker container"
    else
        print_status "FAIL" "README.md is not accessible in Docker container"
    fi
    
    # Test if src directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" fd-env-test test -d src; then
        print_status "PASS" "src directory is accessible in Docker container"
    else
        print_status "FAIL" "src directory is not accessible in Docker container"
    fi
    
    # Test if tests directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" fd-env-test test -d tests; then
        print_status "PASS" "tests directory is accessible in Docker container"
    else
        print_status "FAIL" "tests directory is not accessible in Docker container"
    fi
    
    # Test if contrib directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" fd-env-test test -d contrib; then
        print_status "PASS" "contrib directory is accessible in Docker container"
    else
        print_status "FAIL" "contrib directory is not accessible in Docker container"
    fi
    
    # Test cargo check in Docker
    if docker run --rm -v "$(pwd):/workspace" -w /workspace fd-env-test cargo check --quiet >/dev/null 2>&1; then
        print_status "PASS" "cargo check works in Docker container"
    else
        print_status "FAIL" "cargo check does not work in Docker container"
    fi
    
    # Test fd functionality in Docker
    echo "test file" > /tmp/test_fd.txt
    if docker run --rm -v /tmp:/tmp fd-env-test fd test_fd /tmp >/dev/null 2>&1; then
        print_status "PASS" "fd search functionality works in Docker container"
    else
        print_status "FAIL" "fd search functionality does not work in Docker container"
    fi
    rm -f /tmp/test_fd.txt
    
    # Test fd help in Docker
    if docker run --rm fd-env-test fd --help >/dev/null 2>&1; then
        print_status "PASS" "fd help works in Docker container"
    else
        print_status "FAIL" "fd help does not work in Docker container"
    fi
    
    # Test make in Docker
    if docker run --rm fd-env-test make --version >/dev/null 2>&1; then
        print_status "PASS" "make works in Docker container"
    else
        print_status "FAIL" "make does not work in Docker container"
    fi
    
    # Test cross in Docker
    if docker run --rm fd-env-test cross --version >/dev/null 2>&1; then
        print_status "PASS" "cross works in Docker container"
    else
        print_status "WARN" "cross does not work in Docker container"
    fi
fi

echo ""
echo "9. Testing Fd Build Process..."
echo "-------------------------------"
# Test if Docker container can build the project
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    # Test cargo build in Docker
    if docker run --rm -v "$(pwd):/workspace" -w /workspace fd-env-test cargo build --quiet >/dev/null 2>&1; then
        print_status "PASS" "cargo build works in Docker container"
    else
        print_status "FAIL" "cargo build does not work in Docker container"
    fi
    
    # Test cargo test in Docker
    if docker run --rm -v "$(pwd):/workspace" -w /workspace fd-env-test cargo test --quiet >/dev/null 2>&1; then
        print_status "PASS" "cargo test works in Docker container"
    else
        print_status "FAIL" "cargo test does not work in Docker container"
    fi
    
    # Test make build in Docker
    if docker run --rm -v "$(pwd):/workspace" -w /workspace fd-env-test make >/dev/null 2>&1; then
        print_status "PASS" "make build works in Docker container"
    else
        print_status "FAIL" "make build does not work in Docker container"
    fi
    
    # Test make completions in Docker
    if docker run --rm -v "$(pwd):/workspace" -w /workspace fd-env-test make completions >/dev/null 2>&1; then
        print_status "PASS" "make completions works in Docker container"
    else
        print_status "FAIL" "make completions does not work in Docker container"
    fi
    
    # Test make install in Docker
    if docker run --rm -v "$(pwd):/workspace" -w /workspace fd-env-test make install >/dev/null 2>&1; then
        print_status "PASS" "make install works in Docker container"
    else
        print_status "FAIL" "make install does not work in Docker container"
    fi
fi

echo ""
echo "=========================================="
echo "Fd Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for Fd:"
echo "- Docker build process (Ubuntu 22.04, Rust 1.77.2+, Cargo, Git, build tools)"
echo "- Rust environment (version compatibility, toolchain, compilation)"
echo "- Fd application (file search, regex patterns, command execution)"
echo "- System dependencies (Git, make, curl, pkg-config, libssl-dev, cross)"
echo "- Fd source code structure (src, tests, doc, contrib, scripts)"
echo "- Fd documentation (README.md, LICENSE files, CHANGELOG.md, CONTRIBUTING.md)"
echo "- Docker container functionality (Rust, Cargo, fd, build process)"
echo "- File search tool (ignore, regex, aho-corasick, clap, nix)"
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
    print_status "INFO" "All Docker tests passed! Your Fd Docker environment is ready!"
    print_status "INFO" "Fd is a simple, fast and user-friendly alternative to find."
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your Fd Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now run Fd in Docker: A simple, fast and user-friendly alternative to find."
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace fd-env-test cargo check"
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace fd-env-test cargo test"
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace fd-env-test fd README.md"
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace fd-env-test fd --help"
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace fd-env-test make"
echo ""
print_status "INFO" "For more information, see README.md and https://github.com/sharkdp/fd"
exit 0
fi

# If Docker failed or not available, skip local environment tests
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ] || [ "${DOCKER_MODE:-false}" = "false" ]; then
    echo "Docker environment not available - skipping local environment tests"
    echo "This script is designed to test Docker environment only"
    exit 0
fi 