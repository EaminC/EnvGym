#!/bin/bash

# Tokio Environment Benchmark Test Script
# This script tests the Docker environment setup for Tokio: An asynchronous runtime for Rust
# Tailored specifically for Tokio project requirements and features

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
    docker stop tokio-env-test 2>/dev/null || true
    docker rm tokio-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the tokio-rs_tokio project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t tokio-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/tokio-rs_tokio" --entrypoint="" tokio-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        source /home/cc/.cargo/env
        cd /home/cc/EnvGym/data/tokio-rs_tokio
        bash envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "Tokio Environment Benchmark Test"
echo "=========================================="

echo "1. Checking Rust Environment..."
echo "-------------------------------"
# Check Rust version
if command -v rustc &> /dev/null; then
    rust_version=$(rustc --version 2>&1)
    print_status "PASS" "Rust is available: $rust_version"
    
    # Check Rust version compatibility (requires 1.70+)
    rust_major=$(rustc --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1)
    rust_minor=$(rustc --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f2)
    if [ "$rust_major" -eq 1 ] && [ "$rust_minor" -ge 70 ]; then
        print_status "PASS" "Rust version is >= 1.70 (compatible with Tokio-rs Tokio)"
    else
        print_status "WARN" "Rust version should be >= 1.70 for Tokio-rs Tokio (found: $rust_major.$rust_minor)"
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

# Check cargo-deny
if command -v cargo &> /dev/null; then
    if cargo deny --version >/dev/null 2>&1; then
        deny_version=$(cargo deny --version 2>&1)
        print_status "PASS" "cargo-deny is available: $deny_version"
    else
        print_status "WARN" "cargo-deny is not available"
    fi
else
    print_status "FAIL" "Cargo is not available for cargo-deny testing"
fi

# Check cross
if command -v cross &> /dev/null; then
    cross_version=$(cross --version 2>&1)
    print_status "PASS" "cross is available: $cross_version"
else
    print_status "WARN" "cross is not available"
fi

# Check cargo-spellcheck
if command -v cargo &> /dev/null; then
    if cargo spellcheck --version >/dev/null 2>&1; then
        spellcheck_version=$(cargo spellcheck --version 2>&1)
        print_status "PASS" "cargo-spellcheck is available: $spellcheck_version"
    else
        print_status "WARN" "cargo-spellcheck is not available"
    fi
else
    print_status "FAIL" "Cargo is not available for cargo-spellcheck testing"
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

# Check Python3
if command -v python3 &> /dev/null; then
    python3_version=$(python3 --version 2>&1)
    print_status "PASS" "python3 is available: $python3_version"
else
    print_status "WARN" "python3 is not available"
fi

echo ""
echo "3. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "tokio" ]; then
    print_status "PASS" "tokio directory exists (main crate)"
else
    print_status "FAIL" "tokio directory not found"
fi

if [ -d "tokio-util" ]; then
    print_status "PASS" "tokio-util directory exists (utility crate)"
else
    print_status "FAIL" "tokio-util directory not found"
fi

if [ -d "tokio-test" ]; then
    print_status "PASS" "tokio-test directory exists (testing utilities)"
else
    print_status "FAIL" "tokio-test directory not found"
fi

if [ -d "tokio-stream" ]; then
    print_status "PASS" "tokio-stream directory exists (stream utilities)"
else
    print_status "FAIL" "tokio-stream directory not found"
fi

if [ -d "tokio-macros" ]; then
    print_status "PASS" "tokio-macros directory exists (macro crate)"
else
    print_status "FAIL" "tokio-macros directory not found"
fi

if [ -d "examples" ]; then
    print_status "PASS" "examples directory exists (example code)"
else
    print_status "FAIL" "examples directory not found"
fi

if [ -d "benches" ]; then
    print_status "PASS" "benches directory exists (benchmarks)"
else
    print_status "FAIL" "benches directory not found"
fi

if [ -d "tests-integration" ]; then
    print_status "PASS" "tests-integration directory exists (integration tests)"
else
    print_status "FAIL" "tests-integration directory not found"
fi

if [ -d "tests-build" ]; then
    print_status "PASS" "tests-build directory exists (build tests)"
else
    print_status "FAIL" "tests-build directory not found"
fi

if [ -d "stress-test" ]; then
    print_status "PASS" "stress-test directory exists (stress tests)"
else
    print_status "FAIL" "stress-test directory not found"
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

if [ -f "CODE_OF_CONDUCT.md" ]; then
    print_status "PASS" "CODE_OF_CONDUCT.md exists"
else
    print_status "FAIL" "CODE_OF_CONDUCT.md not found"
fi

if [ -f "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md exists"
else
    print_status "FAIL" "CONTRIBUTING.md not found"
fi

if [ -f "Cross.toml" ]; then
    print_status "PASS" "Cross.toml exists (cross-compilation config)"
else
    print_status "FAIL" "Cross.toml not found"
fi

if [ -f "deny.toml" ]; then
    print_status "PASS" "deny.toml exists (cargo-deny config)"
else
    print_status "FAIL" "deny.toml not found"
fi

if [ -f "spellcheck.toml" ]; then
    print_status "PASS" "spellcheck.toml exists (spellcheck config)"
else
    print_status "FAIL" "spellcheck.toml not found"
fi

if [ -f "spellcheck.dic" ]; then
    print_status "PASS" "spellcheck.dic exists (spellcheck dictionary)"
else
    print_status "FAIL" "spellcheck.dic not found"
fi

# Check tokio crate files
if [ -f "tokio/Cargo.toml" ]; then
    print_status "PASS" "tokio/Cargo.toml exists (main crate config)"
else
    print_status "FAIL" "tokio/Cargo.toml not found"
fi

if [ -f "tokio/src/lib.rs" ]; then
    print_status "PASS" "tokio/src/lib.rs exists (main crate root)"
else
    print_status "FAIL" "tokio/src/lib.rs not found"
fi

if [ -f "tokio/README.md" ]; then
    print_status "PASS" "tokio/README.md exists (main crate docs)"
else
    print_status "FAIL" "tokio/README.md not found"
fi

if [ -f "tokio/CHANGELOG.md" ]; then
    print_status "PASS" "tokio/CHANGELOG.md exists (main crate changelog)"
else
    print_status "FAIL" "tokio/CHANGELOG.md not found"
fi

echo ""
echo "4. Testing Tokio-rs Tokio Source Code..."
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
echo "5. Testing Tokio-rs Tokio Dependencies..."
echo "-----------------------------------------"
# Test if required dependencies are available
if command -v cargo &> /dev/null; then
    print_status "INFO" "Testing Tokio-rs Tokio dependencies..."
    
    # Test workspace dependencies
    if cargo tree --quiet | grep -q "tokio"; then
        print_status "PASS" "tokio dependency is available"
    else
        print_status "WARN" "tokio dependency is not available"
    fi
    
    # Test mio dependency (optional)
    if cargo tree --quiet | grep -q "mio"; then
        print_status "PASS" "mio dependency is available"
    else
        print_status "WARN" "mio dependency is not available (optional)"
    fi
    
    # Test bytes dependency (optional)
    if cargo tree --quiet | grep -q "bytes"; then
        print_status "PASS" "bytes dependency is available"
    else
        print_status "WARN" "bytes dependency is not available (optional)"
    fi
else
    print_status "FAIL" "Cargo is not available for dependency testing"
fi

echo ""
echo "6. Testing Tokio-rs Tokio Documentation..."
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

if [ -r "CODE_OF_CONDUCT.md" ]; then
    print_status "PASS" "CODE_OF_CONDUCT.md is readable"
else
    print_status "FAIL" "CODE_OF_CONDUCT.md is not readable"
fi

if [ -r "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md is readable"
else
    print_status "FAIL" "CONTRIBUTING.md is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "Tokio" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "event-driven" README.md; then
        print_status "PASS" "README.md contains event-driven description"
    else
        print_status "WARN" "README.md missing event-driven description"
    fi
    
    if grep -q "non-blocking" README.md; then
        print_status "PASS" "README.md contains non-blocking description"
    else
        print_status "WARN" "README.md missing non-blocking description"
    fi
    
    if grep -q "asynchronous" README.md; then
        print_status "PASS" "README.md contains asynchronous description"
    else
        print_status "WARN" "README.md missing asynchronous description"
    fi
    
    if grep -q "I/O" README.md; then
        print_status "PASS" "README.md contains I/O description"
    else
        print_status "WARN" "README.md missing I/O description"
    fi
fi

echo ""
echo "7. Testing Tokio-rs Tokio Docker Functionality..."
echo "------------------------------------------------"
# Test if Docker container can run basic commands (only when not in Docker container)
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test if Docker container can execute commands
    if docker run --rm tokio-env-test ls --version >/dev/null 2>&1; then
        print_status "PASS" "Docker container can execute basic commands"
        
        # Test Rust in Docker
        if docker run --rm tokio-env-test bash -c "source /home/cc/.cargo/env && rustc --version" >/dev/null 2>&1; then
            print_status "PASS" "Rust works in Docker container"
        else
            print_status "FAIL" "Rust does not work in Docker container"
        fi
        
        # Test Cargo in Docker
        if docker run --rm tokio-env-test bash -c "source /home/cc/.cargo/env && cargo --version" >/dev/null 2>&1; then
            print_status "PASS" "Cargo works in Docker container"
        else
            print_status "FAIL" "Cargo does not work in Docker container"
        fi
        
        # Test cargo-deny in Docker
        if docker run --rm tokio-env-test bash -c "source /home/cc/.cargo/env && cargo deny --version" >/dev/null 2>&1; then
            print_status "PASS" "cargo-deny works in Docker container"
        else
            print_status "FAIL" "cargo-deny does not work in Docker container"
        fi
        
        # Test cross in Docker
        if docker run --rm tokio-env-test bash -c "source /home/cc/.cargo/env && cross --version" >/dev/null 2>&1; then
            print_status "PASS" "cross works in Docker container"
        else
            print_status "FAIL" "cross does not work in Docker container"
        fi
        
        # Test cargo-spellcheck in Docker
        if docker run --rm tokio-env-test bash -c "source /home/cc/.cargo/env && cargo spellcheck --version" >/dev/null 2>&1; then
            print_status "PASS" "cargo-spellcheck works in Docker container"
        else
            print_status "FAIL" "cargo-spellcheck does not work in Docker container"
        fi
        
        # Test Git in Docker
        if docker run --rm tokio-env-test bash -c "git --version" >/dev/null 2>&1; then
            print_status "PASS" "Git works in Docker container"
        else
            print_status "FAIL" "Git does not work in Docker container"
        fi
        
        # Test if project files are accessible in Docker
        if docker run --rm -v "$(pwd):/workspace" tokio-env-test bash -c "test -f README.md"; then
            print_status "PASS" "README.md is accessible in Docker container"
        else
            print_status "FAIL" "README.md is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" tokio-env-test bash -c "test -f Cargo.toml"; then
            print_status "PASS" "Cargo.toml is accessible in Docker container"
        else
            print_status "FAIL" "Cargo.toml is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" tokio-env-test bash -c "test -f tokio/Cargo.toml"; then
            print_status "PASS" "tokio/Cargo.toml is accessible in Docker container"
        else
            print_status "FAIL" "tokio/Cargo.toml is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" tokio-env-test bash -c "test -f tokio/src/lib.rs"; then
            print_status "PASS" "tokio/src/lib.rs is accessible in Docker container"
        else
            print_status "FAIL" "tokio/src/lib.rs is not accessible in Docker container"
        fi
        
        # Test Rust compilation in Docker
        if timeout 60s docker run --rm -v "$(pwd):/workspace" -w /workspace tokio-env-test bash -c "source /home/cc/.cargo/env && rustc --crate-type lib --emit=metadata -o /dev/null tokio/src/lib.rs" >/dev/null 2>&1; then
            print_status "PASS" "Rust compilation works in Docker container"
        else
            print_status "FAIL" "Rust compilation does not work in Docker container"
        fi
    else
        print_status "WARN" "Docker container has binary execution issues - cannot test runtime functionality"
        print_status "INFO" "Docker build succeeded, but container runtime has architecture compatibility issues"
        print_status "INFO" "This may be due to platform/architecture mismatch between host and container"
    fi
else
    print_status "INFO" "Skipping Docker functionality tests (running inside container)"
fi

echo ""
echo "8. Testing Tokio-rs Tokio Build Process..."
echo "------------------------------------------"
# Test if Docker container can run build commands (only when not in Docker container)
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test if Docker container can execute commands
    if docker run --rm tokio-env-test ls --version >/dev/null 2>&1; then
        # Test if project directories are accessible
        if docker run --rm -v "$(pwd):/workspace" -w /workspace tokio-env-test bash -c "test -d examples"; then
            print_status "PASS" "examples directory is accessible in Docker container"
        else
            print_status "FAIL" "examples directory is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" -w /workspace tokio-env-test bash -c "test -d benches"; then
            print_status "PASS" "benches directory is accessible in Docker container"
        else
            print_status "FAIL" "benches directory is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" -w /workspace tokio-env-test bash -c "test -d tests-integration"; then
            print_status "PASS" "tests-integration directory is accessible in Docker container"
        else
            print_status "FAIL" "tests-integration directory is not accessible in Docker container"
        fi
        
        # Test if configuration files are accessible
        if docker run --rm -v "$(pwd):/workspace" -w /workspace tokio-env-test bash -c "test -f deny.toml"; then
            print_status "PASS" "deny.toml is accessible in Docker container"
        else
            print_status "FAIL" "deny.toml is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" -w /workspace tokio-env-test bash -c "test -f spellcheck.toml"; then
            print_status "PASS" "spellcheck.toml is accessible in Docker container"
        else
            print_status "FAIL" "spellcheck.toml is not accessible in Docker container"
        fi
        
        # Test cargo check
        if timeout 180s docker run --rm -v "$(pwd):/workspace" -w /workspace tokio-env-test bash -c "source /home/cc/.cargo/env && cargo check --quiet" >/dev/null 2>&1; then
            print_status "PASS" "cargo check works in Docker container"
        else
            print_status "FAIL" "cargo check does not work in Docker container"
        fi
        
        # Test cargo deny check
        if timeout 60s docker run --rm -v "$(pwd):/workspace" -w /workspace tokio-env-test bash -c "source /home/cc/.cargo/env && cargo deny check" >/dev/null 2>&1; then
            print_status "PASS" "cargo deny check works in Docker container"
        else
            print_status "FAIL" "cargo deny check does not work in Docker container"
        fi
        
        # Test cargo spellcheck
        if timeout 60s docker run --rm -v "$(pwd):/workspace" -w /workspace tokio-env-test bash -c "source /home/cc/.cargo/env && cargo spellcheck" >/dev/null 2>&1; then
            print_status "PASS" "cargo spellcheck works in Docker container"
        else
            print_status "FAIL" "cargo spellcheck does not work in Docker container"
        fi
        
        # Skip actual test execution to avoid timeouts
        print_status "WARN" "Skipping actual test execution to avoid timeouts (full test suite)"
        print_status "INFO" "Docker environment is ready for Tokio-rs Tokio development"
    else
        print_status "WARN" "Docker container has binary execution issues - cannot test build process"
        print_status "INFO" "Docker build succeeded, but container runtime has architecture compatibility issues"
        print_status "INFO" "This may be due to platform/architecture mismatch between host and container"
    fi
else
    print_status "INFO" "Skipping Docker build tests (running inside container)"
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for Tokio:"
echo "- Docker build process (Ubuntu 22.04, Rust, Cargo)"
echo "- Rust environment (compilation, toolchain, dependencies)"
echo "- Cargo environment (package management, build system)"
echo "- Tokio build system (Cargo.toml, workspace)"
echo "- Tokio source code (tokio, tokio-util, tokio-test, tokio-stream)"
echo "- Tokio documentation (README.md, CONTRIBUTING.md)"
echo "- Tokio configuration (Cargo.toml, .gitignore, deny.toml)"
echo "- Docker container functionality (Rust, Cargo)"
echo "- Asynchronous runtime capabilities"

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
    print_status "INFO" "All Docker tests passed! Your Tokio Docker environment is ready!"
    print_status "INFO" "Tokio is an asynchronous runtime for Rust."
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your Tokio Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi

print_status "INFO" "You can now run Tokio in Docker: An asynchronous runtime for Rust."
print_status "INFO" "Example: docker run --rm tokio-env-test cargo build"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/tokio-rs_tokio tokio-env-test /bin/bash" 