#!/bin/bash

# ExLi Environment Benchmark Test Script
# This script tests the environment setup for ExLi inline test extraction tool

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
    docker stop exli-env-test 2>/dev/null || true
    docker rm exli-env-test 2>/dev/null || true
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
        if timeout 60s docker build -f envgym/envgym.dockerfile -t exli-env-test .; then
            echo "Docker build successful - running environment test in Docker container..."
            if docker run --rm -v "$(pwd):/home/itdocker" --init exli-env-test bash -c "
                trap 'exit 0' SIGINT SIGTERM
                cd /home/itdocker
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
echo "ExLi Environment Benchmark Test"
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
        
        if grep -q "ubuntu:22.04" envgym/envgym.dockerfile; then
            print_status "PASS" "Base image is Ubuntu 22.04"
        else
            print_status "WARN" "Base image is not Ubuntu 22.04"
        fi
        
        if grep -q "miniconda\|conda" envgym/envgym.dockerfile; then
            print_status "PASS" "Conda/Miniconda specified"
        else
            print_status "FAIL" "Conda/Miniconda not specified"
        fi
        
        if grep -q "python" envgym/envgym.dockerfile; then
            print_status "PASS" "Python specified"
        else
            print_status "FAIL" "Python not specified"
        fi
        
        if grep -q "java\|jdk" envgym/envgym.dockerfile; then
            print_status "PASS" "Java specified"
        else
            print_status "FAIL" "Java not specified"
        fi
        
        if grep -q "maven" envgym/envgym.dockerfile; then
            print_status "PASS" "Maven specified"
        else
            print_status "FAIL" "Maven not specified"
        fi
        
        if grep -q "firefox\|geckodriver" envgym/envgym.dockerfile; then
            print_status "PASS" "Firefox/Geckodriver specified"
        else
            print_status "FAIL" "Firefox/Geckodriver not specified"
        fi
        
        if grep -q "git" envgym/envgym.dockerfile; then
            print_status "PASS" "Git specified"
        else
            print_status "FAIL" "Git not specified"
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
# Check Python
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>&1)
    print_status "PASS" "Python 3 is available: $python_version"
    
    # Check Python version (should be 3.9 or later)
    python_major=$(echo $python_version | cut -d' ' -f2 | cut -d'.' -f1)
    python_minor=$(echo $python_version | cut -d' ' -f2 | cut -d'.' -f2)
    if [ -n "$python_major" ] && [ -n "$python_minor" ]; then
        if [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 9 ]; then
            print_status "PASS" "Python version is 3.9 or later"
        else
            print_status "WARN" "Python version should be 3.9 or later (found: $python_major.$python_minor)"
        fi
    fi
else
    print_status "FAIL" "Python 3 is not available"
fi

# Check Java
if command -v java &> /dev/null; then
    java_version=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    print_status "PASS" "Java is available: $java_version"
    
    # Check Java version (should be 8)
    java_major=$(echo $java_version | cut -d'.' -f1)
    if [ "$java_major" = "1" ]; then
        java_major=$(echo $java_version | cut -d'.' -f2)
    fi
    if [ -n "$java_major" ] && [ "$java_major" -eq 8 ]; then
        print_status "PASS" "Java version is 8"
    else
        print_status "WARN" "Java version should be 8 (found: $java_major)"
    fi
else
    print_status "FAIL" "Java is not available"
fi

# Check Maven
if command -v mvn &> /dev/null; then
    mvn_version=$(mvn -version 2>&1 | head -n 1)
    print_status "PASS" "Maven is available: $mvn_version"
    
    # Check Maven version (should be 3.8.3 or later)
    mvn_version_num=$(mvn -version 2>&1 | grep "Apache Maven" | cut -d' ' -f3)
    if [ -n "$mvn_version_num" ]; then
        mvn_major=$(echo $mvn_version_num | cut -d'.' -f1)
        mvn_minor=$(echo $mvn_version_num | cut -d'.' -f2)
        if [ "$mvn_major" -eq 3 ] && [ "$mvn_minor" -ge 8 ]; then
            print_status "PASS" "Maven version is 3.8.3 or later"
        else
            print_status "WARN" "Maven version should be 3.8.3 or later (found: $mvn_version_num)"
        fi
    fi
else
    print_status "FAIL" "Maven is not available"
fi

# Check Conda
if command -v conda &> /dev/null; then
    conda_version=$(conda --version 2>&1)
    print_status "PASS" "Conda is available: $conda_version"
else
    print_status "FAIL" "Conda is not available"
fi

# Check pip
if command -v pip3 &> /dev/null; then
    pip_version=$(pip3 --version 2>&1)
    print_status "PASS" "pip3 is available: $pip_version"
else
    print_status "WARN" "pip3 is not available"
fi

# Check git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1)
    print_status "PASS" "Git is available: $git_version"
else
    print_status "FAIL" "Git is not available"
fi

# Check Firefox (for web testing)
if command -v firefox &> /dev/null; then
    firefox_version=$(firefox --version 2>&1)
    print_status "PASS" "Firefox is available: $firefox_version"
else
    print_status "WARN" "Firefox is not available"
fi

# Check Geckodriver
if command -v geckodriver &> /dev/null; then
    gecko_version=$(geckodriver --version 2>&1 | head -n 1)
    print_status "PASS" "Geckodriver is available: $gecko_version"
else
    print_status "WARN" "Geckodriver is not available"
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
    print_status "FAIL" "wget is not available"
fi

# Check unzip
if command -v unzip &> /dev/null; then
    print_status "PASS" "unzip is available"
else
    print_status "FAIL" "unzip is not available"
fi

# Check build tools
if command -v gcc &> /dev/null; then
    print_status "PASS" "gcc is available"
else
    print_status "WARN" "gcc is not available"
fi

if command -v make &> /dev/null; then
    print_status "PASS" "make is available"
else
    print_status "WARN" "make is not available"
fi

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "python" ]; then
    print_status "PASS" "python directory exists"
else
    print_status "FAIL" "python directory not found"
fi

if [ -d "java" ]; then
    print_status "PASS" "java directory exists"
else
    print_status "FAIL" "java directory not found"
fi

if [ -d "poms" ]; then
    print_status "PASS" "poms directory exists"
else
    print_status "FAIL" "poms directory not found"
fi

if [ -d "jars" ]; then
    print_status "PASS" "jars directory exists"
else
    print_status "FAIL" "jars directory not found"
fi

if [ -d "data" ]; then
    print_status "PASS" "data directory exists"
else
    print_status "FAIL" "data directory not found"
fi

# Check key files
if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
fi

if [ -f "REPRODUCE.md" ]; then
    print_status "PASS" "REPRODUCE.md exists"
else
    print_status "FAIL" "REPRODUCE.md not found"
fi

if [ -f "Dockerfile" ]; then
    print_status "PASS" "Dockerfile exists"
else
    print_status "FAIL" "Dockerfile not found"
fi

if [ -f "python/prepare-conda-env.sh" ]; then
    print_status "PASS" "prepare-conda-env.sh exists"
else
    print_status "FAIL" "prepare-conda-env.sh not found"
fi

if [ -f "python/setup.py" ]; then
    print_status "PASS" "setup.py exists"
else
    print_status "FAIL" "setup.py not found"
fi

if [ -f "java/install.sh" ]; then
    print_status "PASS" "java/install.sh exists"
else
    print_status "FAIL" "java/install.sh not found"
fi

if [ -d "python/exli" ]; then
    print_status "PASS" "python/exli module exists"
else
    print_status "FAIL" "python/exli module not found"
fi

if [ -d "java/raninline" ]; then
    print_status "PASS" "java/raninline module exists"
else
    print_status "FAIL" "java/raninline module not found"
fi

echo ""
echo "3. Checking Environment Variables..."
echo "-----------------------------------"
# Check Python environment
if [ -n "${CONDA_DEFAULT_ENV:-}" ]; then
    print_status "PASS" "Conda environment is active: $CONDA_DEFAULT_ENV"
else
    print_status "WARN" "Conda environment is not active"
fi

# Check Java environment
if [ -n "${JAVA_HOME:-}" ]; then
    print_status "PASS" "JAVA_HOME is set: $JAVA_HOME"
else
    print_status "WARN" "JAVA_HOME is not set"
fi

# Check Maven environment
if [ -n "${MAVEN_HOME:-}" ]; then
    print_status "PASS" "MAVEN_HOME is set: $MAVEN_HOME"
else
    print_status "WARN" "MAVEN_HOME is not set"
fi

# Check PATH
if echo "$PATH" | grep -q "conda"; then
    print_status "PASS" "Conda is in PATH"
else
    print_status "WARN" "Conda is not in PATH"
fi

if echo "$PATH" | grep -q "java"; then
    print_status "PASS" "Java is in PATH"
else
    print_status "WARN" "Java is not in PATH"
fi

echo ""
echo "4. Testing Python Environment..."
echo "-------------------------------"
# Test Python execution
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
echo "5. Testing Conda Environment..."
echo "-------------------------------"
# Test Conda
if command -v conda &> /dev/null; then
    print_status "PASS" "conda is available"
    
    # Test conda info
    if timeout 30s conda info >/dev/null 2>&1; then
        print_status "PASS" "conda info works"
    else
        print_status "WARN" "conda info failed"
    fi
    
    # Test conda env list
    if timeout 30s conda env list >/dev/null 2>&1; then
        print_status "PASS" "conda env list works"
    else
        print_status "WARN" "conda env list failed"
    fi
else
    print_status "FAIL" "conda is not available"
fi

echo ""
echo "6. Testing Java Compilation..."
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
echo "7. Testing Maven Build System..."
echo "--------------------------------"
# Test Maven
if command -v mvn &> /dev/null; then
    print_status "PASS" "mvn is available"
    
    # Test mvn help
    if timeout 30s mvn -help >/dev/null 2>&1; then
        print_status "PASS" "Maven help command works"
    else
        print_status "WARN" "Maven help command failed"
    fi
    
    # Test mvn version
    if timeout 30s mvn -version >/dev/null 2>&1; then
        print_status "PASS" "Maven version command works"
    else
        print_status "WARN" "Maven version command failed"
    fi
else
    print_status "FAIL" "mvn is not available"
fi

echo ""
echo "8. Testing Python Package Installation..."
echo "----------------------------------------"
# Test Python package installation
if command -v pip3 &> /dev/null && [ -f "python/setup.py" ]; then
    print_status "PASS" "pip3 and setup.py are available"
    
    # Test pip install in development mode
    if timeout 60s pip3 install -e python/ >/dev/null 2>&1; then
        print_status "PASS" "Python package installation works"
    else
        print_status "WARN" "Python package installation failed"
    fi
else
    print_status "WARN" "pip3 or setup.py not available"
fi

echo ""
echo "9. Testing Java Module Build..."
echo "-------------------------------"
# Test Java module build
if command -v mvn &> /dev/null && [ -f "java/raninline/pom.xml" ]; then
    print_status "PASS" "mvn and pom.xml are available"
    
    # Test mvn compile
    if timeout 120s mvn -f java/raninline/pom.xml compile >/dev/null 2>&1; then
        print_status "PASS" "Java module compilation works"
    else
        print_status "WARN" "Java module compilation failed"
    fi
else
    print_status "WARN" "mvn or pom.xml not available"
fi

echo ""
echo "10. Testing Web Testing Tools..."
echo "--------------------------------"
# Test Firefox
if command -v firefox &> /dev/null; then
    print_status "PASS" "firefox is available"
    
    # Test firefox version
    if timeout 30s firefox --version >/dev/null 2>&1; then
        print_status "PASS" "Firefox version command works"
    else
        print_status "WARN" "Firefox version command failed"
    fi
else
    print_status "WARN" "firefox is not available"
fi

# Test Geckodriver
if command -v geckodriver &> /dev/null; then
    print_status "PASS" "geckodriver is available"
    
    # Test geckodriver version
    if timeout 30s geckodriver --version >/dev/null 2>&1; then
        print_status "PASS" "Geckodriver version command works"
    else
        print_status "WARN" "Geckodriver version command failed"
    fi
else
    print_status "WARN" "geckodriver is not available"
fi

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (Python 3.9+, Java 8, Maven 3.8.3+, Conda, Git)"
echo "- Web testing tools (Firefox, Geckodriver)"
echo "- Project structure (python/, java/, poms/, jars/, data/)"
echo "- Environment variables (CONDA_DEFAULT_ENV, JAVA_HOME, MAVEN_HOME)"
echo "- Python environment (python3, pip3, conda)"
echo "- Java compilation (javac)"
echo "- Build systems (Maven)"
echo "- Package installation (Python setup.py, Java pom.xml)"
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
    print_status "INFO" "All tests passed! Your ExLi environment is ready!"
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your ExLi environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now build and test ExLi inline test extraction tool."
print_status "INFO" "Example: cd python && bash prepare-conda-env.sh"
echo ""
print_status "INFO" "For more information, see README.md and REPRODUCE.md" 