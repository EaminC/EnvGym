#!/bin/bash

# GlueTest Environment Benchmark Test Script
# This script tests the environment setup for GlueTest: Testing Code Translation via Language Interoperability

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
    # Kill any background processes
    jobs -p | xargs -r kill
    # Remove temporary files
    rm -f docker_build.log
    # Stop and remove Docker container if running
    docker stop gluetest-env-test 2>/dev/null || true
    docker rm gluetest-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the gluetest project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t gluetest-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/gluetest" gluetest-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "GlueTest Environment Benchmark Test"
echo "=========================================="

# Analyze Dockerfile if build failed
if [ ! -f /.dockerenv ] && ! grep -q docker /proc/1/cgroup 2>/dev/null; then
    if [ -f "envgym/envgym.dockerfile" ]; then
        echo ""
        echo "Analyzing Dockerfile..."
        echo "----------------------"
        
        # Check Dockerfile structure
        if grep -q "FROM" envgym/envgym.dockerfile; then
            print_status "PASS" "FROM instruction found"
        else
            print_status "FAIL" "FROM instruction not found"
        fi
        
        if grep -q "ubuntu:22.04" envgym/envgym.dockerfile; then
            print_status "PASS" "Ubuntu 22.04 specified"
        else
            print_status "WARN" "Ubuntu 22.04 not specified"
        fi
        
        if grep -q "WORKDIR" envgym/envgym.dockerfile; then
            print_status "PASS" "WORKDIR set"
        else
            print_status "WARN" "WORKDIR not set"
        fi
        
        if grep -q "build-essential" envgym/envgym.dockerfile; then
            print_status "PASS" "build-essential found"
        else
            print_status "FAIL" "build-essential not found"
        fi
        
        if grep -q "maven" envgym/envgym.dockerfile; then
            print_status "PASS" "maven found"
        else
            print_status "FAIL" "maven not found"
        fi
        
        if grep -q "python3" envgym/envgym.dockerfile; then
            print_status "PASS" "python3 found"
        else
            print_status "FAIL" "python3 not found"
        fi
        
        if grep -q "graalvm" envgym/envgym.dockerfile; then
            print_status "PASS" "graalvm found"
        else
            print_status "FAIL" "graalvm not found"
        fi
        
        if grep -q "pyenv" envgym/envgym.dockerfile; then
            print_status "PASS" "pyenv found"
        else
            print_status "WARN" "pyenv not found"
        fi
        
        if grep -q "pytest" envgym/envgym.dockerfile; then
            print_status "PASS" "pytest found"
        else
            print_status "WARN" "pytest not found"
        fi
        
        if grep -q "git" envgym/envgym.dockerfile; then
            print_status "PASS" "git found"
        else
            print_status "WARN" "git not found"
        fi
        
        if grep -q "curl" envgym/envgym.dockerfile; then
            print_status "PASS" "curl found"
        else
            print_status "WARN" "curl not found"
        fi
        
        if grep -q "COPY" envgym/envgym.dockerfile; then
            print_status "PASS" "COPY instruction found"
        else
            print_status "WARN" "COPY instruction not found"
        fi
        
        if grep -q "CMD" envgym/envgym.dockerfile; then
            print_status "PASS" "CMD found"
        else
            print_status "WARN" "CMD not found"
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
    java_version=$(java -version 2>&1 | head -n 1)
    print_status "PASS" "Java is available: $java_version"
else
    print_status "FAIL" "Java is not available"
fi

# Check javac
if command -v javac &> /dev/null; then
    javac_version=$(javac -version 2>&1)
    print_status "PASS" "javac is available: $javac_version"
else
    print_status "FAIL" "javac is not available"
fi

# Check Maven
if command -v mvn &> /dev/null; then
    mvn_version=$(mvn --version 2>&1 | head -n 1)
    print_status "PASS" "Maven is available: $mvn_version"
else
    print_status "FAIL" "Maven is not available"
fi

# Check Python3
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>&1)
    print_status "PASS" "Python3 is available: $python_version"
    
    # Check Python version (should be >= 3.10)
    python_major=$(echo $python_version | cut -d' ' -f2 | cut -d'.' -f1)
    python_minor=$(echo $python_version | cut -d' ' -f2 | cut -d'.' -f2)
    if [ -n "$python_major" ] && [ "$python_major" -eq 3 ] && [ -n "$python_minor" ] && [ "$python_minor" -ge 10 ]; then
        print_status "PASS" "Python version is >= 3.10 (compatible)"
    else
        print_status "WARN" "Python version should be >= 3.10 (found: $python_major.$python_minor)"
    fi
else
    print_status "FAIL" "Python3 is not available"
fi

# Check pip3
if command -v pip3 &> /dev/null; then
    pip_version=$(pip3 --version 2>&1)
    print_status "PASS" "pip3 is available: $pip_version"
else
    print_status "FAIL" "pip3 is not available"
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

# Check build tools
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version 2>&1 | head -n 1)
    print_status "PASS" "GCC is available: $gcc_version"
else
    print_status "WARN" "GCC is not available"
fi

if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "Make is available: $make_version"
else
    print_status "WARN" "Make is not available"
fi

# Check GraalVM
if command -v gu &> /dev/null; then
    print_status "PASS" "GraalVM gu is available"
else
    print_status "WARN" "GraalVM gu is not available"
fi

if command -v graalpython &> /dev/null; then
    graalpython_version=$(graalpython --version 2>&1)
    print_status "PASS" "GraalPython is available: $graalpython_version"
else
    print_status "WARN" "GraalPython is not available"
fi

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "commons-cli" ]; then
    print_status "PASS" "commons-cli directory exists"
else
    print_status "FAIL" "commons-cli directory not found"
fi

if [ -d "commons-cli-python" ]; then
    print_status "PASS" "commons-cli-python directory exists"
else
    print_status "FAIL" "commons-cli-python directory not found"
fi

if [ -d "commons-cli-graal" ]; then
    print_status "PASS" "commons-cli-graal directory exists"
else
    print_status "FAIL" "commons-cli-graal directory not found"
fi

if [ -d "commons-csv" ]; then
    print_status "PASS" "commons-csv directory exists"
else
    print_status "FAIL" "commons-csv directory not found"
fi

if [ -d "commons-csv-python" ]; then
    print_status "PASS" "commons-csv-python directory exists"
else
    print_status "FAIL" "commons-csv-python directory not found"
fi

if [ -d "commons-csv-graal" ]; then
    print_status "PASS" "commons-csv-graal directory exists"
else
    print_status "FAIL" "commons-csv-graal directory not found"
fi

if [ -d "graal-glue-generator" ]; then
    print_status "PASS" "graal-glue-generator directory exists"
else
    print_status "FAIL" "graal-glue-generator directory not found"
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

if [ -f "run.sh" ]; then
    print_status "PASS" "run.sh exists"
else
    print_status "FAIL" "run.sh not found"
fi

if [ -f "CITATION.bib" ]; then
    print_status "PASS" "CITATION.bib exists"
else
    print_status "FAIL" "CITATION.bib not found"
fi

# Check Maven files
if [ -f "commons-cli/pom.xml" ]; then
    print_status "PASS" "commons-cli/pom.xml exists"
else
    print_status "FAIL" "commons-cli/pom.xml not found"
fi

if [ -f "commons-csv/pom.xml" ]; then
    print_status "PASS" "commons-csv/pom.xml exists"
else
    print_status "FAIL" "commons-csv/pom.xml not found"
fi

if [ -f "commons-cli-graal/pom.xml" ]; then
    print_status "PASS" "commons-cli-graal/pom.xml exists"
else
    print_status "FAIL" "commons-cli-graal/pom.xml not found"
fi

if [ -f "commons-csv-graal/pom.xml" ]; then
    print_status "PASS" "commons-csv-graal/pom.xml exists"
else
    print_status "FAIL" "commons-csv-graal/pom.xml not found"
fi

if [ -f "graal-glue-generator/pom.xml" ]; then
    print_status "PASS" "graal-glue-generator/pom.xml exists"
else
    print_status "FAIL" "graal-glue-generator/pom.xml not found"
fi

# Check script files
if [ -f "scripts/generate_glue.py" ]; then
    print_status "PASS" "scripts/generate_glue.py exists"
else
    print_status "FAIL" "scripts/generate_glue.py not found"
fi

if [ -d "scripts/coverage" ]; then
    print_status "PASS" "scripts/coverage directory exists"
else
    print_status "FAIL" "scripts/coverage directory not found"
fi

if [ -d "scripts/clients" ]; then
    print_status "PASS" "scripts/clients directory exists"
else
    print_status "FAIL" "scripts/clients directory not found"
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

if [ -n "${MAVEN_HOME:-}" ]; then
    print_status "PASS" "MAVEN_HOME is set: $MAVEN_HOME"
else
    print_status "WARN" "MAVEN_HOME is not set"
fi

# Check Python environment
if [ -n "${PYTHONPATH:-}" ]; then
    print_status "PASS" "PYTHONPATH is set: $PYTHONPATH"
else
    print_status "WARN" "PYTHONPATH is not set"
fi

if [ -n "${VIRTUAL_ENV:-}" ]; then
    print_status "PASS" "VIRTUAL_ENV is set: $VIRTUAL_ENV"
else
    print_status "WARN" "VIRTUAL_ENV is not set"
fi

# Check PATH
if echo "$PATH" | grep -q "java"; then
    print_status "PASS" "java is in PATH"
else
    print_status "WARN" "java is not in PATH"
fi

if echo "$PATH" | grep -q "mvn"; then
    print_status "PASS" "mvn is in PATH"
else
    print_status "WARN" "mvn is not in PATH"
fi

if echo "$PATH" | grep -q "python"; then
    print_status "PASS" "python is in PATH"
else
    print_status "WARN" "python is not in PATH"
fi

if echo "$PATH" | grep -q "pip"; then
    print_status "PASS" "pip is in PATH"
else
    print_status "WARN" "pip is not in PATH"
fi

echo ""
echo "4. Testing Java Environment..."
echo "-----------------------------"
# Test Java
if command -v java &> /dev/null; then
    print_status "PASS" "java is available"
    
    # Test Java execution
    if timeout 30s java -version >/dev/null 2>&1; then
        print_status "PASS" "Java execution works"
    else
        print_status "WARN" "Java execution failed"
    fi
else
    print_status "FAIL" "java is not available"
fi

# Test javac
if command -v javac &> /dev/null; then
    print_status "PASS" "javac is available"
    
    # Test simple Java compilation
    echo 'public class Test { public static void main(String[] args) { System.out.println("Hello from Java"); } }' > Test.java
    
    if timeout 30s javac Test.java 2>/dev/null; then
        print_status "PASS" "Java compilation works"
        if timeout 30s java Test 2>/dev/null; then
            print_status "PASS" "Java execution works"
        else
            print_status "WARN" "Java execution failed"
        fi
        rm -f Test.java Test.class
    else
        print_status "WARN" "Java compilation failed"
        rm -f Test.java
    fi
else
    print_status "FAIL" "javac is not available"
fi

echo ""
echo "5. Testing Maven Build System..."
echo "--------------------------------"
# Test Maven
if command -v mvn &> /dev/null; then
    print_status "PASS" "mvn is available"
    
    # Test mvn version
    if timeout 30s mvn --version >/dev/null 2>&1; then
        print_status "PASS" "Maven version command works"
    else
        print_status "WARN" "Maven version command failed"
    fi
    
    # Test mvn help
    if timeout 30s mvn help >/dev/null 2>&1; then
        print_status "PASS" "Maven help command works"
    else
        print_status "WARN" "Maven help command failed"
    fi
else
    print_status "FAIL" "mvn is not available"
fi

echo ""
echo "6. Testing Python Environment..."
echo "-------------------------------"
# Test Python3
if command -v python3 &> /dev/null; then
    print_status "PASS" "python3 is available"
    
    # Test Python3 execution
    if timeout 30s python3 -c "print('Hello from Python3')" >/dev/null 2>&1; then
        print_status "PASS" "Python3 execution works"
    else
        print_status "WARN" "Python3 execution failed"
    fi
    
    # Test Python3 import system
    if timeout 30s python3 -c "import sys; print('Python path:', sys.path[0])" >/dev/null 2>&1; then
        print_status "PASS" "Python3 import system works"
    else
        print_status "WARN" "Python3 import system failed"
    fi
else
    print_status "FAIL" "python3 is not available"
fi

echo ""
echo "7. Testing Package Management..."
echo "-------------------------------"
# Test pip3
if command -v pip3 &> /dev/null; then
    print_status "PASS" "pip3 is available"
    
    # Test pip3 version
    if timeout 30s pip3 --version >/dev/null 2>&1; then
        print_status "PASS" "pip3 version command works"
    else
        print_status "WARN" "pip3 version command failed"
    fi
    
    # Test pip3 list
    if timeout 30s pip3 list >/dev/null 2>&1; then
        print_status "PASS" "pip3 list command works"
    else
        print_status "WARN" "pip3 list command failed"
    fi
else
    print_status "FAIL" "pip3 is not available"
fi

echo ""
echo "8. Testing GlueTest Dependencies..."
echo "-----------------------------------"
# Test pytest
if command -v python3 &> /dev/null; then
    if timeout 30s python3 -c "import pytest; print('Pytest version:', pytest.__version__)" >/dev/null 2>&1; then
        print_status "PASS" "pytest is available"
    else
        print_status "WARN" "pytest is not available"
    fi
else
    print_status "WARN" "python3 not available for pytest testing"
fi

# Test GraalVM components
if command -v gu &> /dev/null; then
    print_status "PASS" "gu is available"
    
    # Test gu list
    if timeout 30s gu list >/dev/null 2>&1; then
        print_status "PASS" "gu list command works"
    else
        print_status "WARN" "gu list command failed"
    fi
    
    # Test gu version
    if timeout 30s gu --version >/dev/null 2>&1; then
        print_status "PASS" "gu version command works"
    else
        print_status "WARN" "gu version command failed"
    fi
else
    print_status "WARN" "gu is not available"
fi

# Test GraalPython
if command -v graalpython &> /dev/null; then
    print_status "PASS" "graalpython is available"
    
    # Test graalpython execution
    if timeout 30s graalpython --version >/dev/null 2>&1; then
        print_status "PASS" "GraalPython execution works"
    else
        print_status "WARN" "GraalPython execution failed"
    fi
else
    print_status "WARN" "graalpython is not available"
fi

echo ""
echo "9. Testing GlueTest Scripts..."
echo "-------------------------------"
# Test run.sh script
if [ -f "run.sh" ] && [ -x "run.sh" ]; then
    print_status "PASS" "run.sh exists and is executable"
else
    print_status "WARN" "run.sh not found or not executable"
fi

# Test if scripts can be made executable
if [ -f "run.sh" ]; then
    if chmod +x run.sh 2>/dev/null; then
        print_status "PASS" "run.sh can be made executable"
    else
        print_status "WARN" "run.sh cannot be made executable"
    fi
fi

# Test generate_glue.py script and verify output
if [ -f "scripts/generate_glue.py" ]; then
    print_status "PASS" "scripts/generate_glue.py exists"
    
    if command -v python3 &> /dev/null; then
        # Run once, capture both exit code and output
        output=$(timeout 360s python3 -c "import sys; sys.path.append('scripts'); exec(open('scripts/generate_glue.py').read())" 2>&1)
        exit_code=$?
        
        # Test 1: Check if script finished within 6 minutes
        if [ $exit_code -eq 0 ]; then
            print_status "PASS" "scripts/generate_glue.py completed within 6 minutes"
        else
            print_status "FAIL" "scripts/generate_glue.py timed out or failed"
        fi
        
        # Test 2: Check for BUILD FAIL in output (only if we have output)
        if [ $exit_code -ne 124 ]; then  # 124 = timeout exit code
            if echo "$output" | grep -iq "BUILD FAIL"; then
                print_status "FAIL" "scripts/generate_glue.py output contains build failures"
            else
                print_status "PASS" "scripts/generate_glue.py output clean (no build failures)"
            fi
        else
            print_status "FAIL" "scripts/generate_glue.py timed out - no output to analyze"
        fi
    else
        print_status "FAIL" "python3 not available for script execution test"
    fi
else
    print_status "FAIL" "scripts/generate_glue.py not found"
fi

echo ""
echo "10. Testing Maven Projects..."
echo "-----------------------------"
# Test Maven project compilation
if command -v mvn &> /dev/null; then
    print_status "PASS" "mvn is available for project testing"
    
    # Test commons-cli compilation
    if [ -f "commons-cli/pom.xml" ]; then
        if timeout 120s mvn -f commons-cli/pom.xml compile -q >/dev/null 2>&1; then
            print_status "PASS" "commons-cli compilation successful"
        else
            print_status "WARN" "commons-cli compilation failed or timed out"
        fi
    else
        print_status "FAIL" "commons-cli/pom.xml not found"
    fi
    
    # Test commons-csv compilation
    if [ -f "commons-csv/pom.xml" ]; then
        if timeout 120s mvn -f commons-csv/pom.xml compile -q >/dev/null 2>&1; then
            print_status "PASS" "commons-csv compilation successful"
        else
            print_status "WARN" "commons-csv compilation failed or timed out"
        fi
    else
        print_status "FAIL" "commons-csv/pom.xml not found"
    fi
    
    # Test graal-glue-generator compilation
    if [ -f "graal-glue-generator/pom.xml" ]; then
        if timeout 120s mvn -f graal-glue-generator/pom.xml compile -q >/dev/null 2>&1; then
            print_status "PASS" "graal-glue-generator compilation successful"
        else
            print_status "WARN" "graal-glue-generator compilation failed or timed out"
        fi
    else
        print_status "FAIL" "graal-glue-generator/pom.xml not found"
    fi
else
    print_status "WARN" "mvn not available for project testing"
fi

echo ""
echo "11. Testing Python Projects..."
echo "-------------------------------"
# Test Python project execution
if command -v python3 &> /dev/null; then
    print_status "PASS" "python3 is available for project testing"
    
    # Test pytest availability
    if timeout 30s python3 -c "import pytest; print('pytest available')" >/dev/null 2>&1; then
        print_status "PASS" "pytest is available for testing"
        
        # Test commons-cli-python
        if [ -d "commons-cli-python" ]; then
            if timeout 60s python3 -m pytest commons-cli-python --collect-only -q >/dev/null 2>&1; then
                print_status "PASS" "commons-cli-python pytest collection works"
            else
                print_status "WARN" "commons-cli-python pytest collection failed"
            fi
        else
            print_status "FAIL" "commons-cli-python directory not found"
        fi
        
        # Test commons-csv-python
        if [ -d "commons-csv-python" ]; then
            if timeout 60s python3 -m pytest commons-csv-python --collect-only -q >/dev/null 2>&1; then
                print_status "PASS" "commons-csv-python pytest collection works"
            else
                print_status "WARN" "commons-csv-python pytest collection failed"
            fi
        else
            print_status "FAIL" "commons-csv-python directory not found"
        fi
    else
        print_status "WARN" "pytest not available for testing"
    fi
else
    print_status "WARN" "python3 not available for project testing"
fi

echo ""
echo "12. Testing GraalVM Integration..."
echo "----------------------------------"
# Test GraalVM integration projects
if command -v mvn &> /dev/null; then
    print_status "PASS" "mvn is available for GraalVM testing"
    
    # Test commons-cli-graal compilation
    if [ -f "commons-cli-graal/pom.xml" ]; then
        if timeout 120s mvn -f commons-cli-graal/pom.xml compile -q >/dev/null 2>&1; then
            print_status "PASS" "commons-cli-graal compilation successful"
        else
            print_status "WARN" "commons-cli-graal compilation failed or timed out"
        fi
    else
        print_status "FAIL" "commons-cli-graal/pom.xml not found"
    fi
    
    # Test commons-csv-graal compilation
    if [ -f "commons-csv-graal/pom.xml" ]; then
        if timeout 120s mvn -f commons-csv-graal/pom.xml compile -q >/dev/null 2>&1; then
            print_status "PASS" "commons-csv-graal compilation successful"
        else
            print_status "WARN" "commons-csv-graal compilation failed or timed out"
        fi
    else
        print_status "FAIL" "commons-csv-graal/pom.xml not found"
    fi
else
    print_status "WARN" "mvn not available for GraalVM testing"
fi

echo ""
echo "13. Testing Coverage Tools..."
echo "-----------------------------"
# Test coverage tools
if [ -d "scripts/coverage" ]; then
    print_status "PASS" "scripts/coverage directory exists"
    
    # Test cover_local.py
    if [ -f "scripts/coverage/cover_local.py" ]; then
        print_status "PASS" "scripts/coverage/cover_local.py exists"
        
        if command -v python3 &> /dev/null; then
            if timeout 30s python3 -c "import sys; sys.path.append('scripts/coverage'); exec(open('scripts/coverage/cover_local.py').read())" >/dev/null 2>&1; then
                print_status "PASS" "scripts/coverage/cover_local.py can be executed"
            else
                print_status "WARN" "scripts/coverage/cover_local.py execution failed"
            fi
        else
            print_status "WARN" "python3 not available for coverage testing"
        fi
    else
        print_status "FAIL" "scripts/coverage/cover_local.py not found"
    fi
else
    print_status "FAIL" "scripts/coverage directory not found"
fi

echo ""
echo "14. Testing Client Collection Tools..."
echo "--------------------------------------"
# Test client collection tools
if [ -d "scripts/clients" ]; then
    print_status "PASS" "scripts/clients directory exists"
    
    # Test selenium.py
    if [ -f "scripts/clients/selenium.py" ]; then
        print_status "PASS" "scripts/clients/selenium.py exists"
    else
        print_status "FAIL" "scripts/clients/selenium.py not found"
    fi
    
    # Test bash_script_version.sh
    if [ -f "scripts/clients/bash_script_version.sh" ]; then
        print_status "PASS" "scripts/clients/bash_script_version.sh exists"
        
        if [ -x "scripts/clients/bash_script_version.sh" ]; then
            print_status "PASS" "scripts/clients/bash_script_version.sh is executable"
        else
            print_status "WARN" "scripts/clients/bash_script_version.sh is not executable"
        fi
    else
        print_status "FAIL" "scripts/clients/bash_script_version.sh not found"
    fi
else
    print_status "FAIL" "scripts/clients directory not found"
fi

echo ""
echo "15. Testing Documentation..."
echo "----------------------------"
# Test if documentation files are readable
if [ -r "README.md" ]; then
    print_status "PASS" "README.md is readable"
else
    print_status "WARN" "README.md is not readable"
fi

if [ -r "CITATION.bib" ]; then
    print_status "PASS" "CITATION.bib is readable"
else
    print_status "WARN" "CITATION.bib is not readable"
fi

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (Java, javac, Maven, Python3 >= 3.10, pip3, Git, Bash)"
echo "- Project structure (commons-cli, commons-csv, graal-glue-generator, scripts/)"
echo "- Environment variables (JAVA_HOME, MAVEN_HOME, PYTHONPATH, VIRTUAL_ENV, PATH)"
echo "- Java environment (java, javac, compilation)"
echo "- Maven build system (mvn, project compilation)"
echo "- Python environment (python3, import system)"
echo "- Package management (pip3)"
echo "- GlueTest dependencies (pytest, GraalVM gu, GraalPython)"
echo "- GlueTest scripts (run.sh, generate_glue.py)"
echo "- Maven projects (commons-cli, commons-csv, graal-glue-generator)"
echo "- Python projects (commons-cli-python, commons-csv-python)"
echo "- GraalVM integration (commons-cli-graal, commons-csv-graal)"
echo "- Coverage tools (cover_local.py)"
echo "- Client collection tools (selenium.py, bash_script_version.sh)"
echo "- Documentation (README.md, CITATION.bib)"
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
    print_status "INFO" "All tests passed! Your GlueTest environment is ready!"
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your GlueTest environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi

print_status "INFO" "You can now run GlueTest: Testing Code Translation via Language Interoperability."
print_status "INFO" "Example: bash run.sh"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/gluetest gluetest-env-test /bin/bash"
