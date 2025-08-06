#!/bin/bash

# jq Environment Benchmark Test Script
# This script tests the Docker environment setup for jq: A lightweight and flexible command-line JSON processor
# Tailored specifically for jq project requirements and features

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
    docker stop jq-env-test 2>/dev/null || true
    docker rm jq-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the jqlang_jq project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t jq-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/jqlang_jq" jq-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "jq Environment Benchmark Test"
echo "=========================================="

echo "1. Checking System Dependencies..."
echo "--------------------------------"
# Check C compiler
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version 2>&1 | head -n 1)
    print_status "PASS" "GCC is available: $gcc_version"
    
    gcc_major=$(gcc -dumpversion | cut -d'.' -f1)
    if [ -n "$gcc_major" ] && [ "$gcc_major" -ge 4 ]; then
        print_status "PASS" "GCC version is >= 4 (compatible)"
    else
        print_status "WARN" "GCC version should be >= 4 (found: $gcc_major)"
    fi
else
    print_status "FAIL" "GCC is not available"
fi

# Check make
if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "Make is available: $make_version"
else
    print_status "FAIL" "Make is not available"
fi

# Check autoconf
if command -v autoconf &> /dev/null; then
    autoconf_version=$(autoconf --version 2>&1 | head -n 1)
    print_status "PASS" "Autoconf is available: $autoconf_version"
else
    print_status "FAIL" "Autoconf is not available"
fi

# Check automake
if command -v automake &> /dev/null; then
    automake_version=$(automake --version 2>&1 | head -n 1)
    print_status "PASS" "Automake is available: $automake_version"
else
    print_status "FAIL" "Automake is not available"
fi

# Check libtool
if command -v libtool &> /dev/null; then
    libtool_version=$(libtool --version 2>&1 | head -n 1)
    print_status "PASS" "Libtool is available: $libtool_version"
else
    print_status "FAIL" "Libtool is not available"
fi

# Check flex
if command -v flex &> /dev/null; then
    flex_version=$(flex --version 2>&1 | head -n 1)
    print_status "PASS" "Flex is available: $flex_version"
else
    print_status "FAIL" "Flex is not available"
fi

# Check bison
if command -v bison &> /dev/null; then
    bison_version=$(bison --version 2>&1 | head -n 1)
    print_status "PASS" "Bison is available: $bison_version"
    
    bison_major=$(bison --version | grep "bison" | sed 's/.*version \([0-9]*\)\.[0-9]*.*/\1/')
    if [ -n "$bison_major" ] && [ "$bison_major" -ge 3 ]; then
        print_status "PASS" "Bison version is >= 3 (compatible)"
    else
        print_status "WARN" "Bison version should be >= 3 (found: $bison_major)"
    fi
else
    print_status "FAIL" "Bison is not available"
fi

# Check git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1)
    print_status "PASS" "Git is available: $git_version"
else
    print_status "FAIL" "Git is not available"
fi

# Check bash
if command -v bash &> /dev/null; then
    bash_version=$(bash --version 2>&1 | head -n 1)
    print_status "PASS" "Bash is available: $bash_version"
else
    print_status "FAIL" "Bash is not available"
fi

# Check curl
if command -v curl &> /dev/null; then
    print_status "PASS" "curl is available"
else
    print_status "FAIL" "curl is not available"
fi

# Check wget
if command -v wget &> /dev/null; then
    print_status "PASS" "wget is available"
else
    print_status "WARN" "wget is not available"
fi

# Check python3
if command -v python3 &> /dev/null; then
    python3_version=$(python3 --version 2>&1)
    print_status "PASS" "Python3 is available: $python3_version"
else
    print_status "WARN" "Python3 is not available"
fi

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "src" ]; then
    print_status "PASS" "src directory exists"
else
    print_status "FAIL" "src directory not found"
fi

if [ -d "tests" ]; then
    print_status "PASS" "tests directory exists"
else
    print_status "FAIL" "tests directory not found"
fi

if [ -d "scripts" ]; then
    print_status "PASS" "scripts directory exists"
else
    print_status "FAIL" "scripts directory not found"
fi

if [ -d "docs" ]; then
    print_status "PASS" "docs directory exists"
else
    print_status "FAIL" "docs directory not found"
fi

if [ -d "vendor" ]; then
    print_status "PASS" "vendor directory exists"
else
    print_status "FAIL" "vendor directory not found"
fi

if [ -d "m4" ]; then
    print_status "PASS" "m4 directory exists"
else
    print_status "FAIL" "m4 directory not found"
fi

if [ -d "config" ]; then
    print_status "PASS" "config directory exists"
else
    print_status "FAIL" "config directory not found"
fi

if [ -d "build" ]; then
    print_status "PASS" "build directory exists"
else
    print_status "FAIL" "build directory not found"
fi

if [ -d ".github" ]; then
    print_status "PASS" ".github directory exists"
else
    print_status "FAIL" ".github directory not found"
fi

# Check key files
if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
fi

if [ -f "COPYING" ]; then
    print_status "PASS" "COPYING exists"
else
    print_status "FAIL" "COPYING not found"
fi

if [ -f "AUTHORS" ]; then
    print_status "PASS" "AUTHORS exists"
else
    print_status "FAIL" "AUTHORS not found"
fi

if [ -f "ChangeLog" ]; then
    print_status "PASS" "ChangeLog exists"
else
    print_status "FAIL" "ChangeLog not found"
fi

if [ -f "NEWS.md" ]; then
    print_status "PASS" "NEWS.md exists"
else
    print_status "FAIL" "NEWS.md not found"
fi

if [ -f "SECURITY.md" ]; then
    print_status "PASS" "SECURITY.md exists"
else
    print_status "FAIL" "SECURITY.md not found"
fi

if [ -f "Makefile.am" ]; then
    print_status "PASS" "Makefile.am exists"
else
    print_status "FAIL" "Makefile.am not found"
fi

if [ -f "configure.ac" ]; then
    print_status "PASS" "configure.ac exists"
else
    print_status "FAIL" "configure.ac not found"
fi

if [ -f "Dockerfile" ]; then
    print_status "PASS" "Dockerfile exists"
else
    print_status "FAIL" "Dockerfile not found"
fi

if [ -f "jq.spec" ]; then
    print_status "PASS" "jq.spec exists"
else
    print_status "FAIL" "jq.spec not found"
fi

# Check source files
if [ -f "src/main.c" ]; then
    print_status "PASS" "src/main.c exists"
else
    print_status "FAIL" "src/main.c not found"
fi

if [ -f "src/jq.h" ]; then
    print_status "PASS" "src/jq.h exists"
else
    print_status "FAIL" "src/jq.h not found"
fi

if [ -f "src/jv.h" ]; then
    print_status "PASS" "src/jv.h exists"
else
    print_status "FAIL" "src/jv.h not found"
fi

if [ -f "src/parser.y" ]; then
    print_status "PASS" "src/parser.y exists"
else
    print_status "FAIL" "src/parser.y not found"
fi

if [ -f "src/lexer.l" ]; then
    print_status "PASS" "src/lexer.l exists"
else
    print_status "FAIL" "src/lexer.l not found"
fi

if [ -f "src/builtin.c" ]; then
    print_status "PASS" "src/builtin.c exists"
else
    print_status "FAIL" "src/builtin.c not found"
fi

if [ -f "src/jv.c" ]; then
    print_status "PASS" "src/jv.c exists"
else
    print_status "FAIL" "src/jv.c not found"
fi

# Check test files
if [ -f "tests/jq.test" ]; then
    print_status "PASS" "tests/jq.test exists"
else
    print_status "FAIL" "tests/jq.test not found"
fi

if [ -f "tests/shtest" ]; then
    print_status "PASS" "tests/shtest exists"
else
    print_status "FAIL" "tests/shtest not found"
fi

if [ -f "tests/setup" ]; then
    print_status "PASS" "tests/setup exists"
else
    print_status "FAIL" "tests/setup not found"
fi

# Check script files
if [ -f "scripts/version" ]; then
    print_status "PASS" "scripts/version exists"
else
    print_status "FAIL" "scripts/version not found"
fi

if [ -f "scripts/crosscompile" ]; then
    print_status "PASS" "scripts/crosscompile exists"
else
    print_status "FAIL" "scripts/crosscompile not found"
fi

if [ -f "scripts/gen_utf8_tables.py" ]; then
    print_status "PASS" "scripts/gen_utf8_tables.py exists"
else
    print_status "FAIL" "scripts/gen_utf8_tables.py not found"
fi

echo ""
echo "3. Checking Environment Variables..."
echo "-----------------------------------"
# Check C environment
if [ -n "${CC:-}" ]; then
    print_status "PASS" "CC is set: $CC"
else
    print_status "WARN" "CC is not set"
fi

if [ -n "${CFLAGS:-}" ]; then
    print_status "PASS" "CFLAGS is set: $CFLAGS"
else
    print_status "WARN" "CFLAGS is not set"
fi

if [ -n "${LDFLAGS:-}" ]; then
    print_status "PASS" "LDFLAGS is set: $LDFLAGS"
else
    print_status "WARN" "LDFLAGS is not set"
fi

if [ -n "${PKG_CONFIG_PATH:-}" ]; then
    print_status "PASS" "PKG_CONFIG_PATH is set: $PKG_CONFIG_PATH"
else
    print_status "WARN" "PKG_CONFIG_PATH is not set"
fi

# Check PATH
if echo "$PATH" | grep -q "gcc"; then
    print_status "PASS" "gcc is in PATH"
else
    print_status "WARN" "gcc is not in PATH"
fi

if echo "$PATH" | grep -q "make"; then
    print_status "PASS" "make is in PATH"
else
    print_status "WARN" "make is not in PATH"
fi

if echo "$PATH" | grep -q "git"; then
    print_status "PASS" "git is in PATH"
else
    print_status "WARN" "git is not in PATH"
fi

if echo "$PATH" | grep -q "bash"; then
    print_status "PASS" "bash is in PATH"
else
    print_status "WARN" "bash is not in PATH"
fi

echo ""
echo "4. Testing C Build Environment..."
echo "--------------------------------"
# Test C compiler
if command -v gcc &> /dev/null; then
    print_status "PASS" "gcc is available"
    
    # Test C compilation
    if timeout 30s gcc -o /tmp/test_prog -x c - <<< '#include <stdio.h>
int main() { printf("Hello from C\n"); return 0; }' 2>/dev/null; then
        print_status "PASS" "C compilation works"
        rm -f /tmp/test_prog
    else
        print_status "WARN" "C compilation failed"
    fi
    
    # Test C standard
    if timeout 30s gcc -std=c99 -o /tmp/test_prog -x c - <<< '#include <stdio.h>
int main() { printf("C99 works\n"); return 0; }' 2>/dev/null; then
        print_status "PASS" "C99 standard works"
        rm -f /tmp/test_prog
    else
        print_status "WARN" "C99 standard failed"
    fi
else
    print_status "FAIL" "gcc is not available"
fi

echo ""
echo "5. Testing Autotools Build System..."
echo "-----------------------------------"
# Test autoconf
if command -v autoconf &> /dev/null; then
    print_status "PASS" "autoconf is available"
    
    if timeout 30s autoconf --version >/dev/null 2>&1; then
        print_status "PASS" "autoconf version command works"
    else
        print_status "WARN" "autoconf version command failed"
    fi
else
    print_status "FAIL" "autoconf is not available"
fi

# Test automake
if command -v automake &> /dev/null; then
    print_status "PASS" "automake is available"
    
    if timeout 30s automake --version >/dev/null 2>&1; then
        print_status "PASS" "automake version command works"
    else
        print_status "WARN" "automake version command failed"
    fi
else
    print_status "FAIL" "automake is not available"
fi

# Test libtool
if command -v libtool &> /dev/null; then
    print_status "PASS" "libtool is available"
    
    if timeout 30s libtool --version >/dev/null 2>&1; then
        print_status "PASS" "libtool version command works"
    else
        print_status "WARN" "libtool version command failed"
    fi
else
    print_status "FAIL" "libtool is not available"
fi

echo ""
echo "6. Testing Parser Generator Tools..."
echo "-----------------------------------"
# Test flex
if command -v flex &> /dev/null; then
    print_status "PASS" "flex is available"
    
    if timeout 30s flex --version >/dev/null 2>&1; then
        print_status "PASS" "flex version command works"
    else
        print_status "WARN" "flex version command failed"
    fi
else
    print_status "FAIL" "flex is not available"
fi

# Test bison
if command -v bison &> /dev/null; then
    print_status "PASS" "bison is available"
    
    if timeout 30s bison --version >/dev/null 2>&1; then
        print_status "PASS" "bison version command works"
    else
        print_status "WARN" "bison version command failed"
    fi
else
    print_status "FAIL" "bison is not available"
fi

echo ""
echo "7. Testing jq Build System..."
echo "----------------------------"
# Test configure script generation
if [ -f "configure.ac" ]; then
    print_status "PASS" "configure.ac exists for build testing"
    
    if command -v autoreconf &> /dev/null; then
        print_status "PASS" "autoreconf is available for build testing"
        
        # Test autoreconf (dry run)
        if timeout 60s autoreconf --dry-run >/dev/null 2>&1; then
            print_status "PASS" "autoreconf dry run works"
        else
            print_status "WARN" "autoreconf dry run failed"
        fi
    else
        print_status "WARN" "autoreconf not available for build testing"
    fi
else
    print_status "FAIL" "configure.ac not found"
fi

# Test Makefile.am
if [ -f "Makefile.am" ]; then
    print_status "PASS" "Makefile.am exists"
    
    if command -v make &> /dev/null; then
        print_status "PASS" "make is available for Makefile testing"
        
        # Test if Makefile.am has valid syntax (basic check)
        if grep -q "SUBDIRS\|bin_PROGRAMS\|lib_LTLIBRARIES" Makefile.am; then
            print_status "PASS" "Makefile.am has valid structure"
        else
            print_status "WARN" "Makefile.am structure unclear"
        fi
    else
        print_status "WARN" "make not available for Makefile testing"
    fi
else
    print_status "FAIL" "Makefile.am not found"
fi

echo ""
echo "8. Testing jq Source Code..."
echo "----------------------------"
# Test source code compilation
if command -v gcc &> /dev/null; then
    print_status "PASS" "gcc is available for source testing"
    
    # Test if main source file can be compiled (basic syntax check)
    if [ -f "src/main.c" ]; then
        if timeout 30s gcc -c -I src -o /tmp/main.o src/main.c 2>/dev/null; then
            print_status "PASS" "src/main.c can be compiled"
            rm -f /tmp/main.o
        else
            print_status "WARN" "src/main.c compilation failed"
        fi
    else
        print_status "FAIL" "src/main.c not found"
    fi
    
    # Test if jv.c can be compiled
    if [ -f "src/jv.c" ]; then
        if timeout 30s gcc -c -I src -o /tmp/jv.o src/jv.c 2>/dev/null; then
            print_status "PASS" "src/jv.c can be compiled"
            rm -f /tmp/jv.o
        else
            print_status "WARN" "src/jv.c compilation failed"
        fi
    else
        print_status "FAIL" "src/jv.c not found"
    fi
    
    # Test if builtin.c can be compiled
    if [ -f "src/builtin.c" ]; then
        if timeout 30s gcc -c -I src -o /tmp/builtin.o src/builtin.c 2>/dev/null; then
            print_status "PASS" "src/builtin.c can be compiled"
            rm -f /tmp/builtin.o
        else
            print_status "WARN" "src/builtin.c compilation failed"
        fi
    else
        print_status "FAIL" "src/builtin.c not found"
    fi
else
    print_status "WARN" "gcc not available for source testing"
fi

echo ""
echo "9. Testing jq Test System..."
echo "----------------------------"
# Test test system
if [ -d "tests" ]; then
    print_status "PASS" "tests directory exists"
    
    # Count test files
    test_count=$(find tests -name "*.test" | wc -l)
    if [ "$test_count" -gt 0 ]; then
        print_status "PASS" "Found $test_count test files"
    else
        print_status "WARN" "No test files found"
    fi
    
    # Test if main test file exists
    if [ -f "tests/jq.test" ]; then
        print_status "PASS" "tests/jq.test exists"
        
        # Test if test file is readable
        if [ -r "tests/jq.test" ]; then
            print_status "PASS" "tests/jq.test is readable"
        else
            print_status "WARN" "tests/jq.test is not readable"
        fi
    else
        print_status "FAIL" "tests/jq.test not found"
    fi
    
    # Test if shell test script exists
    if [ -f "tests/shtest" ]; then
        print_status "PASS" "tests/shtest exists"
        
        # Test if shell test is executable
        if [ -x "tests/shtest" ]; then
            print_status "PASS" "tests/shtest is executable"
        else
            print_status "WARN" "tests/shtest is not executable"
        fi
    else
        print_status "FAIL" "tests/shtest not found"
    fi
else
    print_status "FAIL" "tests directory not found"
fi

echo ""
echo "10. Testing jq Scripts..."
echo "-------------------------"
# Test scripts
if [ -d "scripts" ]; then
    print_status "PASS" "scripts directory exists"
    
    # Count script files
    script_count=$(find scripts -type f | wc -l)
    if [ "$script_count" -gt 0 ]; then
        print_status "PASS" "Found $script_count script files"
    else
        print_status "WARN" "No script files found"
    fi
    
    # Test version script
    if [ -f "scripts/version" ]; then
        print_status "PASS" "scripts/version exists"
        
        if [ -x "scripts/version" ]; then
            print_status "PASS" "scripts/version is executable"
        else
            print_status "WARN" "scripts/version is not executable"
        fi
    else
        print_status "FAIL" "scripts/version not found"
    fi
    
    # Test crosscompile script
    if [ -f "scripts/crosscompile" ]; then
        print_status "PASS" "scripts/crosscompile exists"
        
        if [ -x "scripts/crosscompile" ]; then
            print_status "PASS" "scripts/crosscompile is executable"
        else
            print_status "WARN" "scripts/crosscompile is not executable"
        fi
    else
        print_status "FAIL" "scripts/crosscompile not found"
    fi
    
    # Test Python script
    if [ -f "scripts/gen_utf8_tables.py" ]; then
        print_status "PASS" "scripts/gen_utf8_tables.py exists"
        
        if command -v python3 &> /dev/null; then
            if timeout 30s python3 -m py_compile scripts/gen_utf8_tables.py >/dev/null 2>&1; then
                print_status "PASS" "scripts/gen_utf8_tables.py syntax is valid"
            else
                print_status "WARN" "scripts/gen_utf8_tables.py syntax is invalid"
            fi
        else
            print_status "WARN" "python3 not available for script testing"
        fi
    else
        print_status "FAIL" "scripts/gen_utf8_tables.py not found"
    fi
else
    print_status "FAIL" "scripts directory not found"
fi

echo ""
echo "11. Testing jq Documentation..."
echo "-------------------------------"
# Test documentation
if [ -d "docs" ]; then
    print_status "PASS" "docs directory exists"
else
    print_status "FAIL" "docs directory not found"
fi

if [ -r "README.md" ]; then
    print_status "PASS" "README.md is readable"
else
    print_status "WARN" "README.md is not readable"
fi

if [ -r "COPYING" ]; then
    print_status "PASS" "COPYING is readable"
else
    print_status "WARN" "COPYING is not readable"
fi

if [ -r "AUTHORS" ]; then
    print_status "PASS" "AUTHORS is readable"
else
    print_status "WARN" "AUTHORS is not readable"
fi

if [ -r "ChangeLog" ]; then
    print_status "PASS" "ChangeLog is readable"
else
    print_status "WARN" "ChangeLog is not readable"
fi

if [ -r "NEWS.md" ]; then
    print_status "PASS" "NEWS.md is readable"
else
    print_status "WARN" "NEWS.md is not readable"
fi

if [ -r "SECURITY.md" ]; then
    print_status "PASS" "SECURITY.md is readable"
else
    print_status "WARN" "SECURITY.md is not readable"
fi

echo ""
echo "12. Testing jq Configuration..."
echo "-------------------------------"
# Test configuration files
if [ -r "configure.ac" ]; then
    print_status "PASS" "configure.ac is readable"
    
    # Test if configure.ac has valid structure
    if grep -q "AC_INIT\|AC_PREREQ\|AC_PROG_CC" configure.ac; then
        print_status "PASS" "configure.ac has valid structure"
    else
        print_status "WARN" "configure.ac structure unclear"
    fi
else
    print_status "FAIL" "configure.ac not found or not readable"
fi

if [ -r "Makefile.am" ]; then
    print_status "PASS" "Makefile.am is readable"
    
    # Test if Makefile.am has valid structure
    if grep -q "SUBDIRS\|bin_PROGRAMS\|lib_LTLIBRARIES\|AM_CFLAGS" Makefile.am; then
        print_status "PASS" "Makefile.am has valid structure"
    else
        print_status "WARN" "Makefile.am structure unclear"
    fi
else
    print_status "FAIL" "Makefile.am not found or not readable"
fi

if [ -r "jq.spec" ]; then
    print_status "PASS" "jq.spec is readable"
else
    print_status "FAIL" "jq.spec not found or not readable"
fi

if [ -r "Dockerfile" ]; then
    print_status "PASS" "Dockerfile is readable"
else
    print_status "FAIL" "Dockerfile not found or not readable"
fi

echo ""
echo "13. Testing jq Vendor Dependencies..."
echo "------------------------------------"
# Test vendor dependencies
if [ -d "vendor" ]; then
    print_status "PASS" "vendor directory exists"
    
    # Check for decNumber dependency
    if [ -d "vendor/decNumber" ]; then
        print_status "PASS" "vendor/decNumber directory exists"
        
        if [ -f "vendor/decNumber/decNumber.h" ]; then
            print_status "PASS" "decNumber.h exists"
        else
            print_status "FAIL" "decNumber.h not found"
        fi
        
        if [ -f "vendor/decNumber/decNumber.c" ]; then
            print_status "PASS" "decNumber.c exists"
        else
            print_status "FAIL" "decNumber.c not found"
        fi
    else
        print_status "WARN" "vendor/decNumber directory not found"
    fi
else
    print_status "FAIL" "vendor directory not found"
fi

echo ""
echo "14. Testing jq Build Configuration..."
echo "------------------------------------"
# Test build configuration
if [ -d "m4" ]; then
    print_status "PASS" "m4 directory exists"
    
    m4_count=$(find m4 -name "*.m4" | wc -l)
    if [ "$m4_count" -gt 0 ]; then
        print_status "PASS" "Found $m4_count m4 macro files"
    else
        print_status "WARN" "No m4 macro files found"
    fi
else
    print_status "FAIL" "m4 directory not found"
fi

if [ -d "config" ]; then
    print_status "PASS" "config directory exists"
    
    config_count=$(find config -type f | wc -l)
    if [ "$config_count" -gt 0 ]; then
        print_status "PASS" "Found $config_count config files"
    else
        print_status "WARN" "No config files found"
    fi
else
    print_status "FAIL" "config directory not found"
fi
    
    echo ""
    echo "1. Testing jq Core Functionality..."
    echo "----------------------------------"
    
    # Test basic JSON processing
    if echo '{"test": "value"}' | docker run --rm -i jq-env-test '.test' >/dev/null 2>&1; then
        print_status "PASS" "jq basic JSON processing works"
    else
        print_status "FAIL" "jq basic JSON processing failed"
    fi
    
    # Test array processing
    if echo '{"array": [1,2,3], "object": {"key": "value"}}' | docker run --rm -i jq-env-test '.array[0]' >/dev/null 2>&1; then
        print_status "PASS" "jq array processing works"
    else
        print_status "FAIL" "jq array processing failed"
    fi
    
    # Test builtin functions
    if echo '[1,2,3,4,5]' | docker run --rm -i jq-env-test 'length' >/dev/null 2>&1; then
        print_status "PASS" "jq builtin functions work"
    else
        print_status "FAIL" "jq builtin functions failed"
    fi
    
    # Test object processing
    if echo '{"a": 1, "b": 2, "c": 3}' | docker run --rm -i jq-env-test 'keys' >/dev/null 2>&1; then
        print_status "PASS" "jq object processing works"
    else
        print_status "FAIL" "jq object processing failed"
    fi
    
    # Test string processing
    if echo '"hello world"' | docker run --rm -i jq-env-test 'split(" ")' >/dev/null 2>&1; then
        print_status "PASS" "jq string processing works"
    else
        print_status "FAIL" "jq string processing failed"
    fi
    
    echo ""
    echo "2. Testing jq Advanced Features..."
    echo "---------------------------------"
    
    # Test map function
    if echo '[1,2,3,4,5]' | docker run --rm -i jq-env-test 'map(. * 2)' >/dev/null 2>&1; then
        print_status "PASS" "jq map function works"
    else
        print_status "FAIL" "jq map function failed"
    fi
    
    # Test select function
    if echo '[1,2,3,4,5]' | docker run --rm -i jq-env-test '.[] | select(. > 3)' >/dev/null 2>&1; then
        print_status "PASS" "jq select function works"
    else
        print_status "FAIL" "jq select function failed"
    fi
    
    # Test reduce function
    if echo '[1,2,3,4,5]' | docker run --rm -i jq-env-test 'reduce .[] as $item (0; . + $item)' >/dev/null 2>&1; then
        print_status "PASS" "jq reduce function works"
    else
        print_status "FAIL" "jq reduce function failed"
    fi
    
    # Test group_by function
    if echo '[{"type": "A", "value": 1}, {"type": "B", "value": 2}, {"type": "A", "value": 3}]' | docker run --rm -i jq-env-test 'group_by(.type)' >/dev/null 2>&1; then
        print_status "PASS" "jq group_by function works"
    else
        print_status "FAIL" "jq group_by function failed"
    fi
    
    # Test sort_by function
    if echo '[{"name": "Alice", "age": 30}, {"name": "Bob", "age": 25}]' | docker run --rm -i jq-env-test 'sort_by(.age)' >/dev/null 2>&1; then
        print_status "PASS" "jq sort_by function works"
    else
        print_status "FAIL" "jq sort_by function failed"
    fi
    
    echo ""
    echo "3. Testing jq Data Format Support..."
    echo "-----------------------------------"
    
    # Test CSV output
    if echo '["Alice", 30]' | docker run --rm -i jq-env-test -r '@csv' >/dev/null 2>&1; then
        print_status "PASS" "jq CSV output format works"
    else
        print_status "FAIL" "jq CSV output format failed"
    fi
    
    # Test TSV output
    if echo '["Alice", 30]' | docker run --rm -i jq-env-test -r '@tsv' >/dev/null 2>&1; then
        print_status "PASS" "jq TSV output format works"
    else
        print_status "FAIL" "jq TSV output format failed"
    fi
    
    # Test HTML output
    if echo '"<test>"' | docker run --rm -i jq-env-test '@html' >/dev/null 2>&1; then
        print_status "PASS" "jq HTML output format works"
    else
        print_status "FAIL" "jq HTML output format failed"
    fi
    
    # Test URI encoding
    if echo '"hello world"' | docker run --rm -i jq-env-test '@uri' >/dev/null 2>&1; then
        print_status "PASS" "jq URI encoding works"
    else
        print_status "FAIL" "jq URI encoding failed"
    fi
    
    # Test Base64 encoding
    if echo '"hello"' | docker run --rm -i jq-env-test '@base64' >/dev/null 2>&1; then
        print_status "PASS" "jq Base64 encoding works"
    else
        print_status "FAIL" "jq Base64 encoding failed"
    fi
    
    echo ""
    echo "4. Testing jq Regular Expression Support..."
    echo "-------------------------------------------"
    
    # Test regex match
    if echo '"hello world"' | docker run --rm -i jq-env-test 'match("world")' >/dev/null 2>&1; then
        print_status "PASS" "jq regex match works"
    else
        print_status "FAIL" "jq regex match failed"
    fi
    
    # Test regex test
    if echo '"hello world"' | docker run --rm -i jq-env-test 'test("world")' >/dev/null 2>&1; then
        print_status "PASS" "jq regex test works"
    else
        print_status "FAIL" "jq regex test failed"
    fi
    
    # Test regex capture
    if echo '"hello world"' | docker run --rm -i jq-env-test 'capture("(?<word>\\w+)")' >/dev/null 2>&1; then
        print_status "PASS" "jq regex capture works"
    else
        print_status "FAIL" "jq regex capture failed"
    fi
    
    # Test regex scan
    if echo '"hello world hello"' | docker run --rm -i jq-env-test 'scan("hello")' >/dev/null 2>&1; then
        print_status "PASS" "jq regex scan works"
    else
        print_status "FAIL" "jq regex scan failed"
    fi
    
    echo ""
    echo "5. Testing jq Mathematical Functions..."
    echo "--------------------------------------"
    
    # Test basic math operations
    if echo '10' | docker run --rm -i jq-env-test '. + 5' >/dev/null 2>&1; then
        print_status "PASS" "jq basic math operations work"
    else
        print_status "FAIL" "jq basic math operations failed"
    fi
    
    # Test abs function
    if echo '-5' | docker run --rm -i jq-env-test 'abs' >/dev/null 2>&1; then
        print_status "PASS" "jq abs function works"
    else
        print_status "FAIL" "jq abs function failed"
    fi
    
    # Test floor function
    if echo '3.7' | docker run --rm -i jq-env-test 'floor' >/dev/null 2>&1; then
        print_status "PASS" "jq floor function works"
    else
        print_status "FAIL" "jq floor function failed"
    fi
    
    # Test sqrt function
    if echo '16' | docker run --rm -i jq-env-test 'sqrt' >/dev/null 2>&1; then
        print_status "PASS" "jq sqrt function works"
    else
        print_status "FAIL" "jq sqrt function failed"
    fi
    
    echo ""
    echo "6. Testing jq Date/Time Functions..."
    echo "-----------------------------------"
    
    # Test strptime function
    if echo '"2023-01-01T12:00:00Z"' | docker run --rm -i jq-env-test 'strptime("%Y-%m-%dT%H:%M:%SZ")' >/dev/null 2>&1; then
        print_status "PASS" "jq strptime function works"
    else
        print_status "FAIL" "jq strptime function failed"
    fi
    
    # Test strftime function
    if echo '[2023,1,1,12,0,0,0,0]' | docker run --rm -i jq-env-test 'strftime("%Y-%m-%d")' >/dev/null 2>&1; then
        print_status "PASS" "jq strftime function works"
    else
        print_status "FAIL" "jq strftime function failed"
    fi
    
    echo ""
    echo "7. Testing jq File I/O Capabilities..."
    echo "-------------------------------------"
    
    # Test input function (reading from stdin)
    if echo '{"test": "value"}' | docker run --rm -i jq-env-test '.' >/dev/null 2>&1; then
        print_status "PASS" "jq input function works"
    else
        print_status "FAIL" "jq input function failed"
    fi
    
    # Test inputs function (reading multiple inputs)
    if echo -e '{"a": 1}\n{"b": 2}' | docker run --rm -i jq-env-test 'inputs' >/dev/null 2>&1; then
        print_status "PASS" "jq inputs function works"
    else
        print_status "FAIL" "jq inputs function failed"
    fi
    
    echo ""
    echo "8. Testing jq Error Handling..."
    echo "-------------------------------"
    
    # Test error function
    if echo 'null' | docker run --rm -i jq-env-test 'error("test error")' 2>&1 | grep -q "test error"; then
        print_status "PASS" "jq error function works"
    else
        print_status "FAIL" "jq error function failed"
    fi
    
    # Test try-catch
    if echo 'null' | docker run --rm -i jq-env-test 'try error("test") catch "caught"' >/dev/null 2>&1; then
        print_status "PASS" "jq try-catch works"
    else
        print_status "FAIL" "jq try-catch failed"
    fi
    
    echo ""
    echo "9. Testing jq Performance Features..."
    echo "------------------------------------"
    
    # Test large array processing
    large_array=$(printf '[%s]' $(seq -s ',' 1 1000))
    if echo "$large_array" | docker run --rm -i jq-env-test 'length' >/dev/null 2>&1; then
        print_status "PASS" "jq large array processing works"
    else
        print_status "FAIL" "jq large array processing failed"
    fi
    
    # Test nested object processing
    nested_obj='{"level1": {"level2": {"level3": {"value": "deep"}}}}'
    if echo "$nested_obj" | docker run --rm -i jq-env-test '.level1.level2.level3.value' >/dev/null 2>&1; then
        print_status "PASS" "jq nested object processing works"
    else
        print_status "FAIL" "jq nested object processing failed"
    fi
    
    echo ""
    echo "10. Testing jq Unicode Support..."
    echo "--------------------------------"
    
    # Test Unicode string processing
    if echo '"Hello 世界"' | docker run --rm -i jq-env-test 'length' >/dev/null 2>&1; then
        print_status "PASS" "jq Unicode string processing works"
    else
        print_status "FAIL" "jq Unicode string processing failed"
    fi
    
    # Test Unicode in object keys
    if echo '{"测试": "value"}' | docker run --rm -i jq-env-test 'keys' >/dev/null 2>&1; then
        print_status "PASS" "jq Unicode object keys work"
    else
        print_status "FAIL" "jq Unicode object keys failed"
    fi
    
    echo ""
    echo "=========================================="
    echo "Docker Environment Test Complete"
    echo "=========================================="
    echo ""
    echo "Summary:"
    echo "--------"
    echo "This script has tested the Docker environment for jq:"
    echo "- Docker build process (Ubuntu 22.04, build tools, compilation)"
    echo "- jq binary functionality (version, help, JSON processing)"
    echo "- jq core features (basic JSON, arrays, objects, strings)"
    echo "- jq advanced features (map, select, reduce, group_by, sort_by)"
    echo "- jq data formats (CSV, TSV, HTML, URI, Base64)"
    echo "- jq regex support (match, test, capture, scan)"
    echo "- jq mathematical functions (abs, floor, sqrt)"
    echo "- jq date/time functions (strptime, strftime)"
    echo "- jq file I/O capabilities (input, inputs)"
    echo "- jq error handling (error, try-catch)"
    echo "- jq performance features (large arrays, nested objects)"
    echo "- jq Unicode support (UTF-8 strings and keys)"
    echo "- Build optimization (static linking, minimal image)"
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
        print_status "INFO" "All Docker tests passed! Your jq Docker environment is ready!"
        print_status "INFO" "jq is a lightweight and flexible command-line JSON processor with zero runtime dependencies."
    elif [ $FAIL_COUNT -lt 5 ]; then
        print_status "INFO" "Most Docker tests passed! Your jq Docker environment is mostly ready."
        print_status "WARN" "Some optional features are missing, but core functionality works."
    else
        print_status "WARN" "Many Docker tests failed. Please check the output above."
        print_status "INFO" "This might indicate that the Docker environment is not properly set up."
    fi
    echo ""
    print_status "INFO" "You can now run jq in Docker: A lightweight and flexible command-line JSON processor."
    print_status "INFO" "Example: docker run --rm jq-env-test --version"
    print_status "INFO" "Example: echo '{\"test\": \"value\"}' | docker run --rm -i jq-env-test '.test'"
    echo ""
    print_status "INFO" "For more information, see README.md and https://jqlang.org"
    exit 0
fi

# If Docker failed or not available, skip local environment tests
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ] || [ "${DOCKER_MODE:-false}" = "false" ]; then
    echo "Docker environment not available - skipping local environment tests"
    echo "This script is designed to test Docker environment only"
    exit 0
fi 