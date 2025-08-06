#!/bin/bash

# ELECT Environment Benchmark Test Script
# This script tests the environment setup for ELECT distributed KV store

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
    cat > "$json_file" << EOF
{
    "PASS": $PASS_COUNT,
    "FAIL": $FAIL_COUNT,
    "WARN": $WARN_COUNT
}
EOF
    echo -e "${BLUE}[INFO]${NC} Results written to $json_file"
}

# Check if envgym.dockerfile exists
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
    # Kill any background processes
    jobs -p | xargs -r kill
    # Remove temporary files
    rm -f docker_build.log
    # Stop and remove Docker container if running
    docker stop elect-env-test 2>/dev/null || true
    docker rm elect-env-test 2>/dev/null || true
    exit 0
}

# Set up signal handlers
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the ELECT project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t elect-env-test .; then
        echo -e "${RED}[CRITICAL ERROR]${NC} Docker build failed"
        echo -e "${RED}[RESULT]${NC} Benchmark score: 0 (Docker build failed)"
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Run this script inside Docker container
    echo "Running environment test in Docker container..."
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/ELECT" elect-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "ELECT Environment Benchmark Test"
echo "=========================================="
echo ""

echo "1. Checking System Dependencies..."
echo "--------------------------------"
# Check Java
if command -v java &> /dev/null; then
    java_version=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    print_status "PASS" "Java is available: $java_version"
    
    # Check Java version (should be 11)
    java_major=$(echo $java_version | cut -d'.' -f1)
    if [ "$java_major" = "1" ]; then
        java_major=$(echo $java_version | cut -d'.' -f2)
    fi
    if [ -n "$java_major" ] && [ "$java_major" -eq 11 ]; then
        print_status "PASS" "Java version is 11"
    else
        print_status "WARN" "Java version is not 11 (found: $java_major)"
    fi
else
    print_status "FAIL" "Java is not available"
fi

# Check Ant
if command -v ant &> /dev/null; then
    ant_version=$(ant -version 2>&1 | head -n 1)
    print_status "PASS" "Apache Ant is available: $ant_version"
else
    print_status "FAIL" "Apache Ant is not available"
fi

# Check Maven
if command -v mvn &> /dev/null; then
    mvn_version=$(mvn -version 2>&1 | head -n 1)
    print_status "PASS" "Maven is available: $mvn_version"
else
    print_status "FAIL" "Maven is not available"
fi

# Check Clang
if command -v clang &> /dev/null; then
    clang_version=$(clang --version 2>&1 | head -n 1)
    print_status "PASS" "Clang is available: $clang_version"
else
    print_status "FAIL" "Clang is not available"
fi

# Check LLVM
if command -v llvm-config &> /dev/null; then
    llvm_version=$(llvm-config --version 2>&1)
    print_status "PASS" "LLVM is available: $llvm_version"
else
    print_status "FAIL" "LLVM is not available"
fi

# Check Python 3
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>&1)
    print_status "PASS" "Python 3 is available: $python_version"
else
    print_status "FAIL" "Python 3 is not available"
fi

# Check pip
if command -v pip3 &> /dev/null; then
    pip_version=$(pip3 --version 2>&1)
    print_status "PASS" "pip3 is available: $pip_version"
else
    print_status "WARN" "pip3 is not available"
fi

# Check bc
if command -v bc &> /dev/null; then
    print_status "PASS" "bc calculator is available"
else
    print_status "FAIL" "bc calculator is not available"
fi

# Check make
if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "Make is available: $make_version"
else
    print_status "FAIL" "Make is not available"
fi

# Check git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1)
    print_status "PASS" "Git is available: $git_version"
else
    print_status "FAIL" "Git is not available"
fi

# Check curl
if command -v curl &> /dev/null; then
    print_status "PASS" "curl is available"
else
    print_status "FAIL" "curl is not available"
fi

# Check libisal-dev (Intel ISA-L library)
if pkg-config --exists libisal 2>/dev/null; then
    print_status "PASS" "Intel ISA-L library is available"
else
    print_status "FAIL" "Intel ISA-L library is not available"
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

if [ -d "src/elect" ]; then
    print_status "PASS" "src/elect directory exists"
else
    print_status "FAIL" "src/elect directory not found"
fi

if [ -d "src/coldTier" ]; then
    print_status "PASS" "src/coldTier directory exists"
else
    print_status "FAIL" "src/coldTier directory not found"
fi

if [ -d "scripts" ]; then
    print_status "PASS" "scripts directory exists"
else
    print_status "FAIL" "scripts directory not found"
fi

# Check key files
if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
fi

if [ -f "AE_INSTRUCTION.md" ]; then
    print_status "PASS" "AE_INSTRUCTION.md exists"
else
    print_status "FAIL" "AE_INSTRUCTION.md not found"
fi

if [ -f "src/elect/build.xml" ]; then
    print_status "PASS" "build.xml exists"
else
    print_status "FAIL" "build.xml not found"
fi

if [ -f "src/coldTier/Makefile" ]; then
    print_status "PASS" "coldTier Makefile exists"
else
    print_status "FAIL" "coldTier Makefile not found"
fi

if [ -f "scripts/settings.sh" ]; then
    print_status "PASS" "settings.sh exists"
else
    print_status "FAIL" "settings.sh not found"
fi

if [ -d "scripts/ycsb" ]; then
    print_status "PASS" "YCSB directory exists"
else
    print_status "FAIL" "YCSB directory not found"
fi

if [ -f "scripts/ycsb/pom.xml" ]; then
    print_status "PASS" "YCSB pom.xml exists"
else
    print_status "FAIL" "YCSB pom.xml not found"
fi

echo ""
echo "3. Checking Environment Variables..."
echo "-----------------------------------"
# Check Java environment
if [ -n "${JAVA_HOME:-}" ]; then
    print_status "PASS" "JAVA_HOME is set: $JAVA_HOME"
else
    print_status "WARN" "JAVA_HOME is not set"
fi

# Check PATH
if echo "$PATH" | grep -q "java"; then
    print_status "PASS" "Java is in PATH"
else
    print_status "WARN" "Java is not in PATH"
fi

echo ""
echo "4. Testing Java Compilation..."
echo "-----------------------------"
# Test Java compilation
if command -v javac &> /dev/null; then
    print_status "PASS" "javac is available"
    
    # Test simple Java compilation
    echo 'public class Test { public static void main(String[] args) { System.out.println("Hello"); } }' > Test.java
    if javac Test.java 2>/dev/null; then
        print_status "PASS" "Java compilation works"
        rm -f Test.java Test.class
    else
        print_status "WARN" "Java compilation failed"
        rm -f Test.java
    fi
else
    print_status "FAIL" "javac is not available"
fi

echo ""
echo "5. Testing Ant Build System..."
echo "-----------------------------"
# Test Ant
if command -v ant &> /dev/null && [ -f "src/elect/build.xml" ]; then
    print_status "PASS" "Ant and build.xml are available"
    
    # Test ant help
    if timeout 30s ant -help >/dev/null 2>&1; then
        print_status "PASS" "Ant help command works"
    else
        print_status "WARN" "Ant help command failed"
    fi
    
    # Test ant targets
    if timeout 30s ant -projecthelp >/dev/null 2>&1; then
        print_status "PASS" "Ant project help works"
    else
        print_status "WARN" "Ant project help failed"
    fi
else
    print_status "WARN" "Ant or build.xml not available"
fi

echo ""
echo "6. Testing Maven Build System..."
echo "--------------------------------"
# Test Maven
if command -v mvn &> /dev/null && [ -f "scripts/ycsb/pom.xml" ]; then
    print_status "PASS" "Maven and pom.xml are available"
    
    # Test mvn help
    if timeout 30s mvn -help >/dev/null 2>&1; then
        print_status "PASS" "Maven help command works"
    else
        print_status "WARN" "Maven help command failed"
    fi
    
    # Test mvn validate
    if timeout 60s mvn -f scripts/ycsb/pom.xml validate >/dev/null 2>&1; then
        print_status "PASS" "Maven validate works"
    else
        print_status "WARN" "Maven validate failed"
    fi
else
    print_status "WARN" "Maven or pom.xml not available"
fi

echo ""
echo "7. Testing C/C++ Compilation..."
echo "-------------------------------"
# Test C/C++ compilation
if command -v gcc &> /dev/null; then
    print_status "PASS" "gcc is available"
    
    # Test simple C compilation
    echo '#include <stdio.h>
int main() { printf("Hello\n"); return 0; }' > test.c
    if gcc -o test test.c 2>/dev/null; then
        print_status "PASS" "C compilation works"
        rm -f test.c test
    else
        print_status "WARN" "C compilation failed"
        rm -f test.c
    fi
else
    print_status "FAIL" "gcc is not available"
fi

if command -v clang &> /dev/null; then
    print_status "PASS" "clang is available"
    
    # Test simple C compilation with clang
    echo '#include <stdio.h>
int main() { printf("Hello\n"); return 0; }' > test_clang.c
    if clang -o test_clang test_clang.c 2>/dev/null; then
        print_status "PASS" "Clang compilation works"
        rm -f test_clang.c test_clang
    else
        print_status "WARN" "Clang compilation failed"
        rm -f test_clang.c
    fi
else
    print_status "FAIL" "clang is not available"
fi

echo ""
echo "8. Testing Python Environment..."
echo "-------------------------------"
# Test Python
if command -v python3 &> /dev/null; then
    print_status "PASS" "python3 is available"
    
    # Test Python execution
    if python3 -c "print('Hello from Python')" >/dev/null 2>&1; then
        print_status "PASS" "Python execution works"
    else
        print_status "WARN" "Python execution failed"
    fi
    
    # Test pip
    if command -v pip3 &> /dev/null; then
        print_status "PASS" "pip3 is available"
        
        # Test pip list
        if timeout 30s pip3 list >/dev/null 2>&1; then
            print_status "PASS" "pip3 list works"
        else
            print_status "WARN" "pip3 list failed"
        fi
    else
        print_status "WARN" "pip3 is not available"
    fi
else
    print_status "FAIL" "python3 is not available"
fi

echo ""
echo "9. Testing Make Build System..."
echo "-------------------------------"
# Test Make
if command -v make &> /dev/null && [ -f "src/coldTier/Makefile" ]; then
    print_status "PASS" "Make and Makefile are available"
    
    # Test make help or default target
    if timeout 30s make -f src/coldTier/Makefile >/dev/null 2>&1; then
        print_status "PASS" "Make works with coldTier Makefile"
    else
        print_status "WARN" "Make failed with coldTier Makefile"
    fi
else
    print_status "WARN" "Make or Makefile not available"
fi

echo ""
echo "10. Testing Intel ISA-L Library..."
echo "----------------------------------"
# Test Intel ISA-L library
if pkg-config --exists libisal 2>/dev/null; then
    print_status "PASS" "Intel ISA-L library is available"
    
    # Test compilation with ISA-L
    echo '#include <isa-l.h>
int main() { return 0; }' > test_isal.c
    if gcc -o test_isal test_isal.c $(pkg-config --cflags --libs libisal) 2>/dev/null; then
        print_status "PASS" "ISA-L library compilation works"
        rm -f test_isal.c test_isal
    else
        print_status "WARN" "ISA-L library compilation failed"
        rm -f test_isal.c
    fi
else
    print_status "FAIL" "Intel ISA-L library is not available"
fi

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (Java 11, Ant, Maven, Clang, LLVM, Python 3, bc, make, git, curl)"
echo "- Intel ISA-L library for erasure coding"
echo "- Project structure (src/elect, src/coldTier, scripts, build.xml, Makefile, pom.xml)"
echo "- Environment variables (JAVA_HOME, PATH)"
echo "- Java compilation (javac)"
echo "- Build systems (Ant, Maven, Make)"
echo "- C/C++ compilation (gcc, clang)"
echo "- Python environment (python3, pip3)"
echo "- Dockerfile structure (if Docker build failed)"
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
    print_status "INFO" "All tests passed! Your ELECT environment is ready!"
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your ELECT environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi

print_status "INFO" "You can now build and test ELECT distributed KV store."
print_status "INFO" "Example: cd src/elect && ant -Duse.jdk11=true"

echo ""
print_status "INFO" "For more information, see README.md and AE_INSTRUCTION.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/ELECT elect-env-test /bin/bash" 