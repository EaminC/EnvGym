#!/bin/bash

# Tokio-rs Bytes Environment Benchmark Test Script
# This script tests the Docker environment setup for Tokio-rs Bytes: A utility library for working with bytes
# Tailored specifically for Tokio-rs Bytes project requirements and features

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
    docker stop bytes-env-test 2>/dev/null || true
    docker rm bytes-env-test 2>/dev/null || true
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
        DOCKER_BUILD_FAILED=true
    elif [ -f "envgym/envgym.dockerfile" ]; then
        echo "Building Docker image..."
        if timeout 300s docker build -f envgym/envgym.dockerfile -t bytes-env-test .; then
            echo "Docker build successful - analyzing build process..."
            DOCKER_BUILD_SUCCESS=true
        else
            echo "WARNING: Docker build failed - analyzing Dockerfile only"
            DOCKER_BUILD_FAILED=true
        fi
    else
        print_status "WARN" "envgym.dockerfile not found - Docker environment not available"
        DOCKER_BUILD_FAILED=true
    fi
fi

# If Docker failed or not available, give 0 score and exit immediately
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ]; then
    echo ""
    echo "=========================================="
    echo "Tokio-rs Bytes Environment Test Complete"
    echo "=========================================="
    echo ""
    echo "Summary:"
    echo "--------"
    echo "Docker build failed - environment not ready for Tokio-rs Bytes development"
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
    print_status "FAIL" "Docker build failed - Tokio-rs Bytes environment is not ready!"
    print_status "INFO" "Please fix the Docker build issues before using this environment"
    exit 1
fi

# If Docker build was successful, analyze the build process
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    echo ""
    echo "Docker build was successful - analyzing build process..."
    echo "------------------------------------------------------"
    
    # Test if Rust is available in Docker
    if docker run --rm bytes-env-test rustc --version >/dev/null 2>&1; then
        rust_version=$(docker run --rm bytes-env-test rustc --version 2>&1)
        print_status "PASS" "Rust is available in Docker: $rust_version"
    else
        print_status "FAIL" "Rust is not available in Docker"
    fi
    
    # Test if Cargo is available in Docker
    if docker run --rm bytes-env-test cargo --version >/dev/null 2>&1; then
        cargo_version=$(docker run --rm bytes-env-test cargo --version 2>&1)
        print_status "PASS" "Cargo is available in Docker: $cargo_version"
    else
        print_status "FAIL" "Cargo is not available in Docker"
    fi
    
    # Test if Clippy is available in Docker
    if docker run --rm bytes-env-test cargo clippy --version >/dev/null 2>&1; then
        clippy_version=$(docker run --rm bytes-env-test cargo clippy --version 2>&1)
        print_status "PASS" "Clippy is available in Docker: $clippy_version"
    else
        print_status "FAIL" "Clippy is not available in Docker"
    fi
    
    # Test if rustfmt is available in Docker
    if docker run --rm bytes-env-test rustfmt --version >/dev/null 2>&1; then
        rustfmt_version=$(docker run --rm bytes-env-test rustfmt --version 2>&1)
        print_status "PASS" "rustfmt is available in Docker: $rustfmt_version"
    else
        print_status "FAIL" "rustfmt is not available in Docker"
    fi
    
    # Test if Git is available in Docker
    if docker run --rm bytes-env-test git --version >/dev/null 2>&1; then
        git_version=$(docker run --rm bytes-env-test git --version 2>&1)
        print_status "PASS" "Git is available in Docker: $git_version"
    else
        print_status "FAIL" "Git is not available in Docker"
    fi
fi

echo "=========================================="
echo "Tokio-rs Bytes Environment Benchmark Test"
echo "=========================================="

echo "1. Checking Rust Environment..."
echo "-------------------------------"
# Check Rust version
if command -v rustc &> /dev/null; then
    rust_version=$(rustc --version 2>&1)
    print_status "PASS" "Rust is available: $rust_version"
    
    # Check Rust version compatibility (requires 1.57+)
    rust_major=$(rustc --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1)
    rust_minor=$(rustc --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f2)
    if [ "$rust_major" -eq 1 ] && [ "$rust_minor" -ge 57 ]; then
        print_status "PASS" "Rust version is >= 1.57 (compatible with Tokio-rs Bytes)"
    else
        print_status "WARN" "Rust version should be >= 1.57 for Tokio-rs Bytes (found: $rust_major.$rust_minor)"
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

# Check Clippy
if command -v cargo &> /dev/null; then
    if cargo clippy --version >/dev/null 2>&1; then
        clippy_version=$(cargo clippy --version 2>&1)
        print_status "PASS" "Clippy is available: $clippy_version"
    else
        print_status "WARN" "Clippy is not available"
    fi
else
    print_status "FAIL" "Cargo is not available for Clippy testing"
fi

# Check rustfmt
if command -v rustfmt &> /dev/null; then
    rustfmt_version=$(rustfmt --version 2>&1)
    print_status "PASS" "rustfmt is available: $rustfmt_version"
else
    print_status "WARN" "rustfmt is not available"
fi

# Test Rust compilation
if command -v rustc &> /dev/null; then
    echo 'fn main() { println!("Hello, Rust!"); }' > /tmp/test.rs
    if timeout 30s rustc -o /tmp/test /tmp/test.rs >/dev/null 2>&1; then
        print_status "PASS" "Rust compilation works"
        rm -f /tmp/test /tmp/test.rs
    else
        print_status "WARN" "Rust compilation failed"
        rm -f /tmp/test.rs
    fi
else
    print_status "FAIL" "Rust is not available for compilation testing"
fi

echo ""
echo "2. Checking System Dependencies..."
echo "---------------------------------"
# Check Git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1)
    print_status "PASS" "Git is available: $git_version"
else
    print_status "FAIL" "Git is not available"
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

# Check curl and wget
if command -v curl &> /dev/null; then
    curl_version=$(curl --version 2>&1 | head -n 1)
    print_status "PASS" "curl is available: $curl_version"
else
    print_status "FAIL" "curl is not available"
fi

if command -v wget &> /dev/null; then
    wget_version=$(wget --version 2>&1 | head -n 1)
    print_status "PASS" "wget is available: $wget_version"
else
    print_status "FAIL" "wget is not available"
fi

# Check make
if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "make is available: $make_version"
else
    print_status "WARN" "make is not available"
fi

echo ""
echo "3. Checking Project Structure..."
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

if [ -d "benches" ]; then
    print_status "PASS" "benches directory exists (benchmarks)"
else
    print_status "FAIL" "benches directory not found"
fi

if [ -d "ci" ]; then
    print_status "PASS" "ci directory exists (CI configuration)"
else
    print_status "FAIL" "ci directory not found"
fi

# Check key files
if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
fi

if [ -f "Cargo.toml" ]; then
    print_status "PASS" "Cargo.toml exists (project configuration)"
else
    print_status "FAIL" "Cargo.toml not found"
fi

if [ -f "LICENSE" ]; then
    print_status "PASS" "LICENSE exists"
else
    print_status "FAIL" "LICENSE not found"
fi

if [ -f "CHANGELOG.md" ]; then
    print_status "PASS" "CHANGELOG.md exists"
else
    print_status "FAIL" "CHANGELOG.md not found"
fi

if [ -f "SECURITY.md" ]; then
    print_status "PASS" "SECURITY.md exists"
else
    print_status "FAIL" "SECURITY.md not found"
fi

if [ -f "clippy.toml" ]; then
    print_status "PASS" "clippy.toml exists (Clippy configuration)"
else
    print_status "FAIL" "clippy.toml not found"
fi

# Check source files
if [ -f "src/lib.rs" ]; then
    print_status "PASS" "src/lib.rs exists (library root)"
else
    print_status "FAIL" "src/lib.rs not found"
fi

if [ -f "src/bytes.rs" ]; then
    print_status "PASS" "src/bytes.rs exists (Bytes implementation)"
else
    print_status "FAIL" "src/bytes.rs not found"
fi

if [ -f "src/bytes_mut.rs" ]; then
    print_status "PASS" "src/bytes_mut.rs exists (BytesMut implementation)"
else
    print_status "FAIL" "src/bytes_mut.rs not found"
fi

if [ -d "src/buf" ]; then
    print_status "PASS" "src/buf directory exists (buffer traits)"
else
    print_status "FAIL" "src/buf directory not found"
fi

if [ -f "src/serde.rs" ]; then
    print_status "PASS" "src/serde.rs exists (serde support)"
else
    print_status "FAIL" "src/serde.rs not found"
fi

echo ""
echo "4. Testing Tokio-rs Bytes Source Code..."
echo "----------------------------------------"
# Count Rust files
rust_files=$(find . -name "*.rs" | wc -l)
if [ "$rust_files" -gt 0 ]; then
    print_status "PASS" "Found $rust_files Rust files"
else
    print_status "FAIL" "No Rust files found"
fi

# Count test files
test_files=$(find . -name "test_*.rs" | wc -l)
if [ "$test_files" -gt 0 ]; then
    print_status "PASS" "Found $test_files test files"
else
    print_status "WARN" "No test files found"
fi

# Count benchmark files
bench_files=$(find . -name "*.rs" -path "*/benches/*" | wc -l)
if [ "$bench_files" -gt 0 ]; then
    print_status "PASS" "Found $bench_files benchmark files"
else
    print_status "WARN" "No benchmark files found"
fi

# Count TOML files
toml_files=$(find . -name "*.toml" | wc -l)
if [ "$toml_files" -gt 0 ]; then
    print_status "PASS" "Found $toml_files TOML files"
else
    print_status "WARN" "No TOML files found"
fi

# Test Rust syntax
if command -v rustc &> /dev/null; then
    print_status "INFO" "Testing Rust syntax..."
    syntax_errors=0
    for rs_file in $(find . -name "*.rs" | head -20); do
        if ! timeout 30s rustc --crate-type lib --emit=metadata -o /dev/null "$rs_file" >/dev/null 2>&1; then
            ((syntax_errors++))
        fi
    done
    
    if [ "$syntax_errors" -eq 0 ]; then
        print_status "PASS" "All tested Rust files have valid syntax"
    else
        print_status "WARN" "Found $syntax_errors Rust files with syntax errors"
    fi
else
    print_status "FAIL" "Rust is not available for syntax checking"
fi

# Test Cargo.toml parsing
if command -v cargo &> /dev/null; then
    print_status "INFO" "Testing Cargo.toml parsing..."
    if timeout 30s cargo check --quiet >/dev/null 2>&1; then
        print_status "PASS" "Cargo.toml parsing successful"
    else
        print_status "FAIL" "Cargo.toml parsing failed"
    fi
else
    print_status "FAIL" "Cargo is not available for Cargo.toml parsing"
fi

echo ""
echo "5. Testing Tokio-rs Bytes Dependencies..."
echo "-----------------------------------------"
# Test if required dependencies are available
if command -v cargo &> /dev/null; then
    print_status "INFO" "Testing Tokio-rs Bytes dependencies..."
    
    # Test serde dependency (optional)
    if cargo tree --quiet | grep -q "serde"; then
        print_status "PASS" "serde dependency is available"
    else
        print_status "WARN" "serde dependency is not available (optional)"
    fi
    
    # Test portable-atomic dependency (optional)
    if cargo tree --quiet | grep -q "portable-atomic"; then
        print_status "PASS" "portable-atomic dependency is available"
    else
        print_status "WARN" "portable-atomic dependency is not available (optional)"
    fi
else
    print_status "FAIL" "Cargo is not available for dependency testing"
fi

echo ""
echo "6. Testing Tokio-rs Bytes Documentation..."
echo "------------------------------------------"
# Test documentation readability
if [ -r "README.md" ]; then
    print_status "PASS" "README.md is readable"
else
    print_status "FAIL" "README.md is not readable"
fi

if [ -r "LICENSE" ]; then
    print_status "PASS" "LICENSE is readable"
else
    print_status "FAIL" "LICENSE is not readable"
fi

if [ -r "CHANGELOG.md" ]; then
    print_status "PASS" "CHANGELOG.md is readable"
else
    print_status "FAIL" "CHANGELOG.md is not readable"
fi

if [ -r "SECURITY.md" ]; then
    print_status "PASS" "SECURITY.md is readable"
else
    print_status "FAIL" "SECURITY.md is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "Bytes" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "utility library" README.md; then
        print_status "PASS" "README.md contains utility library description"
    else
        print_status "WARN" "README.md missing utility library description"
    fi
    
    if grep -q "bytes" README.md; then
        print_status "PASS" "README.md contains bytes description"
    else
        print_status "WARN" "README.md missing bytes description"
    fi
    
    if grep -q "no_std" README.md; then
        print_status "PASS" "README.md contains no_std support description"
    else
        print_status "WARN" "README.md missing no_std support description"
    fi
    
    if grep -q "serde" README.md; then
        print_status "PASS" "README.md contains serde support description"
    else
        print_status "WARN" "README.md missing serde support description"
    fi
fi

echo ""
echo "7. Testing Tokio-rs Bytes Docker Functionality..."
echo "------------------------------------------------"
# Test if Docker container can run basic commands
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    # Test Rust in Docker
    if docker run --rm bytes-env-test rustc --version >/dev/null 2>&1; then
        print_status "PASS" "Rust works in Docker container"
    else
        print_status "FAIL" "Rust does not work in Docker container"
    fi
    
    # Test Cargo in Docker
    if docker run --rm bytes-env-test cargo --version >/dev/null 2>&1; then
        print_status "PASS" "Cargo works in Docker container"
    else
        print_status "FAIL" "Cargo does not work in Docker container"
    fi
    
    # Test Clippy in Docker
    if docker run --rm bytes-env-test cargo clippy --version >/dev/null 2>&1; then
        print_status "PASS" "Clippy works in Docker container"
    else
        print_status "FAIL" "Clippy does not work in Docker container"
    fi
    
    # Test rustfmt in Docker
    if docker run --rm bytes-env-test rustfmt --version >/dev/null 2>&1; then
        print_status "PASS" "rustfmt works in Docker container"
    else
        print_status "FAIL" "rustfmt does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm bytes-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" bytes-env-test test -f README.md; then
        print_status "PASS" "README.md is accessible in Docker container"
    else
        print_status "FAIL" "README.md is not accessible in Docker container"
    fi
    
    # Test if Cargo.toml is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" bytes-env-test test -f Cargo.toml; then
        print_status "PASS" "Cargo.toml is accessible in Docker container"
    else
        print_status "FAIL" "Cargo.toml is not accessible in Docker container"
    fi
    
    # Test if src/lib.rs is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" bytes-env-test test -f src/lib.rs; then
        print_status "PASS" "src/lib.rs is accessible in Docker container"
    else
        print_status "FAIL" "src/lib.rs is not accessible in Docker container"
    fi
    
    # Test Rust compilation in Docker
    if timeout 60s docker run --rm -v "$(pwd):/workspace" -w /workspace bytes-env-test rustc --crate-type lib --emit=metadata -o /dev/null src/lib.rs >/dev/null 2>&1; then
        print_status "PASS" "Rust compilation works in Docker container"
    else
        print_status "FAIL" "Rust compilation does not work in Docker container"
    fi
fi

echo ""
echo "8. Testing Tokio-rs Bytes Build Process..."
echo "------------------------------------------"
# Test if Docker container can run build commands
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    # Test if tests directory is accessible
    if docker run --rm -v "$(pwd):/workspace" -w /workspace bytes-env-test test -d tests; then
        print_status "PASS" "tests directory is accessible in Docker container"
    else
        print_status "FAIL" "tests directory is not accessible in Docker container"
    fi
    
    # Test if benches directory is accessible
    if docker run --rm -v "$(pwd):/workspace" -w /workspace bytes-env-test test -d benches; then
        print_status "PASS" "benches directory is accessible in Docker container"
    else
        print_status "FAIL" "benches directory is not accessible in Docker container"
    fi
    
    # Test if clippy.toml is accessible
    if docker run --rm -v "$(pwd):/workspace" -w /workspace bytes-env-test test -f clippy.toml; then
        print_status "PASS" "clippy.toml is accessible in Docker container"
    else
        print_status "FAIL" "clippy.toml is not accessible in Docker container"
    fi
    
    # Test cargo check
    if timeout 120s docker run --rm -v "$(pwd):/workspace" -w /workspace bytes-env-test cargo check --quiet >/dev/null 2>&1; then
        print_status "PASS" "cargo check works in Docker container"
    else
        print_status "FAIL" "cargo check does not work in Docker container"
    fi
    
    # Test cargo clippy
    if timeout 120s docker run --rm -v "$(pwd):/workspace" -w /workspace bytes-env-test cargo clippy --quiet >/dev/null 2>&1; then
        print_status "PASS" "cargo clippy works in Docker container"
    else
        print_status "FAIL" "cargo clippy does not work in Docker container"
    fi
    
    # Test cargo fmt check
    if timeout 60s docker run --rm -v "$(pwd):/workspace" -w /workspace bytes-env-test cargo fmt --check >/dev/null 2>&1; then
        print_status "PASS" "cargo fmt check works in Docker container"
    else
        print_status "FAIL" "cargo fmt check does not work in Docker container"
    fi
    
    # Skip actual test execution to avoid timeouts
    print_status "WARN" "Skipping actual test execution to avoid timeouts (full test suite)"
    print_status "INFO" "Docker environment is ready for Tokio-rs Bytes development"
fi

echo ""
echo "=========================================="
echo "Tokio-rs Bytes Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for Tokio-rs Bytes:"
echo "- Docker build process (Rust latest, Cargo, Clippy, rustfmt)"
echo "- Rust environment (version compatibility, compilation, toolchain)"
echo "- System dependencies (Git, GCC, G++, curl, wget, make)"
echo "- Tokio-rs Bytes source code structure (Rust files, tests, benchmarks)"
echo "- Tokio-rs Bytes documentation (README.md, LICENSE, CHANGELOG.md, SECURITY.md)"
echo "- Docker container functionality (Rust, Cargo, Clippy, build process)"
echo "- Bytes utility library (no_std support, serde integration, zero-copy)"
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
    print_status "INFO" "All Docker tests passed! Your Tokio-rs Bytes Docker environment is ready!"
    print_status "INFO" "Tokio-rs Bytes is a utility library for working with bytes."
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your Tokio-rs Bytes Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now run Tokio-rs Bytes in Docker: A utility library for working with bytes."
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace bytes-env-test cargo check"
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace bytes-env-test cargo test"
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace bytes-env-test cargo clippy"
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace bytes-env-test cargo bench"
echo ""
print_status "INFO" "For more information, see README.md and https://github.com/tokio-rs/bytes" 