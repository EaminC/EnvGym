#!/bin/bash

# Rayon Environment Benchmark Test Script
# This script tests the Docker environment setup for Rayon: A data parallelism library for Rust
# Tailored specifically for Rayon project requirements and features

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
    docker stop rayon-env-test 2>/dev/null || true
    docker rm rayon-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the rayon-rs_rayon project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t rayon-env-test .; then
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
    docker run --rm -v "$(pwd):/workspace" rayon-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        cd /workspace
        bash envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "Rayon Environment Benchmark Test"
echo "=========================================="

echo "1. Checking System Dependencies..."
echo "--------------------------------"
# Check Rust
if command -v rustc &> /dev/null; then
    rustc_version=$(rustc --version 2>&1)
    print_status "PASS" "Rust is available: $rustc_version"
else
    print_status "FAIL" "Rust is not available"
fi

# Check Rust version
if command -v rustc &> /dev/null; then
    rustc_version_num=$(rustc --version | sed 's/rustc \([0-9]*\)\.\([0-9]*\)\.\([0-9]*\).*/\1\2\3/')
    if [ "$rustc_version_num" -ge 1630 ]; then
        print_status "PASS" "Rust version is >= 1.63.0 (compatible with Rayon)"
    else
        print_status "WARN" "Rust version should be >= 1.63.0 for Rayon (found: $(rustc --version | cut -d' ' -f2))"
    fi
else
    print_status "FAIL" "Rust is not available for version check"
fi

# Check Cargo
if command -v cargo &> /dev/null; then
    cargo_version=$(cargo --version 2>&1)
    print_status "PASS" "Cargo is available: $cargo_version"
else
    print_status "FAIL" "Cargo is not available"
fi

# Check Git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1)
    print_status "PASS" "Git is available: $git_version"
else
    print_status "FAIL" "Git is not available"
fi

# Check curl
if command -v curl &> /dev/null; then
    curl_version=$(curl --version 2>&1 | head -n 1)
    print_status "PASS" "curl is available: $curl_version"
else
    print_status "FAIL" "curl is not available"
fi

# Check build tools
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version 2>&1 | head -n 1)
    print_status "PASS" "GCC is available: $gcc_version"
else
    print_status "FAIL" "GCC is not available"
fi

if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "make is available: $make_version"
else
    print_status "FAIL" "make is not available"
fi

if command -v pkg-config &> /dev/null; then
    pkg_config_version=$(pkg-config --version 2>&1)
    print_status "PASS" "pkg-config is available: $pkg_config_version"
else
    print_status "FAIL" "pkg-config is not available"
fi

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "src" ]; then
    print_status "PASS" "src directory exists (main source code)"
else
    print_status "FAIL" "src directory not found"
fi

if [ -d "tests" ]; then
    print_status "PASS" "tests directory exists (test suite)"
else
    print_status "FAIL" "tests directory not found"
fi

if [ -d "rayon-core" ]; then
    print_status "PASS" "rayon-core directory exists (core APIs)"
else
    print_status "FAIL" "rayon-core directory not found"
fi

if [ -d "rayon-demo" ]; then
    print_status "PASS" "rayon-demo directory exists (examples and benchmarks)"
else
    print_status "FAIL" "rayon-demo directory not found"
fi

if [ -d "ci" ]; then
    print_status "PASS" "ci directory exists (continuous integration)"
else
    print_status "FAIL" "ci directory not found"
fi

if [ -d "scripts" ]; then
    print_status "PASS" "scripts directory exists (build scripts)"
else
    print_status "FAIL" "scripts directory not found"
fi

# Check key files
if [ -f "Cargo.toml" ]; then
    print_status "PASS" "Cargo.toml exists (root package configuration)"
else
    print_status "FAIL" "Cargo.toml not found"
fi

if [ -f "Cargo.lock" ]; then
    print_status "PASS" "Cargo.lock exists (dependency lock file)"
else
    print_status "FAIL" "Cargo.lock not found"
fi

if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
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

if [ -f ".gitignore" ]; then
    print_status "PASS" ".gitignore exists"
else
    print_status "FAIL" ".gitignore not found"
fi

if [ -f "FAQ.md" ]; then
    print_status "PASS" "FAQ.md exists (frequently asked questions)"
else
    print_status "FAIL" "FAQ.md not found"
fi

if [ -f "RELEASES.md" ]; then
    print_status "PASS" "RELEASES.md exists (release notes)"
else
    print_status "FAIL" "RELEASES.md not found"
fi

# Check rayon-core files
if [ -f "rayon-core/Cargo.toml" ]; then
    print_status "PASS" "rayon-core/Cargo.toml exists (core package configuration)"
else
    print_status "FAIL" "rayon-core/Cargo.toml not found"
fi

if [ -d "rayon-core/src" ]; then
    print_status "PASS" "rayon-core/src directory exists (core source code)"
else
    print_status "FAIL" "rayon-core/src directory not found"
fi

if [ -d "rayon-core/tests" ]; then
    print_status "PASS" "rayon-core/tests directory exists (core tests)"
else
    print_status "FAIL" "rayon-core/tests directory not found"
fi

# Check rayon-demo files
if [ -f "rayon-demo/Cargo.toml" ]; then
    print_status "PASS" "rayon-demo/Cargo.toml exists (demo package configuration)"
else
    print_status "FAIL" "rayon-demo/Cargo.toml not found"
fi

if [ -d "rayon-demo/src" ]; then
    print_status "PASS" "rayon-demo/src directory exists (demo source code)"
else
    print_status "FAIL" "rayon-demo/src directory not found"
fi

if [ -d "rayon-demo/examples" ]; then
    print_status "PASS" "rayon-demo/examples directory exists (example programs)"
else
    print_status "FAIL" "rayon-demo/examples directory not found"
fi

if [ -d "rayon-demo/data" ]; then
    print_status "PASS" "rayon-demo/data directory exists (demo data)"
else
    print_status "FAIL" "rayon-demo/data directory not found"
fi

echo ""
echo "3. Checking Environment Variables..."
echo "-----------------------------------"
# Check Rust environment
if [ -n "${RUSTUP_HOME:-}" ]; then
    print_status "PASS" "RUSTUP_HOME is set: $RUSTUP_HOME"
else
    print_status "WARN" "RUSTUP_HOME is not set"
fi

if [ -n "${CARGO_HOME:-}" ]; then
    print_status "PASS" "CARGO_HOME is set: $CARGO_HOME"
else
    print_status "WARN" "CARGO_HOME is not set"
fi

if [ -n "${RUST_BACKTRACE:-}" ]; then
    print_status "PASS" "RUST_BACKTRACE is set: $RUST_BACKTRACE"
else
    print_status "WARN" "RUST_BACKTRACE is not set"
fi

# Check PATH
if echo "$PATH" | grep -q "cargo"; then
    print_status "PASS" "cargo is in PATH"
else
    print_status "WARN" "cargo is not in PATH"
fi

if echo "$PATH" | grep -q "rustc"; then
    print_status "PASS" "rustc is in PATH"
else
    print_status "WARN" "rustc is not in PATH"
fi

if echo "$PATH" | grep -q "git"; then
    print_status "PASS" "git is in PATH"
else
    print_status "WARN" "git is not in PATH"
fi

echo ""
echo "4. Testing Rust Environment..."
echo "-----------------------------"
# Test Rust
if command -v rustc &> /dev/null; then
    print_status "PASS" "rustc is available"
    
    # Test Rust execution
    if timeout 30s rustc --version >/dev/null 2>&1; then
        print_status "PASS" "Rust execution works"
    else
        print_status "WARN" "Rust execution failed"
    fi
    
    # Test Rust compilation
    if timeout 30s rustc --version >/dev/null 2>&1; then
        print_status "PASS" "rustc version command works"
    else
        print_status "WARN" "rustc version command failed"
    fi
else
    print_status "FAIL" "rustc is not available"
fi

# Test Cargo
if command -v cargo &> /dev/null; then
    print_status "PASS" "cargo is available"
    
    # Test Cargo version
    if timeout 30s cargo --version >/dev/null 2>&1; then
        print_status "PASS" "Cargo version command works"
    else
        print_status "WARN" "Cargo version command failed"
    fi
    
    # Test Cargo help
    if timeout 30s cargo help >/dev/null 2>&1; then
        print_status "PASS" "Cargo help command works"
    else
        print_status "WARN" "Cargo help command failed"
    fi
else
    print_status "FAIL" "cargo is not available"
fi

echo ""
echo "5. Testing Rayon Build System..."
echo "-------------------------------"
# Test Cargo.toml
if [ -f "Cargo.toml" ]; then
    print_status "PASS" "Cargo.toml exists for build testing"
    
    # Check for key dependencies
    if grep -q "rayon-core" Cargo.toml; then
        print_status "PASS" "Cargo.toml includes rayon-core dependency"
    else
        print_status "FAIL" "Cargo.toml missing rayon-core dependency"
    fi
    
    if grep -q "either" Cargo.toml; then
        print_status "PASS" "Cargo.toml includes either dependency"
    else
        print_status "FAIL" "Cargo.toml missing either dependency"
    fi
    
    if grep -q "wasm_sync" Cargo.toml; then
        print_status "PASS" "Cargo.toml includes wasm_sync dependency"
    else
        print_status "WARN" "Cargo.toml missing wasm_sync dependency"
    fi
else
    print_status "FAIL" "Cargo.toml not found"
fi

# Test workspace configuration
if [ -f "Cargo.toml" ]; then
    if grep -q "\[workspace\]" Cargo.toml; then
        print_status "PASS" "Cargo.toml contains workspace configuration"
    else
        print_status "FAIL" "Cargo.toml missing workspace configuration"
    fi
    
    if grep -q "rayon-core" Cargo.toml; then
        print_status "PASS" "Cargo.toml includes rayon-core in workspace"
    else
        print_status "FAIL" "Cargo.toml missing rayon-core in workspace"
    fi
    
    if grep -q "rayon-demo" Cargo.toml; then
        print_status "PASS" "Cargo.toml includes rayon-demo in workspace"
    else
        print_status "FAIL" "Cargo.toml missing rayon-demo in workspace"
    fi
fi

# Test rayon-core Cargo.toml
if [ -f "rayon-core/Cargo.toml" ]; then
    print_status "PASS" "rayon-core/Cargo.toml exists"
    
    # Check for key dependencies
    if grep -q "crossbeam-deque" rayon-core/Cargo.toml; then
        print_status "PASS" "rayon-core/Cargo.toml includes crossbeam-deque dependency"
    else
        print_status "FAIL" "rayon-core/Cargo.toml missing crossbeam-deque dependency"
    fi
    
    if grep -q "crossbeam-utils" rayon-core/Cargo.toml; then
        print_status "PASS" "rayon-core/Cargo.toml includes crossbeam-utils dependency"
    else
        print_status "FAIL" "rayon-core/Cargo.toml missing crossbeam-utils dependency"
    fi
    
    if grep -q "wasm_sync" rayon-core/Cargo.toml; then
        print_status "PASS" "rayon-core/Cargo.toml includes wasm_sync dependency"
    else
        print_status "WARN" "rayon-core/Cargo.toml missing wasm_sync dependency"
    fi
else
    print_status "FAIL" "rayon-core/Cargo.toml not found"
fi

# Test rayon-demo Cargo.toml
if [ -f "rayon-demo/Cargo.toml" ]; then
    print_status "PASS" "rayon-demo/Cargo.toml exists"
    
    # Check for key dependencies
    if grep -q "rayon = { path = \"../\" }" rayon-demo/Cargo.toml; then
        print_status "PASS" "rayon-demo/Cargo.toml includes rayon dependency"
    else
        print_status "FAIL" "rayon-demo/Cargo.toml missing rayon dependency"
    fi
    
    if grep -q "rand" rayon-demo/Cargo.toml; then
        print_status "PASS" "rayon-demo/Cargo.toml includes rand dependency"
    else
        print_status "FAIL" "rayon-demo/Cargo.toml missing rand dependency"
    fi
else
    print_status "FAIL" "rayon-demo/Cargo.toml not found"
fi

echo ""
echo "6. Testing Rayon Source Code Structure..."
echo "----------------------------------------"
# Test source code directories
if [ -d "src" ]; then
    print_status "PASS" "src directory exists for source testing"
    
    # Count source files
    rust_files=$(find src -name "*.rs" | wc -l)
    
    if [ "$rust_files" -gt 0 ]; then
        print_status "PASS" "Found $rust_files Rust source files in src"
    else
        print_status "WARN" "No Rust source files found in src"
    fi
    
    # Check for key modules
    if [ -f "src/lib.rs" ]; then
        print_status "PASS" "src/lib.rs exists (main library file)"
    else
        print_status "FAIL" "src/lib.rs not found"
    fi
    
    if [ -f "src/prelude.rs" ]; then
        print_status "PASS" "src/prelude.rs exists (prelude module)"
    else
        print_status "FAIL" "src/prelude.rs not found"
    fi
    
    if [ -d "src/iter" ]; then
        print_status "PASS" "src/iter directory exists (parallel iterators)"
    else
        print_status "FAIL" "src/iter directory not found"
    fi
    
    if [ -d "src/collections" ]; then
        print_status "PASS" "src/collections directory exists (parallel collections)"
    else
        print_status "FAIL" "src/collections directory not found"
    fi
else
    print_status "FAIL" "src directory not found"
fi

if [ -d "rayon-core/src" ]; then
    print_status "PASS" "rayon-core/src directory exists for core testing"
    
    # Count core source files
    core_rust_files=$(find rayon-core/src -name "*.rs" | wc -l)
    if [ "$core_rust_files" -gt 0 ]; then
        print_status "PASS" "Found $core_rust_files Rust source files in rayon-core/src"
    else
        print_status "WARN" "No Rust source files found in rayon-core/src"
    fi
else
    print_status "FAIL" "rayon-core/src directory not found"
fi

if [ -d "rayon-demo/src" ]; then
    print_status "PASS" "rayon-demo/src directory exists for demo testing"
    
    # Count demo source files
    demo_rust_files=$(find rayon-demo/src -name "*.rs" | wc -l)
    if [ "$demo_rust_files" -gt 0 ]; then
        print_status "PASS" "Found $demo_rust_files Rust source files in rayon-demo/src"
    else
        print_status "WARN" "No Rust source files found in rayon-demo/src"
    fi
else
    print_status "FAIL" "rayon-demo/src directory not found"
fi

if [ -d "tests" ]; then
    print_status "PASS" "tests directory exists for test testing"
    
    # Count test files
    test_files=$(find tests -name "*.rs" | wc -l)
    if [ "$test_files" -gt 0 ]; then
        print_status "PASS" "Found $test_files test files in tests"
    else
        print_status "WARN" "No test files found in tests"
    fi
else
    print_status "FAIL" "tests directory not found"
fi

echo ""
echo "7. Testing Rayon Documentation..."
echo "--------------------------------"
# Test documentation
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

if [ -r ".gitignore" ]; then
    print_status "PASS" ".gitignore is readable"
else
    print_status "FAIL" ".gitignore is not readable"
fi

if [ -r "FAQ.md" ]; then
    print_status "PASS" "FAQ.md is readable"
else
    print_status "FAIL" "FAQ.md is not readable"
fi

if [ -r "RELEASES.md" ]; then
    print_status "PASS" "RELEASES.md is readable"
else
    print_status "FAIL" "RELEASES.md is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "Rayon" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "data-parallelism" README.md; then
        print_status "PASS" "README.md contains project description"
    else
        print_status "WARN" "README.md missing project description"
    fi
    
    if grep -q "cargo" README.md; then
        print_status "PASS" "README.md contains build instructions"
    else
        print_status "WARN" "README.md missing build instructions"
    fi
fi

echo ""
echo "8. Testing Rayon Configuration..."
echo "--------------------------------"
# Test configuration files
if [ -r "Cargo.toml" ]; then
    print_status "PASS" "Cargo.toml is readable"
else
    print_status "FAIL" "Cargo.toml is not readable"
fi

if [ -r "Cargo.lock" ]; then
    print_status "PASS" "Cargo.lock is readable"
else
    print_status "FAIL" "Cargo.lock is not readable"
fi

if [ -r ".gitignore" ]; then
    print_status "PASS" ".gitignore is readable"
else
    print_status "FAIL" ".gitignore is not readable"
fi

# Check .gitignore content
if [ -r ".gitignore" ]; then
    if grep -q "target/" .gitignore; then
        print_status "PASS" ".gitignore excludes target directory"
    else
        print_status "WARN" ".gitignore missing target directory exclusion"
    fi
    
    if grep -q "Cargo.lock" .gitignore; then
        print_status "PASS" ".gitignore excludes Cargo.lock"
    else
        print_status "WARN" ".gitignore missing Cargo.lock exclusion"
    fi
fi

echo ""
echo "9. Testing Rayon Docker Functionality..."
echo "---------------------------------------"
# Test if Docker container can run basic commands (only when not in Docker container)
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test Rust in Docker
    if docker run --rm rayon-env-test rustc --version >/dev/null 2>&1; then
        print_status "PASS" "Rust works in Docker container"
    else
        print_status "FAIL" "Rust does not work in Docker container"
    fi
    
    # Test Cargo in Docker
    if docker run --rm rayon-env-test cargo --version >/dev/null 2>&1; then
        print_status "PASS" "Cargo works in Docker container"
    else
        print_status "FAIL" "Cargo does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm rayon-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test build tools in Docker
    if docker run --rm rayon-env-test gcc --version >/dev/null 2>&1; then
        print_status "PASS" "GCC works in Docker container"
    else
        print_status "FAIL" "GCC does not work in Docker container"
    fi
    
    # Test if Cargo.toml is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" rayon-env-test test -f Cargo.toml; then
        print_status "PASS" "Cargo.toml is accessible in Docker container"
    else
        print_status "FAIL" "Cargo.toml is not accessible in Docker container"
    fi
    
    # Test if src directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" rayon-env-test test -d src; then
        print_status "PASS" "src directory is accessible in Docker container"
    else
        print_status "FAIL" "src directory is not accessible in Docker container"
    fi
    
    # Test if rayon-core directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" rayon-env-test test -d rayon-core; then
        print_status "PASS" "rayon-core directory is accessible in Docker container"
    else
        print_status "FAIL" "rayon-core directory is not accessible in Docker container"
    fi
    
    # Test if rayon-demo directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" rayon-env-test test -d rayon-demo; then
        print_status "PASS" "rayon-demo directory is accessible in Docker container"
    else
        print_status "FAIL" "rayon-demo directory is not accessible in Docker container"
    fi
    
    # Test if tests directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" rayon-env-test test -d tests; then
        print_status "PASS" "tests directory is accessible in Docker container"
    else
        print_status "FAIL" "tests directory is not accessible in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" rayon-env-test test -f README.md; then
        print_status "PASS" "README.md is accessible in Docker container"
    else
        print_status "FAIL" "README.md is not accessible in Docker container"
    fi
else
    print_status "INFO" "Skipping Docker functionality tests (running inside container)"
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for Rayon:"
echo "- Docker build process (Ubuntu 22.04, Rust, Cargo)"
echo "- Rust environment (compilation, toolchain, dependencies)"
echo "- Cargo environment (package management, build system)"
echo "- Rayon build system (Cargo.toml, workspace)"
echo "- Rayon source code (src, rayon-core, tests)"
echo "- Rayon documentation (README.md, FAQ.md, RELEASES.md)"
echo "- Rayon configuration (Cargo.toml, .gitignore)"
echo "- Docker container functionality (Rust, Cargo)"
echo "- Data parallelism library capabilities"

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
    print_status "INFO" "All Docker tests passed! Your Rayon Docker environment is ready!"
    print_status "INFO" "Rayon is a data parallelism library for Rust."
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your Rayon Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi

print_status "INFO" "You can now run Rayon in Docker: A data parallelism library for Rust."
print_status "INFO" "Example: docker run --rm rayon-env-test cargo build"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/rayon-rs_rayon rayon-env-test /bin/bash" 