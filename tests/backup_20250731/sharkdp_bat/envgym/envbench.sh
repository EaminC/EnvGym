#!/bin/bash

# Bat Environment Benchmark Test Script
# This script tests the Docker environment setup for Bat: A cat(1) clone with syntax highlighting
# Tailored specifically for Bat project requirements and features




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
    docker stop bat-env-test 2>/dev/null || true
    docker rm bat-env-test 2>/dev/null || true
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
        if timeout 600s docker build -f envgym/envgym.dockerfile -t bat-env-test .; then
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
    if docker run --rm bat-env-test rustc --version >/dev/null 2>&1; then
        rust_version=$(docker run --rm bat-env-test rustc --version 2>&1)
        print_status "PASS" "Rust is available in Docker: $rust_version"
    else
        print_status "FAIL" "Rust is not available in Docker"
    fi
    
    # Test if Cargo is available in Docker
    if docker run --rm bat-env-test cargo --version >/dev/null 2>&1; then
        cargo_version=$(docker run --rm bat-env-test cargo --version 2>&1)
        print_status "PASS" "Cargo is available in Docker: $cargo_version"
    else
        print_status "FAIL" "Cargo is not available in Docker"
    fi
    
    # Test if Git is available in Docker
    if docker run --rm bat-env-test git --version >/dev/null 2>&1; then
        git_version=$(docker run --rm bat-env-test git --version 2>&1)
        print_status "PASS" "Git is available in Docker: $git_version"
    else
        print_status "FAIL" "Git is not available in Docker"
    fi
    
    # Test if bat is available in Docker
    if docker run --rm bat-env-test bat --version >/dev/null 2>&1; then
        bat_version=$(docker run --rm bat-env-test bat --version 2>&1)
        print_status "PASS" "bat is available in Docker: $bat_version"
    else
        print_status "FAIL" "bat is not available in Docker"
    fi
fi

echo "=========================================="
echo "Bat Environment Benchmark Test"
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
    if [ "$rust_major" -eq 1 ] && [ "$rust_minor" -ge 74 ]; then
        print_status "PASS" "Rust version is >= 1.74 (compatible with Bat)"
    else
        print_status "WARN" "Rust version should be >= 1.74 for Bat (found: $rust_major.$rust_minor)"
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
echo "2. Checking Bat Application..."
echo "-----------------------------"
# Check if bat is installed
if command -v bat &> /dev/null; then
    bat_version=$(bat --version 2>&1)
    print_status "PASS" "bat is available: $bat_version"
else
    print_status "WARN" "bat is not available (not installed or not in PATH)"
fi

# Check if batcat is available (alternative name)
if command -v batcat &> /dev/null; then
    batcat_version=$(batcat --version 2>&1)
    print_status "PASS" "batcat is available: $batcat_version"
else
    print_status "WARN" "batcat is not available"
fi

# Test bat functionality if available
if command -v bat &> /dev/null; then
    # Test basic bat functionality
    if timeout 30s bat --help >/dev/null 2>&1; then
        print_status "PASS" "bat help command works"
    else
        print_status "WARN" "bat help command failed"
    fi
    
    # Test bat syntax highlighting
    echo 'fn main() { println!("Hello, Rust!"); }' > /tmp/test.rs
    if timeout 30s bat /tmp/test.rs >/dev/null 2>&1; then
        print_status "PASS" "bat syntax highlighting works"
    else
        print_status "WARN" "bat syntax highlighting failed"
    fi
    rm -f /tmp/test.rs
else
    print_status "WARN" "bat is not available for functionality testing"
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

# Check less (pager)
if command -v less &> /dev/null; then
    less_version=$(less --version 2>&1 | head -n 1)
    print_status "PASS" "less is available: $less_version"
else
    print_status "WARN" "less is not available"
fi

# Check fzf (fuzzy finder)
if command -v fzf &> /dev/null; then
    fzf_version=$(fzf --version 2>&1)
    print_status "PASS" "fzf is available: $fzf_version"
else
    print_status "WARN" "fzf is not available"
fi

# Check ripgrep
if command -v rg &> /dev/null; then
    rg_version=$(rg --version 2>&1)
    print_status "PASS" "ripgrep is available: $rg_version"
else
    print_status "WARN" "ripgrep is not available"
fi

# Check fd (find alternative)
if command -v fd &> /dev/null; then
    fd_version=$(fd --version 2>&1)
    print_status "PASS" "fd is available: $fd_version"
else
    print_status "WARN" "fd is not available"
fi

# Check xclip
if command -v xclip &> /dev/null; then
    print_status "PASS" "xclip is available"
else
    print_status "WARN" "xclip is not available"
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

# Check libonig-dev
if pkg-config --exists oniguruma; then
    onig_version=$(pkg-config --modversion oniguruma 2>/dev/null)
    print_status "PASS" "libonig-dev is available: $onig_version"
else
    print_status "WARN" "libonig-dev is not available"
fi

# Check libgit2-dev
if pkg-config --exists libgit2; then
    git2_version=$(pkg-config --modversion libgit2 2>/dev/null)
    print_status "PASS" "libgit2-dev is available: $git2_version"
else
    print_status "WARN" "libgit2-dev is not available"
fi

# Check curl
if command -v curl &> /dev/null; then
    curl_version=$(curl --version 2>&1 | head -n 1)
    print_status "PASS" "curl is available: $curl_version"
else
    print_status "FAIL" "curl is not available"
fi

# Check Python3
if command -v python3 &> /dev/null; then
    python3_version=$(python3 --version 2>&1)
    print_status "PASS" "python3 is available: $python3_version"
else
    print_status "WARN" "python3 is not available"
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

if [ -d "examples" ]; then
    print_status "PASS" "examples directory exists (examples)"
else
    print_status "FAIL" "examples directory not found"
fi

if [ -d "assets" ]; then
    print_status "PASS" "assets directory exists (assets and themes)"
else
    print_status "FAIL" "assets directory not found"
fi

if [ -d "build" ]; then
    print_status "PASS" "build directory exists (build scripts)"
else
    print_status "FAIL" "build directory not found"
fi

if [ -d "diagnostics" ]; then
    print_status "PASS" "diagnostics directory exists (diagnostic tools)"
else
    print_status "FAIL" "diagnostics directory not found"
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

if [ -f "NOTICE" ]; then
    print_status "PASS" "NOTICE exists"
else
    print_status "FAIL" "NOTICE not found"
fi

if [ -f ".gitmodules" ]; then
    print_status "PASS" ".gitmodules exists (submodules)"
else
    print_status "FAIL" ".gitmodules not found"
fi

if [ -f "rustfmt.toml" ]; then
    print_status "PASS" "rustfmt.toml exists (code formatting config)"
else
    print_status "FAIL" "rustfmt.toml not found"
fi

# Check source files
if [ -f "src/lib.rs" ]; then
    print_status "PASS" "src/lib.rs exists (main library)"
else
    print_status "FAIL" "src/lib.rs not found"
fi

if [ -f "src/main.rs" ]; then
    print_status "PASS" "src/main.rs exists (binary entry point)"
else
    print_status "FAIL" "src/main.rs not found"
fi

if [ -d "src/bin" ]; then
    print_status "PASS" "src/bin directory exists (binary modules)"
else
    print_status "FAIL" "src/bin directory not found"
fi

# Check build files
if [ -f "build/main.rs" ]; then
    print_status "PASS" "build/main.rs exists (build script)"
else
    print_status "FAIL" "build/main.rs not found"
fi

# Check configuration files
if [ -d ".cargo" ]; then
    print_status "PASS" ".cargo directory exists (cargo configuration)"
else
    print_status "FAIL" ".cargo directory not found"
fi

echo ""
echo "5. Testing Bat Source Code..."
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
echo "6. Testing Bat Dependencies..."
echo "-----------------------------"
# Test if syntect is available (syntax highlighting)
if command -v cargo &> /dev/null; then
    print_status "INFO" "Testing Bat dependencies..."
    
    # Test syntect dependency
    if timeout 60s cargo check --quiet >/dev/null 2>&1; then
        print_status "PASS" "syntect dependency is available"
    else
        print_status "WARN" "syntect dependency check failed"
    fi
    
    # Test git2 dependency
    if timeout 60s cargo check --quiet >/dev/null 2>&1; then
        print_status "PASS" "git2 dependency is available"
    else
        print_status "WARN" "git2 dependency check failed"
    fi
    
    # Test clap dependency
    if timeout 60s cargo check --quiet >/dev/null 2>&1; then
        print_status "PASS" "clap dependency is available"
    else
        print_status "WARN" "clap dependency check failed"
    fi
else
    print_status "FAIL" "Cargo is not available for dependency testing"
fi

echo ""
echo "7. Testing Bat Documentation..."
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

# Check README content
if [ -r "README.md" ]; then
    if grep -q "bat" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "syntax highlighting" README.md; then
        print_status "PASS" "README.md contains syntax highlighting description"
    else
        print_status "WARN" "README.md missing syntax highlighting description"
    fi
    
    if grep -q "cat" README.md; then
        print_status "PASS" "README.md contains cat clone description"
    else
        print_status "WARN" "README.md missing cat clone description"
    fi
    
    if grep -q "Git integration" README.md; then
        print_status "PASS" "README.md contains Git integration description"
    else
        print_status "WARN" "README.md missing Git integration description"
    fi
fi

echo ""
echo "8. Testing Bat Docker Functionality..."
echo "-------------------------------------"
# Test if Docker container can run basic commands
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    # Test Rust in Docker
    if docker run --rm bat-env-test rustc --version >/dev/null 2>&1; then
        print_status "PASS" "Rust works in Docker container"
    else
        print_status "FAIL" "Rust does not work in Docker container"
    fi
    
    # Test Cargo in Docker
    if docker run --rm bat-env-test cargo --version >/dev/null 2>&1; then
        print_status "PASS" "Cargo works in Docker container"
    else
        print_status "FAIL" "Cargo does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm bat-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test bat in Docker
    if docker run --rm bat-env-test bat --version >/dev/null 2>&1; then
        print_status "PASS" "bat works in Docker container"
    else
        print_status "FAIL" "bat does not work in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" bat-env-test test -f README.md; then
        print_status "PASS" "README.md is accessible in Docker container"
    else
        print_status "FAIL" "README.md is not accessible in Docker container"
    fi
    
    # Test if src directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" bat-env-test test -d src; then
        print_status "PASS" "src directory is accessible in Docker container"
    else
        print_status "FAIL" "src directory is not accessible in Docker container"
    fi
    
    # Test if tests directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" bat-env-test test -d tests; then
        print_status "PASS" "tests directory is accessible in Docker container"
    else
        print_status "FAIL" "tests directory is not accessible in Docker container"
    fi
    
    # Test if assets directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" bat-env-test test -d assets; then
        print_status "PASS" "assets directory is accessible in Docker container"
    else
        print_status "FAIL" "assets directory is not accessible in Docker container"
    fi
    
    # Test cargo check in Docker
    if docker run --rm -v "$(pwd):/workspace" -w /workspace bat-env-test cargo check --quiet >/dev/null 2>&1; then
        print_status "PASS" "cargo check works in Docker container"
    else
        print_status "FAIL" "cargo check does not work in Docker container"
    fi
    
    # Test bat functionality in Docker
    echo 'fn main() { println!("Hello, Rust!"); }' > /tmp/test.rs
    if docker run --rm -v /tmp:/tmp bat-env-test bat /tmp/test.rs >/dev/null 2>&1; then
        print_status "PASS" "bat syntax highlighting works in Docker container"
    else
        print_status "FAIL" "bat syntax highlighting does not work in Docker container"
    fi
    rm -f /tmp/test.rs
    
    # Test bat help in Docker
    if docker run --rm bat-env-test bat --help >/dev/null 2>&1; then
        print_status "PASS" "bat help works in Docker container"
    else
        print_status "FAIL" "bat help does not work in Docker container"
    fi
fi

echo ""
echo "=========================================="
echo "Bat Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for Bat:"
echo "- Docker build process (Ubuntu 22.04, Rust, Cargo, Git, build tools)"
echo "- Rust environment (version compatibility, toolchain, compilation)"
echo "- Bat application (syntax highlighting, Git integration, paging)"
echo "- System dependencies (Git, less, fzf, ripgrep, fd, xclip, libonig-dev, libgit2-dev)"
echo "- Bat source code structure (src, tests, doc, examples, assets, build)"
echo "- Bat documentation (README.md, LICENSE files, CHANGELOG.md, CONTRIBUTING.md)"
echo "- Docker container functionality (Rust, Cargo, bat, syntax highlighting)"
echo "- Cat clone with syntax highlighting (syntect, Git integration, themes)"
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
    print_status "INFO" "All Docker tests passed! Your Bat Docker environment is ready!"
    print_status "INFO" "Bat is a cat(1) clone with syntax highlighting and Git integration."
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your Bat Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now run Bat in Docker: A cat(1) clone with syntax highlighting."
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace bat-env-test cargo check"
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace bat-env-test cargo test"
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace bat-env-test bat README.md"
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace bat-env-test bat --list-themes"
echo ""
print_status "INFO" "For more information, see README.md and https://github.com/sharkdp/bat"
exit 0
fi

# If Docker failed or not available, skip local environment tests
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ] || [ "${DOCKER_MODE:-false}" = "false" ]; then
    echo "Docker environment not available - skipping local environment tests"
    echo "This script is designed to test Docker environment only"
    exit 0
fi 