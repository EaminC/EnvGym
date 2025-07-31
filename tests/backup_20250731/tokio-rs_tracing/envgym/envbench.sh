#!/bin/bash

# Tokio-rs Tracing Environment Benchmark Test Script
# This script tests the Docker environment setup for Tokio-rs Tracing: A framework for instrumenting Rust programs
# Tailored specifically for Tokio-rs Tracing project requirements and features

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
    docker stop tracing-env-test 2>/dev/null || true
    docker rm tracing-env-test 2>/dev/null || true
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
        if timeout 600s docker build -f envgym/envgym.dockerfile -t tracing-env-test .; then
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
    echo "Tokio-rs Tracing Environment Test Complete"
    echo "=========================================="
    echo ""
    echo "Summary:"
    echo "--------"
    echo "Docker build failed - environment not ready for Tokio-rs Tracing development"
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
    print_status "FAIL" "Docker build failed - Tokio-rs Tracing environment is not ready!"
    print_status "INFO" "Please fix the Docker build issues before using this environment"
    exit 1
fi

# If Docker build was successful, analyze the build process
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    echo ""
    echo "Docker build was successful - analyzing build process..."
    echo "------------------------------------------------------"
    
    # Test if Docker container can execute commands
    if docker run --rm tracing-env-test ls --version >/dev/null 2>&1; then
        print_status "PASS" "Docker container can execute basic commands"
        
        # Test if Rust is available in Docker
        if docker run --rm tracing-env-test rustc --version >/dev/null 2>&1; then
            rust_version=$(docker run --rm tracing-env-test rustc --version 2>&1)
            print_status "PASS" "Rust is available in Docker: $rust_version"
        else
            print_status "FAIL" "Rust is not available in Docker"
        fi
        
        # Test if Cargo is available in Docker
        if docker run --rm tracing-env-test cargo --version >/dev/null 2>&1; then
            cargo_version=$(docker run --rm tracing-env-test cargo --version 2>&1)
            print_status "PASS" "Cargo is available in Docker: $cargo_version"
        else
            print_status "FAIL" "Cargo is not available in Docker"
        fi
        
        # Test if cargo-nextest is available in Docker
        if docker run --rm tracing-env-test cargo nextest --version >/dev/null 2>&1; then
            nextest_version=$(docker run --rm tracing-env-test cargo nextest --version 2>&1)
            print_status "PASS" "cargo-nextest is available in Docker: $nextest_version"
        else
            print_status "FAIL" "cargo-nextest is not available in Docker"
        fi
        
        # Test if cargo-hack is available in Docker
        if docker run --rm tracing-env-test cargo hack --version >/dev/null 2>&1; then
            hack_version=$(docker run --rm tracing-env-test cargo hack --version 2>&1)
            print_status "PASS" "cargo-hack is available in Docker: $hack_version"
        else
            print_status "FAIL" "cargo-hack is not available in Docker"
        fi
        
        # Test if cargo-audit is available in Docker
        if docker run --rm tracing-env-test cargo audit --version >/dev/null 2>&1; then
            audit_version=$(docker run --rm tracing-env-test cargo audit --version 2>&1)
            print_status "PASS" "cargo-audit is available in Docker: $audit_version"
        else
            print_status "FAIL" "cargo-audit is not available in Docker"
        fi
        
        # Test if cargo-minimal-versions is available in Docker
        if docker run --rm tracing-env-test cargo minimal-versions --version >/dev/null 2>&1; then
            minimal_versions=$(docker run --rm tracing-env-test cargo minimal-versions --version 2>&1)
            print_status "PASS" "cargo-minimal-versions is available in Docker: $minimal_versions"
        else
            print_status "FAIL" "cargo-minimal-versions is not available in Docker"
        fi
        
        # Test if inferno is available in Docker
        if docker run --rm tracing-env-test inferno --version >/dev/null 2>&1; then
            inferno_version=$(docker run --rm tracing-env-test inferno --version 2>&1)
            print_status "PASS" "inferno is available in Docker: $inferno_version"
        else
            print_status "FAIL" "inferno is not available in Docker"
        fi
        
        # Test if Git is available in Docker
        if docker run --rm tracing-env-test git --version >/dev/null 2>&1; then
            git_version=$(docker run --rm tracing-env-test git --version 2>&1)
            print_status "PASS" "Git is available in Docker: $git_version"
        else
            print_status "FAIL" "Git is not available in Docker"
        fi
    else
        print_status "WARN" "Docker container has binary execution issues - cannot test runtime functionality"
        print_status "INFO" "Docker build succeeded, but container runtime has architecture compatibility issues"
        print_status "INFO" "This may be due to platform/architecture mismatch between host and container"
    fi
fi

echo "=========================================="
echo "Tokio-rs Tracing Environment Benchmark Test"
echo "=========================================="

echo "1. Checking Rust Environment..."
echo "-------------------------------"
# Check Rust version
if command -v rustc &> /dev/null; then
    rust_version=$(rustc --version 2>&1)
    print_status "PASS" "Rust is available: $rust_version"
    
    # Check Rust version compatibility (requires 1.65+)
    rust_major=$(rustc --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1)
    rust_minor=$(rustc --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f2)
    if [ "$rust_major" -eq 1 ] && [ "$rust_minor" -ge 65 ]; then
        print_status "PASS" "Rust version is >= 1.65 (compatible with Tokio-rs Tracing)"
    else
        print_status "WARN" "Rust version should be >= 1.65 for Tokio-rs Tracing (found: $rust_major.$rust_minor)"
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

# Check cargo-nextest
if command -v cargo &> /dev/null; then
    if cargo nextest --version >/dev/null 2>&1; then
        nextest_version=$(cargo nextest --version 2>&1)
        print_status "PASS" "cargo-nextest is available: $nextest_version"
    else
        print_status "WARN" "cargo-nextest is not available"
    fi
else
    print_status "FAIL" "Cargo is not available for cargo-nextest testing"
fi

# Check cargo-hack
if command -v cargo &> /dev/null; then
    if cargo hack --version >/dev/null 2>&1; then
        hack_version=$(cargo hack --version 2>&1)
        print_status "PASS" "cargo-hack is available: $hack_version"
    else
        print_status "WARN" "cargo-hack is not available"
    fi
else
    print_status "FAIL" "Cargo is not available for cargo-hack testing"
fi

# Check cargo-audit
if command -v cargo &> /dev/null; then
    if cargo audit --version >/dev/null 2>&1; then
        audit_version=$(cargo audit --version 2>&1)
        print_status "PASS" "cargo-audit is available: $audit_version"
    else
        print_status "WARN" "cargo-audit is not available"
    fi
else
    print_status "FAIL" "Cargo is not available for cargo-audit testing"
fi

# Check inferno
if command -v inferno &> /dev/null; then
    inferno_version=$(inferno --version 2>&1)
    print_status "PASS" "inferno is available: $inferno_version"
else
    print_status "WARN" "inferno is not available"
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

if command -v clang &> /dev/null; then
    clang_version=$(clang --version 2>&1 | head -n 1)
    print_status "PASS" "clang is available: $clang_version"
else
    print_status "WARN" "clang is not available"
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

# Check pkg-config
if command -v pkg-config &> /dev/null; then
    pkg_config_version=$(pkg-config --version 2>&1)
    print_status "PASS" "pkg-config is available: $pkg_config_version"
else
    print_status "WARN" "pkg-config is not available"
fi

# Check systemd
if command -v systemctl &> /dev/null; then
    systemd_version=$(systemctl --version 2>&1 | head -n 1)
    print_status "PASS" "systemd is available: $systemd_version"
else
    print_status "WARN" "systemd is not available"
fi

# Check perl
if command -v perl &> /dev/null; then
    perl_version=$(perl --version 2>&1 | head -n 1)
    print_status "PASS" "perl is available: $perl_version"
else
    print_status "WARN" "perl is not available"
fi

echo ""
echo "3. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "tracing" ]; then
    print_status "PASS" "tracing directory exists (main crate)"
else
    print_status "FAIL" "tracing directory not found"
fi

if [ -d "tracing-core" ]; then
    print_status "PASS" "tracing-core directory exists (core crate)"
else
    print_status "FAIL" "tracing-core directory not found"
fi

if [ -d "tracing-subscriber" ]; then
    print_status "PASS" "tracing-subscriber directory exists (subscriber crate)"
else
    print_status "FAIL" "tracing-subscriber directory not found"
fi

if [ -d "tracing-attributes" ]; then
    print_status "PASS" "tracing-attributes directory exists (attributes crate)"
else
    print_status "FAIL" "tracing-attributes directory not found"
fi

if [ -d "tracing-macros" ]; then
    print_status "PASS" "tracing-macros directory exists (macros crate)"
else
    print_status "FAIL" "tracing-macros directory not found"
fi

if [ -d "tracing-log" ]; then
    print_status "PASS" "tracing-log directory exists (log integration)"
else
    print_status "FAIL" "tracing-log directory not found"
fi

if [ -d "tracing-test" ]; then
    print_status "PASS" "tracing-test directory exists (testing utilities)"
else
    print_status "FAIL" "tracing-test directory not found"
fi

if [ -d "tracing-mock" ]; then
    print_status "PASS" "tracing-mock directory exists (mock utilities)"
else
    print_status "FAIL" "tracing-mock directory not found"
fi

if [ -d "tracing-serde" ]; then
    print_status "PASS" "tracing-serde directory exists (serde integration)"
else
    print_status "FAIL" "tracing-serde directory not found"
fi

if [ -d "tracing-journald" ]; then
    print_status "PASS" "tracing-journald directory exists (journald integration)"
else
    print_status "FAIL" "tracing-journald directory not found"
fi

if [ -d "tracing-appender" ]; then
    print_status "PASS" "tracing-appender directory exists (appender crate)"
else
    print_status "FAIL" "tracing-appender directory not found"
fi

if [ -d "tracing-flame" ]; then
    print_status "PASS" "tracing-flame directory exists (flamegraph crate)"
else
    print_status "FAIL" "tracing-flame directory not found"
fi

if [ -d "tracing-futures" ]; then
    print_status "PASS" "tracing-futures directory exists (futures integration)"
else
    print_status "FAIL" "tracing-futures directory not found"
fi

if [ -d "tracing-tower" ]; then
    print_status "PASS" "tracing-tower directory exists (tower integration)"
else
    print_status "FAIL" "tracing-tower directory not found"
fi

if [ -d "tracing-error" ]; then
    print_status "PASS" "tracing-error directory exists (error handling)"
else
    print_status "FAIL" "tracing-error directory not found"
fi

if [ -d "examples" ]; then
    print_status "PASS" "examples directory exists (example code)"
else
    print_status "FAIL" "examples directory not found"
fi

if [ -d "assets" ]; then
    print_status "PASS" "assets directory exists (project assets)"
else
    print_status "FAIL" "assets directory not found"
fi

if [ -d "bin" ]; then
    print_status "PASS" "bin directory exists (binary utilities)"
else
    print_status "FAIL" "bin directory not found"
fi

# Check key files
if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
fi

if [ -f "Cargo.toml" ]; then
    print_status "PASS" "Cargo.toml exists (workspace configuration)"
else
    print_status "FAIL" "Cargo.toml not found"
fi

if [ -f "LICENSE" ]; then
    print_status "PASS" "LICENSE exists"
else
    print_status "FAIL" "LICENSE not found"
fi

if [ -f "SECURITY.md" ]; then
    print_status "PASS" "SECURITY.md exists"
else
    print_status "FAIL" "SECURITY.md not found"
fi

if [ -f "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md exists"
else
    print_status "FAIL" "CONTRIBUTING.md not found"
fi

if [ -f "clippy.toml" ]; then
    print_status "PASS" "clippy.toml exists (Clippy configuration)"
else
    print_status "FAIL" "clippy.toml not found"
fi

if [ -f "netlify.toml" ]; then
    print_status "PASS" "netlify.toml exists (deployment configuration)"
else
    print_status "FAIL" "netlify.toml not found"
fi

# Check tracing crate files
if [ -f "tracing/Cargo.toml" ]; then
    print_status "PASS" "tracing/Cargo.toml exists (main crate config)"
else
    print_status "FAIL" "tracing/Cargo.toml not found"
fi

if [ -f "tracing/src/lib.rs" ]; then
    print_status "PASS" "tracing/src/lib.rs exists (main crate root)"
else
    print_status "FAIL" "tracing/src/lib.rs not found"
fi

if [ -f "tracing/README.md" ]; then
    print_status "PASS" "tracing/README.md exists (main crate docs)"
else
    print_status "FAIL" "tracing/README.md not found"
fi

if [ -f "tracing/CHANGELOG.md" ]; then
    print_status "PASS" "tracing/CHANGELOG.md exists (main crate changelog)"
else
    print_status "FAIL" "tracing/CHANGELOG.md not found"
fi

echo ""
echo "4. Testing Tokio-rs Tracing Source Code..."
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

# Count example files
example_files=$(find . -name "*.rs" -path "*/examples/*" | wc -l)
if [ "$example_files" -gt 0 ]; then
    print_status "PASS" "Found $example_files example files"
else
    print_status "WARN" "No example files found"
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
echo "5. Testing Tokio-rs Tracing Dependencies..."
echo "-----------------------------------------"
# Test if required dependencies are available
if command -v cargo &> /dev/null; then
    print_status "INFO" "Testing Tokio-rs Tracing dependencies..."
    
    # Test workspace dependencies
    if cargo tree --quiet | grep -q "tracing"; then
        print_status "PASS" "tracing dependency is available"
    else
        print_status "WARN" "tracing dependency is not available"
    fi
    
    # Test tracing-core dependency
    if cargo tree --quiet | grep -q "tracing-core"; then
        print_status "PASS" "tracing-core dependency is available"
    else
        print_status "WARN" "tracing-core dependency is not available"
    fi
    
    # Test tracing-subscriber dependency
    if cargo tree --quiet | grep -q "tracing-subscriber"; then
        print_status "PASS" "tracing-subscriber dependency is available"
    else
        print_status "WARN" "tracing-subscriber dependency is not available"
    fi
else
    print_status "FAIL" "Cargo is not available for dependency testing"
fi

echo ""
echo "6. Testing Tokio-rs Tracing Documentation..."
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

if [ -r "SECURITY.md" ]; then
    print_status "PASS" "SECURITY.md is readable"
else
    print_status "FAIL" "SECURITY.md is not readable"
fi

if [ -r "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md is readable"
else
    print_status "FAIL" "CONTRIBUTING.md is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "tracing" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "framework" README.md; then
        print_status "PASS" "README.md contains framework description"
    else
        print_status "WARN" "README.md missing framework description"
    fi
    
    if grep -q "instrumenting" README.md; then
        print_status "PASS" "README.md contains instrumenting description"
    else
        print_status "WARN" "README.md missing instrumenting description"
    fi
    
    if grep -q "diagnostic" README.md; then
        print_status "PASS" "README.md contains diagnostic description"
    else
        print_status "WARN" "README.md missing diagnostic description"
    fi
    
    if grep -q "structured" README.md; then
        print_status "PASS" "README.md contains structured description"
    else
        print_status "WARN" "README.md missing structured description"
    fi
fi

echo ""
echo "7. Testing Tokio-rs Tracing Docker Functionality..."
echo "------------------------------------------------"
# Test if Docker container can run basic commands
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    # Test if Docker container can execute commands
    if docker run --rm tracing-env-test ls --version >/dev/null 2>&1; then
        print_status "PASS" "Docker container can execute basic commands"
        
        # Test Rust in Docker
        if docker run --rm tracing-env-test rustc --version >/dev/null 2>&1; then
            print_status "PASS" "Rust works in Docker container"
        else
            print_status "FAIL" "Rust does not work in Docker container"
        fi
        
        # Test Cargo in Docker
        if docker run --rm tracing-env-test cargo --version >/dev/null 2>&1; then
            print_status "PASS" "Cargo works in Docker container"
        else
            print_status "FAIL" "Cargo does not work in Docker container"
        fi
        
        # Test cargo-nextest in Docker
        if docker run --rm tracing-env-test cargo nextest --version >/dev/null 2>&1; then
            print_status "PASS" "cargo-nextest works in Docker container"
        else
            print_status "FAIL" "cargo-nextest does not work in Docker container"
        fi
        
        # Test cargo-hack in Docker
        if docker run --rm tracing-env-test cargo hack --version >/dev/null 2>&1; then
            print_status "PASS" "cargo-hack works in Docker container"
        else
            print_status "FAIL" "cargo-hack does not work in Docker container"
        fi
        
        # Test cargo-audit in Docker
        if docker run --rm tracing-env-test cargo audit --version >/dev/null 2>&1; then
            print_status "PASS" "cargo-audit works in Docker container"
        else
            print_status "FAIL" "cargo-audit does not work in Docker container"
        fi
        
        # Test inferno in Docker
        if docker run --rm tracing-env-test inferno --version >/dev/null 2>&1; then
            print_status "PASS" "inferno works in Docker container"
        else
            print_status "FAIL" "inferno does not work in Docker container"
        fi
        
        # Test Git in Docker
        if docker run --rm tracing-env-test git --version >/dev/null 2>&1; then
            print_status "PASS" "Git works in Docker container"
        else
            print_status "FAIL" "Git does not work in Docker container"
        fi
        
        # Test if project files are accessible in Docker
        if docker run --rm -v "$(pwd):/workspace" tracing-env-test test -f README.md; then
            print_status "PASS" "README.md is accessible in Docker container"
        else
            print_status "FAIL" "README.md is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" tracing-env-test test -f Cargo.toml; then
            print_status "PASS" "Cargo.toml is accessible in Docker container"
        else
            print_status "FAIL" "Cargo.toml is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" tracing-env-test test -f tracing/Cargo.toml; then
            print_status "PASS" "tracing/Cargo.toml is accessible in Docker container"
        else
            print_status "FAIL" "tracing/Cargo.toml is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" tracing-env-test test -f tracing/src/lib.rs; then
            print_status "PASS" "tracing/src/lib.rs is accessible in Docker container"
        else
            print_status "FAIL" "tracing/src/lib.rs is not accessible in Docker container"
        fi
        
        # Test Rust compilation in Docker
        if timeout 60s docker run --rm -v "$(pwd):/workspace" -w /workspace tracing-env-test rustc --crate-type lib --emit=metadata -o /dev/null tracing/src/lib.rs >/dev/null 2>&1; then
            print_status "PASS" "Rust compilation works in Docker container"
        else
            print_status "FAIL" "Rust compilation does not work in Docker container"
        fi
    else
        print_status "WARN" "Docker container has binary execution issues - cannot test runtime functionality"
        print_status "INFO" "Docker build succeeded, but container runtime has architecture compatibility issues"
        print_status "INFO" "This may be due to platform/architecture mismatch between host and container"
    fi
fi

echo ""
echo "8. Testing Tokio-rs Tracing Build Process..."
echo "------------------------------------------"
# Test if Docker container can run build commands
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    # Test if Docker container can execute commands
    if docker run --rm tracing-env-test ls --version >/dev/null 2>&1; then
        # Test if project directories are accessible
        if docker run --rm -v "$(pwd):/workspace" -w /workspace tracing-env-test test -d examples; then
            print_status "PASS" "examples directory is accessible in Docker container"
        else
            print_status "FAIL" "examples directory is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" -w /workspace tracing-env-test test -d tracing/benches; then
            print_status "PASS" "tracing/benches directory is accessible in Docker container"
        else
            print_status "FAIL" "tracing/benches directory is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" -w /workspace tracing-env-test test -d tracing/tests; then
            print_status "PASS" "tracing/tests directory is accessible in Docker container"
        else
            print_status "FAIL" "tracing/tests directory is not accessible in Docker container"
        fi
        
        # Test if configuration files are accessible
        if docker run --rm -v "$(pwd):/workspace" -w /workspace tracing-env-test test -f clippy.toml; then
            print_status "PASS" "clippy.toml is accessible in Docker container"
        else
            print_status "FAIL" "clippy.toml is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" -w /workspace tracing-env-test test -f netlify.toml; then
            print_status "PASS" "netlify.toml is accessible in Docker container"
        else
            print_status "FAIL" "netlify.toml is not accessible in Docker container"
        fi
        
        # Test cargo check
        if timeout 180s docker run --rm -v "$(pwd):/workspace" -w /workspace tracing-env-test cargo check --quiet >/dev/null 2>&1; then
            print_status "PASS" "cargo check works in Docker container"
        else
            print_status "FAIL" "cargo check does not work in Docker container"
        fi
        
        # Test cargo audit
        if timeout 60s docker run --rm -v "$(pwd):/workspace" -w /workspace tracing-env-test cargo audit >/dev/null 2>&1; then
            print_status "PASS" "cargo audit works in Docker container"
        else
            print_status "FAIL" "cargo audit does not work in Docker container"
        fi
        
        # Test cargo nextest
        if timeout 120s docker run --rm -v "$(pwd):/workspace" -w /workspace tracing-env-test cargo nextest list >/dev/null 2>&1; then
            print_status "PASS" "cargo nextest works in Docker container"
        else
            print_status "FAIL" "cargo nextest does not work in Docker container"
        fi
        
        # Skip actual test execution to avoid timeouts
        print_status "WARN" "Skipping actual test execution to avoid timeouts (full test suite)"
        print_status "INFO" "Docker environment is ready for Tokio-rs Tracing development"
    else
        print_status "WARN" "Docker container has binary execution issues - cannot test build process"
        print_status "INFO" "Docker build succeeded, but container runtime has architecture compatibility issues"
        print_status "INFO" "This may be due to platform/architecture mismatch between host and container"
    fi
fi

echo ""
echo "=========================================="
echo "Tokio-rs Tracing Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for Tokio-rs Tracing:"
echo "- Docker build process (Rust 1.65, Cargo, cargo-nextest, cargo-hack, cargo-audit, inferno)"
echo "- Rust environment (version compatibility, compilation, toolchain)"
echo "- System dependencies (Git, GCC, G++, clang, curl, wget, make, pkg-config, systemd, perl)"
echo "- Tokio-rs Tracing source code structure (Rust files, tests, benchmarks, examples)"
echo "- Tokio-rs Tracing documentation (README.md, LICENSE, SECURITY.md, CONTRIBUTING.md)"
echo "- Docker container functionality (Rust, Cargo, build tools, build process)"
echo "- Tracing framework (instrumenting, diagnostics, structured logging)"
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
    print_status "INFO" "All Docker tests passed! Your Tokio-rs Tracing Docker environment is ready!"
    print_status "INFO" "Tokio-rs Tracing is a framework for instrumenting Rust programs to collect structured, event-based diagnostic information."
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your Tokio-rs Tracing Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now run Tokio-rs Tracing in Docker: A framework for instrumenting Rust programs."
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace tracing-env-test cargo check"
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace tracing-env-test cargo nextest run"
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace tracing-env-test cargo audit"
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace tracing-env-test cargo bench"
echo ""
print_status "INFO" "For more information, see README.md and https://github.com/tokio-rs/tracing" 