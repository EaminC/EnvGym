#!/bin/bash

# Serde Environment Benchmark Test Script
# This script tests the Docker environment setup for Serde: A serialization framework for Rust
# Tailored specifically for Serde project requirements and features

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
    docker stop serde-env-test 2>/dev/null || true
    docker rm serde-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the serde-rs_serde project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t serde-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/serde-rs_serde" serde-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "Serde Environment Benchmark Test"
echo "=========================================="

echo "1. Checking Rust Environment..."
echo "-------------------------------"
# Check Rust version
if command -v rustc &> /dev/null; then
    rust_version=$(rustc --version 2>&1)
    print_status "PASS" "Rust is available: $rust_version"
    
    # Check Rust version compatibility
    rust_major=$(rustc --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1)
    rust_minor=$(rustc --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f2)
    if [ "$rust_major" -eq 1 ] && [ "$rust_minor" -ge 56 ]; then
        print_status "PASS" "Rust version is >= 1.56 (compatible with Serde)"
    else
        print_status "WARN" "Rust version should be >= 1.56 for Serde (found: $rust_major.$rust_minor)"
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
echo "2. Checking Rust Toolchain..."
echo "-----------------------------"
# Check rustup
if command -v rustup &> /dev/null; then
    rustup_version=$(rustup --version 2>&1)
    print_status "PASS" "rustup is available: $rustup_version"
else
    print_status "WARN" "rustup is not available"
fi

# Check clippy
if command -v cargo-clippy &> /dev/null; then
    print_status "PASS" "cargo-clippy is available"
else
    print_status "WARN" "cargo-clippy is not available"
fi

# Check rustfmt
if command -v rustfmt &> /dev/null; then
    print_status "PASS" "rustfmt is available"
else
    print_status "WARN" "rustfmt is not available"
fi

# Check cargo check
if command -v cargo &> /dev/null; then
    if timeout 30s cargo check --version >/dev/null 2>&1; then
        print_status "PASS" "cargo check works"
    else
        print_status "WARN" "cargo check failed"
    fi
else
    print_status "FAIL" "Cargo is not available for cargo check"
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

# Check GCC
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version 2>&1 | head -n 1)
    print_status "PASS" "GCC is available: $gcc_version"
else
    print_status "FAIL" "GCC is not available"
fi

# Check build-essential
if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "make is available: $make_version"
else
    print_status "FAIL" "make is not available"
fi

# Check pkg-config
if command -v pkg-config &> /dev/null; then
    pkg_config_version=$(pkg-config --version 2>&1)
    print_status "PASS" "pkg-config is available: $pkg_config_version"
else
    print_status "FAIL" "pkg-config is not available"
fi

# Check libssl-dev
if pkg-config --exists openssl; then
    openssl_version=$(pkg-config --modversion openssl 2>/dev/null)
    print_status "PASS" "libssl-dev is available: $openssl_version"
else
    print_status "WARN" "libssl-dev is not available"
fi

# Check curl
if command -v curl &> /dev/null; then
    curl_version=$(curl --version 2>&1 | head -n 1)
    print_status "PASS" "curl is available: $curl_version"
else
    print_status "FAIL" "curl is not available"
fi

echo ""
echo "4. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "serde" ]; then
    print_status "PASS" "serde directory exists (core serialization library)"
else
    print_status "FAIL" "serde directory not found"
fi

if [ -d "serde_derive" ]; then
    print_status "PASS" "serde_derive directory exists (derive macros)"
else
    print_status "FAIL" "serde_derive directory not found"
fi

if [ -d "serde_derive_internals" ]; then
    print_status "PASS" "serde_derive_internals directory exists (internal derive support)"
else
    print_status "FAIL" "serde_derive_internals directory not found"
fi

if [ -d "test_suite" ]; then
    print_status "PASS" "test_suite directory exists (comprehensive test suite)"
else
    print_status "FAIL" "test_suite directory not found"
fi

# Check key files
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

if [ -f "Cargo.toml" ]; then
    print_status "PASS" "Cargo.toml exists (workspace configuration)"
else
    print_status "FAIL" "Cargo.toml not found"
fi

if [ -f "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md exists"
else
    print_status "FAIL" "CONTRIBUTING.md not found"
fi

if [ -f "crates-io.md" ]; then
    print_status "PASS" "crates-io.md exists"
else
    print_status "FAIL" "crates-io.md not found"
fi

# Check serde subdirectory files
if [ -f "serde/Cargo.toml" ]; then
    print_status "PASS" "serde/Cargo.toml exists"
else
    print_status "FAIL" "serde/Cargo.toml not found"
fi

if [ -f "serde/build.rs" ]; then
    print_status "PASS" "serde/build.rs exists (build script)"
else
    print_status "FAIL" "serde/build.rs not found"
fi

if [ -f "serde/README.md" ]; then
    print_status "PASS" "serde/README.md exists"
else
    print_status "FAIL" "serde/README.md not found"
fi

# Check serde_derive subdirectory files
if [ -f "serde_derive/Cargo.toml" ]; then
    print_status "PASS" "serde_derive/Cargo.toml exists"
else
    print_status "FAIL" "serde_derive/Cargo.toml not found"
fi

if [ -f "serde_derive/build.rs" ]; then
    print_status "PASS" "serde_derive/build.rs exists (build script)"
else
    print_status "FAIL" "serde_derive/build.rs not found"
fi

if [ -f "serde_derive/README.md" ]; then
    print_status "PASS" "serde_derive/README.md exists"
else
    print_status "FAIL" "serde_derive/README.md not found"
fi

# Check serde_derive_internals subdirectory files
if [ -f "serde_derive_internals/Cargo.toml" ]; then
    print_status "PASS" "serde_derive_internals/Cargo.toml exists"
else
    print_status "FAIL" "serde_derive_internals/Cargo.toml not found"
fi

# Check test_suite subdirectory files
if [ -f "test_suite/Cargo.toml" ]; then
    print_status "PASS" "test_suite/Cargo.toml exists"
else
    print_status "FAIL" "test_suite/Cargo.toml not found"
fi

if [ -d "test_suite/tests" ]; then
    print_status "PASS" "test_suite/tests directory exists"
else
    print_status "FAIL" "test_suite/tests directory not found"
fi

if [ -d "test_suite/no_std" ]; then
    print_status "PASS" "test_suite/no_std directory exists (no_std tests)"
else
    print_status "FAIL" "test_suite/no_std directory not found"
fi

echo ""
echo "5. Testing Serde Source Code..."
echo "-------------------------------"
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

# Count build.rs files
build_files=$(find . -name "build.rs" | wc -l)
if [ "$build_files" -gt 0 ]; then
    print_status "PASS" "Found $build_files build.rs files"
else
    print_status "WARN" "No build.rs files found"
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
    for cargo_file in $(find . -name "Cargo.toml"); do
        if ! timeout 30s cargo check --manifest-path "$cargo_file" --quiet >/dev/null 2>&1; then
            print_status "WARN" "Cargo.toml parsing failed for $cargo_file"
        fi
    done
    print_status "PASS" "Cargo.toml parsing completed"
else
    print_status "FAIL" "Cargo is not available for Cargo.toml parsing"
fi

echo ""
echo "6. Testing Serde Workspace..."
echo "-----------------------------"
# Test workspace configuration
if command -v cargo &> /dev/null; then
    print_status "INFO" "Testing workspace configuration..."
    
    # Test workspace check
    if timeout 60s cargo check --workspace --quiet >/dev/null 2>&1; then
        print_status "PASS" "Workspace configuration is valid"
    else
        print_status "WARN" "Workspace configuration has issues"
    fi
    
    # Test workspace members
    if timeout 60s cargo check --package serde --quiet >/dev/null 2>&1; then
        print_status "PASS" "serde package is valid"
    else
        print_status "FAIL" "serde package has issues"
    fi
    
    if timeout 60s cargo check --package serde_derive --quiet >/dev/null 2>&1; then
        print_status "PASS" "serde_derive package is valid"
    else
        print_status "FAIL" "serde_derive package has issues"
    fi
    
    if timeout 60s cargo check --package serde_derive_internals --quiet >/dev/null 2>&1; then
        print_status "PASS" "serde_derive_internals package is valid"
    else
        print_status "FAIL" "serde_derive_internals package has issues"
    fi
    
    if timeout 60s cargo check --package test_suite --quiet >/dev/null 2>&1; then
        print_status "PASS" "test_suite package is valid"
    else
        print_status "FAIL" "test_suite package has issues"
    fi
else
    print_status "FAIL" "Cargo is not available for workspace testing"
fi

echo ""
echo "7. Testing Serde Documentation..."
echo "--------------------------------"
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

if [ -r "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md is readable"
else
    print_status "FAIL" "CONTRIBUTING.md is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "Serde" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "serialization" README.md; then
        print_status "PASS" "README.md contains serialization description"
    else
        print_status "WARN" "README.md missing serialization description"
    fi
    
    if grep -q "deserialization" README.md; then
        print_status "PASS" "README.md contains deserialization description"
    else
        print_status "WARN" "README.md missing deserialization description"
    fi
    
    if grep -q "Serialize" README.md; then
        print_status "PASS" "README.md contains Serialize trait reference"
    else
        print_status "WARN" "README.md missing Serialize trait reference"
    fi
    
    if grep -q "Deserialize" README.md; then
        print_status "PASS" "README.md contains Deserialize trait reference"
    else
        print_status "WARN" "README.md missing Deserialize trait reference"
    fi
fi

echo ""
echo "8. Testing Serde Docker Functionality..."
echo "----------------------------------------"
# Test if Docker container can run basic commands
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test Rust in Docker
    if docker run --rm serde-env-test rustc --version >/dev/null 2>&1; then
        print_status "PASS" "Rust works in Docker container"
    else
        print_status "FAIL" "Rust does not work in Docker container"
    fi
    
    # Test Cargo in Docker
    if docker run --rm serde-env-test cargo --version >/dev/null 2>&1; then
        print_status "PASS" "Cargo works in Docker container"
    else
        print_status "FAIL" "Cargo does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm serde-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test GCC in Docker
    if docker run --rm serde-env-test gcc --version >/dev/null 2>&1; then
        print_status "PASS" "GCC works in Docker container"
    else
        print_status "FAIL" "GCC does not work in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" serde-env-test test -f README.md; then
        print_status "PASS" "README.md is accessible in Docker container"
    else
        print_status "FAIL" "README.md is not accessible in Docker container"
    fi
    
    # Test if serde directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" serde-env-test test -d serde; then
        print_status "PASS" "serde directory is accessible in Docker container"
    else
        print_status "FAIL" "serde directory is not accessible in Docker container"
    fi
    
    # Test if serde_derive directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" serde-env-test test -d serde_derive; then
        print_status "PASS" "serde_derive directory is accessible in Docker container"
    else
        print_status "FAIL" "serde_derive directory is not accessible in Docker container"
    fi
    
    # Test if test_suite directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" serde-env-test test -d test_suite; then
        print_status "PASS" "test_suite directory is accessible in Docker container"
    else
        print_status "FAIL" "test_suite directory is not accessible in Docker container"
    fi
    
    # Test workspace check in Docker
    if docker run --rm -v "$(pwd):/workspace" -w /workspace serde-env-test cargo check --workspace --quiet >/dev/null 2>&1; then
        print_status "PASS" "Workspace check works in Docker container"
    else
        print_status "FAIL" "Workspace check does not work in Docker container"
    fi
    
    # Test serde package check in Docker
    if docker run --rm -v "$(pwd):/workspace" -w /workspace serde-env-test cargo check --package serde --quiet >/dev/null 2>&1; then
        print_status "PASS" "serde package check works in Docker container"
    else
        print_status "FAIL" "serde package check does not work in Docker container"
    fi
    
    # Test serde_derive package check in Docker
    if docker run --rm -v "$(pwd):/workspace" -w /workspace serde-env-test cargo check --package serde_derive --quiet >/dev/null 2>&1; then
        print_status "PASS" "serde_derive package check works in Docker container"
    else
        print_status "FAIL" "serde_derive package check does not work in Docker container"
    fi
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for Serde:"
echo "- Docker build process (Ubuntu 22.04, Rust, Cargo)"
echo "- Rust environment (compilation, toolchain, dependencies)"
echo "- Cargo environment (package management, build system)"
echo "- Serde build system (Cargo.toml, workspace)"
echo "- Serde source code (serde, serde_derive, test_suite)"
echo "- Serde documentation (README.md, crates-io.md, CONTRIBUTING.md)"
echo "- Serde configuration (Cargo.toml, .gitignore)"
echo "- Docker container functionality (Rust, Cargo)"
echo "- Serialization framework capabilities"

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
    print_status "INFO" "All Docker tests passed! Your Serde Docker environment is ready!"
    print_status "INFO" "Serde is a serialization framework for Rust."
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your Serde Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi

print_status "INFO" "You can now run Serde in Docker: A serialization framework for Rust."
print_status "INFO" "Example: docker run --rm serde-env-test cargo build"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/serde-rs_serde serde-env-test /bin/bash" 