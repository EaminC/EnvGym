#!/bin/bash

# Nushell Environment Benchmark Test Script
# This script tests the Docker environment setup for Nushell: A new type of shell
# Tailored specifically for Nushell project requirements and features

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
    docker stop nushell-env-test 2>/dev/null || true
    docker rm nushell-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the nushell_nushell project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t nushell-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/nushell_nushell" nushell-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "Nushell Environment Benchmark Test"
echo "=========================================="

echo "1. Checking System Dependencies..."
echo "--------------------------------"
# Check Rust
if command -v rustc &> /dev/null; then
    rust_version=$(rustc --version 2>&1)
    print_status "PASS" "Rust is available: $rust_version"
else
    print_status "FAIL" "Rust is not available"
fi

# Check Rust version
if command -v rustc &> /dev/null; then
    rust_major=$(rustc --version | sed 's/.*rustc \([0-9]*\)\.[0-9]*.*/\1/')
    if [ -n "$rust_major" ] && [ "$rust_major" -ge 1 ]; then
        print_status "PASS" "Rust version is >= 1 (compatible)"
    else
        print_status "WARN" "Rust version should be >= 1 (found: $rust_major)"
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

# Check Nushell
if command -v nu &> /dev/null; then
    nu_version=$(nu --version 2>&1)
    print_status "PASS" "Nushell is available: $nu_version"
else
    print_status "WARN" "Nushell is not available (target application)"
fi

# Check Git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1)
    print_status "PASS" "Git is available: $git_version"
else
    print_status "FAIL" "Git is not available"
fi

# Check GCC
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version 2>&1 | head -n 1)
    print_status "PASS" "GCC is available: $gcc_version"
else
    print_status "WARN" "GCC is not available"
fi

# Check pkg-config
if command -v pkg-config &> /dev/null; then
    pkg_config_version=$(pkg-config --version 2>&1)
    print_status "PASS" "pkg-config is available: $pkg_config_version"
else
    print_status "WARN" "pkg-config is not available"
fi

# Check curl
if command -v curl &> /dev/null; then
    curl_version=$(curl --version 2>&1 | head -n 1)
    print_status "PASS" "curl is available: $curl_version"
else
    print_status "FAIL" "curl is not available"
fi

# Check wget
if command -v wget &> /dev/null; then
    wget_version=$(wget --version 2>&1 | head -n 1)
    print_status "PASS" "wget is available: $wget_version"
else
    print_status "WARN" "wget is not available"
fi

# Check perl
if command -v perl &> /dev/null; then
    perl_version=$(perl --version 2>&1 | head -n 1)
    print_status "PASS" "perl is available: $perl_version"
else
    print_status "WARN" "perl is not available"
fi

# Check clang
if command -v clang &> /dev/null; then
    clang_version=$(clang --version 2>&1 | head -n 1)
    print_status "PASS" "clang is available: $clang_version"
else
    print_status "WARN" "clang is not available"
fi

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "src" ]; then
    print_status "PASS" "src directory exists (source code)"
else
    print_status "FAIL" "src directory not found"
fi

if [ -d "crates" ]; then
    print_status "PASS" "crates directory exists (Rust crates)"
else
    print_status "FAIL" "crates directory not found"
fi

if [ -d "tests" ]; then
    print_status "PASS" "tests directory exists (test files)"
else
    print_status "FAIL" "tests directory not found"
fi

if [ -d "scripts" ]; then
    print_status "PASS" "scripts directory exists (build scripts)"
else
    print_status "FAIL" "scripts directory not found"
fi

if [ -d "benches" ]; then
    print_status "PASS" "benches directory exists (benchmark tests)"
else
    print_status "FAIL" "benches directory not found"
fi

if [ -d "devdocs" ]; then
    print_status "PASS" "devdocs directory exists (developer documentation)"
else
    print_status "FAIL" "devdocs directory not found"
fi

if [ -d "docker" ]; then
    print_status "PASS" "docker directory exists (Docker configurations)"
else
    print_status "FAIL" "docker directory not found"
fi

if [ -d "wix" ]; then
    print_status "PASS" "wix directory exists (Windows installer)"
else
    print_status "FAIL" "wix directory not found"
fi

if [ -d "assets" ]; then
    print_status "PASS" "assets directory exists (project assets)"
else
    print_status "FAIL" "assets directory not found"
fi

if [ -d ".cargo" ]; then
    print_status "PASS" ".cargo directory exists (Cargo configuration)"
else
    print_status "FAIL" ".cargo directory not found"
fi

if [ -d ".github" ]; then
    print_status "PASS" ".github directory exists (GitHub workflows)"
else
    print_status "FAIL" ".github directory not found"
fi

if [ -d ".githooks" ]; then
    print_status "PASS" ".githooks directory exists (Git hooks)"
else
    print_status "FAIL" ".githooks directory not found"
fi

if [ -d "clippy" ]; then
    print_status "PASS" "clippy directory exists (clippy configurations)"
else
    print_status "FAIL" "clippy directory not found"
fi

# Check key files
if [ -f "Cargo.toml" ]; then
    print_status "PASS" "Cargo.toml exists (Rust package configuration)"
else
    print_status "FAIL" "Cargo.toml not found"
fi

if [ -f "Cargo.lock" ]; then
    print_status "PASS" "Cargo.lock exists (dependency lock file)"
else
    print_status "FAIL" "Cargo.lock not found"
fi

if [ -f "rust-toolchain.toml" ]; then
    print_status "PASS" "rust-toolchain.toml exists (Rust toolchain configuration)"
else
    print_status "FAIL" "rust-toolchain.toml not found"
fi

if [ -f "Cross.toml" ]; then
    print_status "PASS" "Cross.toml exists (cross-compilation configuration)"
else
    print_status "FAIL" "Cross.toml not found"
fi

if [ -f "toolkit.nu" ]; then
    print_status "PASS" "toolkit.nu exists (Nushell toolkit script)"
else
    print_status "FAIL" "toolkit.nu not found"
fi

if [ -f "typos.toml" ]; then
    print_status "PASS" "typos.toml exists (typo checking configuration)"
else
    print_status "FAIL" "typos.toml not found"
fi

if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
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
    print_status "PASS" "CODE_OF_CONDUCT.md exists (code of conduct)"
else
    print_status "FAIL" "CODE_OF_CONDUCT.md not found"
fi

if [ -f "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md exists (contribution guidelines)"
else
    print_status "FAIL" "CONTRIBUTING.md not found"
fi

if [ -f ".gitignore" ]; then
    print_status "PASS" ".gitignore exists"
else
    print_status "FAIL" ".gitignore not found"
fi

if [ -f ".gitattributes" ]; then
    print_status "PASS" ".gitattributes exists"
else
    print_status "FAIL" ".gitattributes not found"
fi

if [ -f "CITATION.cff" ]; then
    print_status "PASS" "CITATION.cff exists (citation configuration)"
else
    print_status "FAIL" "CITATION.cff not found"
fi

echo ""
echo "3. Checking Environment Variables..."
echo "-----------------------------------"
# Check Rust environment
if [ -n "${CARGO_HOME:-}" ]; then
    print_status "PASS" "CARGO_HOME is set: $CARGO_HOME"
else
    print_status "WARN" "CARGO_HOME is not set"
fi

if [ -n "${RUSTUP_HOME:-}" ]; then
    print_status "PASS" "RUSTUP_HOME is set: $RUSTUP_HOME"
else
    print_status "WARN" "RUSTUP_HOME is not set"
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

if echo "$PATH" | grep -q "gcc"; then
    print_status "PASS" "gcc is in PATH"
else
    print_status "WARN" "gcc is not in PATH"
fi

echo ""
echo "4. Testing Rust Environment..."
echo "-----------------------------"
# Test Rust
if command -v rustc &> /dev/null; then
    print_status "PASS" "rustc is available"
    
    # Test Rust compilation
    if timeout 30s rustc --version >/dev/null 2>&1; then
        print_status "PASS" "Rust version command works"
    else
        print_status "WARN" "Rust version command failed"
    fi
    
    # Test Rust target list
    if timeout 30s rustc --print target-list >/dev/null 2>&1; then
        print_status "PASS" "Rust target list works"
    else
        print_status "WARN" "Rust target list failed"
    fi
else
    print_status "FAIL" "rustc is not available"
fi

echo ""
echo "5. Testing Cargo Environment..."
echo "------------------------------"
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
    
    # Test Cargo check
    if timeout 60s cargo check --quiet >/dev/null 2>&1; then
        print_status "PASS" "Cargo check works"
    else
        print_status "WARN" "Cargo check failed"
    fi
else
    print_status "FAIL" "cargo is not available"
fi

echo ""
echo "6. Testing Nushell Environment..."
echo "--------------------------------"
# Test Nushell
if command -v nu &> /dev/null; then
    print_status "PASS" "nu is available"
    
    # Test Nushell version
    if timeout 30s nu --version >/dev/null 2>&1; then
        print_status "PASS" "Nushell version command works"
    else
        print_status "WARN" "Nushell version command failed"
    fi
    
    # Test Nushell help
    if timeout 30s nu --help >/dev/null 2>&1; then
        print_status "PASS" "Nushell help command works"
    else
        print_status "WARN" "Nushell help command failed"
    fi
    
    # Test Nushell execution
    if timeout 30s nu -c "echo 'Hello from Nushell'" >/dev/null 2>&1; then
        print_status "PASS" "Nushell execution works"
    else
        print_status "WARN" "Nushell execution failed"
    fi
else
    print_status "WARN" "nu is not available"
fi

echo ""
echo "7. Testing Nushell Build System..."
echo "----------------------------------"
# Test Cargo.toml
if [ -f "Cargo.toml" ]; then
    print_status "PASS" "Cargo.toml exists for build testing"
    
    # Check for key package information
    if grep -q "name = \"nu\"" Cargo.toml; then
        print_status "PASS" "Cargo.toml includes package name"
    else
        print_status "FAIL" "Cargo.toml missing package name"
    fi
    
    if grep -q "version" Cargo.toml; then
        print_status "PASS" "Cargo.toml includes version"
    else
        print_status "FAIL" "Cargo.toml missing version"
    fi
    
    if grep -q "edition" Cargo.toml; then
        print_status "PASS" "Cargo.toml includes Rust edition"
    else
        print_status "FAIL" "Cargo.toml missing Rust edition"
    fi
    
    if grep -q "workspace" Cargo.toml; then
        print_status "PASS" "Cargo.toml includes workspace configuration"
    else
        print_status "FAIL" "Cargo.toml missing workspace configuration"
    fi
else
    print_status "FAIL" "Cargo.toml not found"
fi

# Test rust-toolchain.toml
if [ -f "rust-toolchain.toml" ]; then
    print_status "PASS" "rust-toolchain.toml exists"
    
    # Check for toolchain configuration
    if grep -q "channel" rust-toolchain.toml; then
        print_status "PASS" "rust-toolchain.toml includes channel configuration"
    else
        print_status "WARN" "rust-toolchain.toml missing channel configuration"
    fi
    
    if grep -q "profile" rust-toolchain.toml; then
        print_status "PASS" "rust-toolchain.toml includes profile configuration"
    else
        print_status "WARN" "rust-toolchain.toml missing profile configuration"
    fi
else
    print_status "FAIL" "rust-toolchain.toml not found"
fi

# Test Cross.toml
if [ -f "Cross.toml" ]; then
    print_status "PASS" "Cross.toml exists"
    
    # Check for cross-compilation configuration
    if grep -q "target" Cross.toml; then
        print_status "PASS" "Cross.toml includes target configuration"
    else
        print_status "WARN" "Cross.toml missing target configuration"
    fi
else
    print_status "FAIL" "Cross.toml not found"
fi

# Test toolkit.nu
if [ -f "toolkit.nu" ]; then
    print_status "PASS" "toolkit.nu exists"
    
    # Check if it's a valid Nushell script
    if command -v nu &> /dev/null; then
        if timeout 30s nu -c "source toolkit.nu; help" >/dev/null 2>&1; then
            print_status "PASS" "toolkit.nu is a valid Nushell script"
        else
            print_status "WARN" "toolkit.nu may not be a valid Nushell script"
        fi
    else
        print_status "WARN" "nu not available for toolkit.nu testing"
    fi
else
    print_status "FAIL" "toolkit.nu not found"
fi

echo ""
echo "8. Testing Nushell Source Code Structure..."
echo "------------------------------------------"
# Test source code directories
if [ -d "src" ]; then
    print_status "PASS" "src directory exists for source testing"
    
    # Count Rust source files
    rust_files=$(find src -name "*.rs" | wc -l)
    if [ "$rust_files" -gt 0 ]; then
        print_status "PASS" "Found $rust_files Rust source files in src directory"
    else
        print_status "WARN" "No Rust source files found in src directory"
    fi
else
    print_status "FAIL" "src directory not found"
fi

if [ -d "crates" ]; then
    print_status "PASS" "crates directory exists for crate testing"
    
    # Count crate directories
    crate_count=$(find crates -maxdepth 1 -type d | wc -l)
    if [ "$crate_count" -gt 1 ]; then
        print_status "PASS" "Found $((crate_count - 1)) crates in crates directory"
    else
        print_status "WARN" "No crates found in crates directory"
    fi
    
    # Check for key crates
    if [ -d "crates/nu-cli" ]; then
        print_status "PASS" "crates/nu-cli exists (main CLI crate)"
    else
        print_status "FAIL" "crates/nu-cli not found"
    fi
    
    if [ -d "crates/nu-engine" ]; then
        print_status "PASS" "crates/nu-engine exists (engine crate)"
    else
        print_status "FAIL" "crates/nu-engine not found"
    fi
    
    if [ -d "crates/nu-parser" ]; then
        print_status "PASS" "crates/nu-parser exists (parser crate)"
    else
        print_status "FAIL" "crates/nu-parser not found"
    fi
else
    print_status "FAIL" "crates directory not found"
fi

if [ -d "tests" ]; then
    print_status "PASS" "tests directory exists for testing"
    
    # Count test files
    test_count=$(find tests -name "*.rs" | wc -l)
    if [ "$test_count" -gt 0 ]; then
        print_status "PASS" "Found $test_count test files in tests directory"
    else
        print_status "WARN" "No test files found in tests directory"
    fi
else
    print_status "FAIL" "tests directory not found"
fi

if [ -d "benches" ]; then
    print_status "PASS" "benches directory exists for benchmark testing"
    
    # Count benchmark files
    bench_count=$(find benches -name "*.rs" | wc -l)
    if [ "$bench_count" -gt 0 ]; then
        print_status "PASS" "Found $bench_count benchmark files in benches directory"
    else
        print_status "WARN" "No benchmark files found in benches directory"
    fi
else
    print_status "FAIL" "benches directory not found"
fi

echo ""
echo "9. Testing Nushell Configuration Files..."
echo "----------------------------------------"
# Test configuration files
if [ -r "Cargo.toml" ]; then
    print_status "PASS" "Cargo.toml is readable"
else
    print_status "FAIL" "Cargo.toml is not readable"
fi

if [ -r "rust-toolchain.toml" ]; then
    print_status "PASS" "rust-toolchain.toml is readable"
else
    print_status "FAIL" "rust-toolchain.toml is not readable"
fi

if [ -r "Cross.toml" ]; then
    print_status "PASS" "Cross.toml is readable"
else
    print_status "FAIL" "Cross.toml is not readable"
fi

if [ -r "toolkit.nu" ]; then
    print_status "PASS" "toolkit.nu is readable"
else
    print_status "FAIL" "toolkit.nu is not readable"
fi

if [ -r "typos.toml" ]; then
    print_status "PASS" "typos.toml is readable"
else
    print_status "FAIL" "typos.toml is not readable"
fi

# Check Cargo.toml content
if [ -r "Cargo.toml" ]; then
    if grep -q "description" Cargo.toml; then
        print_status "PASS" "Cargo.toml includes description"
    else
        print_status "WARN" "Cargo.toml missing description"
    fi
    
    if grep -q "license" Cargo.toml; then
        print_status "PASS" "Cargo.toml includes license"
    else
        print_status "WARN" "Cargo.toml missing license"
    fi
    
    if grep -q "repository" Cargo.toml; then
        print_status "PASS" "Cargo.toml includes repository"
    else
        print_status "WARN" "Cargo.toml missing repository"
    fi
fi

# Check rust-toolchain.toml content
if [ -r "rust-toolchain.toml" ]; then
    if grep -q "1.86.0" rust-toolchain.toml; then
        print_status "PASS" "rust-toolchain.toml specifies Rust 1.86.0"
    else
        print_status "WARN" "rust-toolchain.toml missing Rust 1.86.0 specification"
    fi
fi

echo ""
echo "10. Testing Nushell Documentation..."
echo "-----------------------------------"
# Test documentation
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

if [ -r ".gitignore" ]; then
    print_status "PASS" ".gitignore is readable"
else
    print_status "FAIL" ".gitignore is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "Nushell" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "shell" README.md; then
        print_status "PASS" "README.md contains shell reference"
    else
        print_status "WARN" "README.md missing shell reference"
    fi
    
    if grep -q "Rust" README.md; then
        print_status "PASS" "README.md contains Rust reference"
    else
        print_status "WARN" "README.md missing Rust reference"
    fi
fi

echo ""
echo "11. Testing Nushell Docker Functionality..."
echo "------------------------------------------"
# Test if Docker container can run basic commands
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test Rust in Docker
    if docker run --rm nushell-env-test rustc --version >/dev/null 2>&1; then
        print_status "PASS" "Rust works in Docker container"
    else
        print_status "FAIL" "Rust does not work in Docker container"
    fi
    
    # Test Cargo in Docker
    if docker run --rm nushell-env-test cargo --version >/dev/null 2>&1; then
        print_status "PASS" "Cargo works in Docker container"
    else
        print_status "FAIL" "Cargo does not work in Docker container"
    fi
    
    # Test Nushell in Docker
    if docker run --rm nushell-env-test nu --version >/dev/null 2>&1; then
        print_status "PASS" "Nushell works in Docker container"
    else
        print_status "FAIL" "Nushell does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm nushell-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test GCC in Docker
    if docker run --rm nushell-env-test gcc --version >/dev/null 2>&1; then
        print_status "PASS" "GCC works in Docker container"
    else
        print_status "FAIL" "GCC does not work in Docker container"
    fi
    
    # Test if Cargo.toml is accessible in Docker
    if docker run --rm nushell-env-test test -f Cargo.toml; then
        print_status "PASS" "Cargo.toml is accessible in Docker container"
    else
        print_status "FAIL" "Cargo.toml is not accessible in Docker container"
    fi
    
    # Test if rust-toolchain.toml is accessible in Docker
    if docker run --rm nushell-env-test test -f rust-toolchain.toml; then
        print_status "PASS" "rust-toolchain.toml is accessible in Docker container"
    else
        print_status "FAIL" "rust-toolchain.toml is not accessible in Docker container"
    fi
    
    # Test if src directory is accessible in Docker
    if docker run --rm nushell-env-test test -d src; then
        print_status "PASS" "src directory is accessible in Docker container"
    else
        print_status "FAIL" "src directory is not accessible in Docker container"
    fi
    
    # Test if crates directory is accessible in Docker
    if docker run --rm nushell-env-test test -d crates; then
        print_status "PASS" "crates directory is accessible in Docker container"
    else
        print_status "FAIL" "crates directory is not accessible in Docker container"
    fi
    
    # Test if tests directory is accessible in Docker
    if docker run --rm nushell-env-test test -d tests; then
        print_status "PASS" "tests directory is accessible in Docker container"
    else
        print_status "FAIL" "tests directory is not accessible in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm nushell-env-test test -f README.md; then
        print_status "PASS" "README.md is accessible in Docker container"
    else
        print_status "FAIL" "README.md is not accessible in Docker container"
    fi
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for Nushell:"
echo "- Docker build process (Ubuntu 22.04, Rust 1.86.0, Cargo, Nushell 0.92.1)"
echo "- Rust environment (compilation, toolchain, dependencies)"
echo "- Cargo environment (package management, build system)"
echo "- Nushell build system (Cargo.toml, rust-toolchain.toml, Cross.toml, toolkit.nu)"
echo "- Nushell source code structure (src, crates, tests, benches)"
echo "- Nushell configuration files (Rust, Cargo, cross-compilation, toolkit)"
echo "- Nushell documentation (README.md, LICENSE, SECURITY.md, CONTRIBUTING.md)"
echo "- Docker container functionality (Rust, Cargo, Nushell, Git, GCC)"
echo "- Modern shell (Rust-based, structured data, pipelines)"
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
    print_status "INFO" "All Docker tests passed! Your Nushell Docker environment is ready!"
    print_status "INFO" "Nushell is a new type of shell with structured data and pipelines."
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your Nushell Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now run Nushell in Docker: A new type of shell."
print_status "INFO" "Example: docker run --rm nushell-env-test cargo build"
print_status "INFO" "Example: docker run --rm nushell-env-test nu --version"
echo ""
print_status "INFO" "For more information, see README.md and https://github.com/nushell/nushell"

# Write results to JSON
write_results_to_json

exit 0
fi

# If Docker failed or not available, skip local environment tests
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ] || [ "${DOCKER_MODE:-false}" = "false" ]; then
    echo "Docker environment not available - skipping local environment tests"
    echo "This script is designed to test Docker environment only"
    exit 0
fi 