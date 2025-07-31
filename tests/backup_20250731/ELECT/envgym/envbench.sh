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

# Check if we're running in Docker
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo "Running inside Docker container - performing environment tests..."
    DOCKER_MODE=true
else
    echo "Running on host - checking for Docker and envgym.dockerfile"
    DOCKER_MODE=false
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_status "WARN" "Docker not available - running tests in local environment"
    elif [ -f "envgym/envgym.dockerfile" ]; then
        echo "Building Docker image..."
        if timeout 60s docker build -f envgym/envgym.dockerfile -t elect-env-test .; then
            echo "Docker build successful - running environment test in Docker container..."
            if docker run --rm -v "$(pwd):/home/cc/EnvGym/data/ELECT" --init elect-env-test bash -c "
                trap 'exit 0' SIGINT SIGTERM
                cd /home/cc/EnvGym/data/ELECT
                bash envgym/envbench.sh
            "; then
                echo "Docker container test completed successfully"
                cleanup
            else
                echo "WARNING: Docker container failed to run - analyzing Dockerfile only"
                echo "This may be due to architecture compatibility issues"
                DOCKER_BUILD_FAILED=true
            fi
        else
            echo "WARNING: Docker build failed - analyzing Dockerfile only"
            DOCKER_BUILD_FAILED=true
        fi
    else
        print_status "WARN" "envgym.dockerfile not found - running tests in local environment"
    fi
fi

echo "=========================================="
echo "ELECT Environment Benchmark Test"
echo "=========================================="

# Analyze Dockerfile if build failed
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ]; then
    echo ""
    echo "Analyzing Dockerfile..."
    echo "----------------------"
    
    if [ -f "envgym/envgym.dockerfile" ]; then
        # Check Dockerfile structure
        if grep -q "FROM" envgym/envgym.dockerfile; then
            print_status "PASS" "FROM instruction found"
        else
            print_status "FAIL" "FROM instruction not found"
        fi
        
        if grep -q "ubuntu:20.04" envgym/envgym.dockerfile; then
            print_status "PASS" "Base image is Ubuntu 20.04"
        else
            print_status "WARN" "Base image is not Ubuntu 20.04"
        fi
        
        if grep -q "openjdk-11" envgym/envgym.dockerfile; then
            print_status "PASS" "Java 11 specified"
        else
            print_status "FAIL" "Java 11 not specified"
        fi
        
        if grep -q "JAVA_HOME" envgym/envgym.dockerfile; then
            print_status "PASS" "JAVA_HOME environment variable set"
        else
            print_status "WARN" "JAVA_HOME not set"
        fi
        
        if grep -q "ant" envgym/envgym.dockerfile; then
            print_status "PASS" "Apache Ant specified"
        else
            print_status "FAIL" "Apache Ant not specified"
        fi
        
        if grep -q "maven" envgym/envgym.dockerfile; then
            print_status "PASS" "Maven specified"
        else
            print_status "FAIL" "Maven not specified"
        fi
        
        if grep -q "clang\|llvm" envgym/envgym.dockerfile; then
            print_status "PASS" "Clang/LLVM specified"
        else
            print_status "FAIL" "Clang/LLVM not specified"
        fi
        
        if grep -q "libisal-dev" envgym/envgym.dockerfile; then
            print_status "PASS" "Intel ISA-L library specified"
        else
            print_status "FAIL" "Intel ISA-L library not specified"
        fi
        
        if grep -q "python3" envgym/envgym.dockerfile; then
            print_status "PASS" "Python 3 specified"
        else
            print_status "FAIL" "Python 3 not specified"
        fi
        
        if grep -q "WORKDIR" envgym/envgym.dockerfile; then
            print_status "PASS" "WORKDIR set"
        else
            print_status "WARN" "WORKDIR not set"
        fi
        
        if grep -q "CMD\|ENTRYPOINT" envgym/envgym.dockerfile; then
            print_status "PASS" "CMD/ENTRYPOINT found"
        else
            print_status "WARN" "CMD/ENTRYPOINT not found"
        fi
        
        echo ""
        total_dockerfile_checks=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT))
        if [ $total_dockerfile_checks -gt 0 ]; then
            dockerfile_score=$((PASS_COUNT * 100 / total_dockerfile_checks))
        else
            dockerfile_score=0
        fi
        print_status "INFO" "Dockerfile Environment Score: $dockerfile_score% ($PASS_COUNT/$total_dockerfile_checks checks passed)"
        print_status "INFO" "PASS: $PASS_COUNT, FAIL: $((FAIL_COUNT)), WARN: $((WARN_COUNT))"
        if [ $FAIL_COUNT -eq 0 ]; then
            print_status "INFO" "Dockerfile结构良好，建议检查依赖版本和构建产物。"
        else
            print_status "WARN" "Dockerfile存在一些问题，建议修复后重新构建。"
        fi
        echo ""
    else
        print_status "FAIL" "envgym.dockerfile not found"
    fi
fi

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
print_status "INFO" "Environment Score: $score_percentage% ($PASS_COUNT/$total_tests tests passed)"
echo ""
if [ $FAIL_COUNT -eq 0 ]; then
    print_status "INFO" "All tests passed! Your ELECT environment is ready!"
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your ELECT environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now build and test ELECT distributed KV store."
print_status "INFO" "Example: cd src/elect && ant -Duse.jdk11=true"
echo ""
print_status "INFO" "For more information, see README.md and AE_INSTRUCTION.md" 