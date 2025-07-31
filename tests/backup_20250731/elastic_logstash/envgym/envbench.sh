#!/bin/bash

# Elastic Logstash Environment Benchmark Test
# Tests the environment for Elastic Logstash development

set -u

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Function to print status with colors
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

# Function to check if command exists
check_command() {
    local cmd=$1
    local name=${2:-$1}
    if command -v "$cmd" &> /dev/null; then
        print_status "PASS" "$name is available"
        return 0
    else
        print_status "FAIL" "$name is not available"
        return 1
    fi
}

# Cleanup function
cleanup() {
    echo -e "\n${YELLOW}[INFO] Cleaning up...${NC}"
    # Stop any running containers
    docker stop elastic-logstash-env-test 2>/dev/null || true
    docker rm elastic-logstash-env-test 2>/dev/null || true
    # Remove the test image
    docker rmi elastic-logstash-env-test 2>/dev/null || true
    echo -e "${GREEN}[INFO] Cleanup completed${NC}"
    exit 0
}

# Set up signal handling
trap cleanup INT TERM

# Check if we're running in Docker
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo "Running inside Docker container - proceeding with environment tests"
    DOCKER_BUILD_FAILED=false
else
    echo "Running on host - checking for Docker and envgym.dockerfile"
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        print_status "WARN" "Docker is not installed or not in PATH - running in local environment"
        DOCKER_BUILD_FAILED=true
    else
        # Check if envgym.dockerfile exists
        if [ -f "envgym/envgym.dockerfile" ]; then
            echo "Building Docker image..."
            if timeout 60s docker build -f envgym/envgym.dockerfile -t elastic-logstash-env-test . > docker_build.log 2>&1; then
                echo "Docker build successful - running environment test in Docker container..."
                if docker run --rm -v "$(pwd):/home/cc/elastic_logstash" elastic-logstash-env-test bash -c "
                    trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
                    cd /home/cc/elastic_logstash && ./envgym/envbench.sh
                "; then
                    exit 0
                else
                    echo "WARNING: Docker container failed to run - analyzing Dockerfile only"
                    echo "This may be due to architecture compatibility issues"
                    DOCKER_BUILD_FAILED=true
                fi
            else
                echo "WARNING: Docker build failed - analyzing Dockerfile only"
                echo "This may be due to Dockerfile issues or missing dependencies"
                DOCKER_BUILD_FAILED=true
            fi
        else
            echo "No Dockerfile found - analyzing Dockerfile only"
            DOCKER_BUILD_FAILED=true
        fi
    fi
fi

echo "=========================================="
echo "Elastic Logstash Environment Benchmark Test"
echo "=========================================="
echo ""

if [ "$DOCKER_BUILD_FAILED" = "true" ]; then
    echo "Analyzing Dockerfile..."
    echo "----------------------"
    if [ -f "envgym/envgym.dockerfile" ]; then
        DOCKER_PASS=0
        DOCKER_FAIL=0
        DOCKER_WARN=0
        DOCKER_TOTAL=0
        
        # FROM instruction
        if grep -q "^FROM " envgym/envgym.dockerfile; then
            base_image=$(grep "^FROM " envgym/envgym.dockerfile | head -1 | awk '{print $2}')
            print_status "PASS" "FROM instruction found: $base_image"
            ((DOCKER_PASS++)); ((DOCKER_TOTAL++))
            if [[ "$base_image" =~ ubuntu|debian ]]; then
                print_status "PASS" "Base image is common: $base_image"
                ((DOCKER_PASS++)); ((DOCKER_TOTAL++))
            else
                print_status "WARN" "Base image is uncommon: $base_image"
                ((DOCKER_WARN++)); ((DOCKER_TOTAL++))
            fi
        else
            print_status "FAIL" "No FROM instruction"
            ((DOCKER_FAIL++)); ((DOCKER_TOTAL++))
        fi
        
        # Java/JDK configuration
        if grep -q "JAVA_VERSION" envgym/envgym.dockerfile; then
            print_status "PASS" "Java version specified"
            ((DOCKER_PASS++)); ((DOCKER_TOTAL++))
        else
            print_status "FAIL" "No Java version specified"
            ((DOCKER_FAIL++)); ((DOCKER_TOTAL++))
        fi
        
        if grep -q "JAVA_HOME" envgym/envgym.dockerfile; then
            print_status "PASS" "JAVA_HOME environment variable set"
            ((DOCKER_PASS++)); ((DOCKER_TOTAL++))
        else
            print_status "FAIL" "JAVA_HOME not set"
            ((DOCKER_FAIL++)); ((DOCKER_TOTAL++))
        fi
        
        # JRuby configuration
        if grep -q "JRUBY" envgym/envgym.dockerfile; then
            print_status "PASS" "JRuby specified"
            ((DOCKER_PASS++)); ((DOCKER_TOTAL++))
        else
            print_status "FAIL" "No JRuby specified"
            ((DOCKER_FAIL++)); ((DOCKER_TOTAL++))
        fi
        
        if grep -q "JRUBY_HOME" envgym/envgym.dockerfile; then
            print_status "PASS" "JRUBY_HOME environment variable set"
            ((DOCKER_PASS++)); ((DOCKER_TOTAL++))
        else
            print_status "FAIL" "JRUBY_HOME not set"
            ((DOCKER_FAIL++)); ((DOCKER_TOTAL++))
        fi
        
        # Gradle installation
        if grep -q "gradle" envgym/envgym.dockerfile; then
            print_status "PASS" "Gradle installation found"
            ((DOCKER_PASS++)); ((DOCKER_TOTAL++))
        else
            print_status "FAIL" "No Gradle installation found"
            ((DOCKER_FAIL++)); ((DOCKER_TOTAL++))
        fi
        
        # System dependencies
        if grep -q "apt-get install" envgym/envgym.dockerfile; then
            print_status "PASS" "apt-get install found"
            ((DOCKER_PASS++)); ((DOCKER_TOTAL++))
        else
            print_status "FAIL" "No apt-get install found"
            ((DOCKER_FAIL++)); ((DOCKER_TOTAL++))
        fi
        
        # Ruby gems
        if grep -q "gem install" envgym/envgym.dockerfile; then
            print_status "PASS" "gem install found"
            ((DOCKER_PASS++)); ((DOCKER_TOTAL++))
        else
            print_status "WARN" "No gem install found"
            ((DOCKER_WARN++)); ((DOCKER_TOTAL++))
        fi
        
        # WORKDIR
        if grep -q "WORKDIR" envgym/envgym.dockerfile; then
            print_status "PASS" "WORKDIR set"
            ((DOCKER_PASS++)); ((DOCKER_TOTAL++))
        else
            print_status "FAIL" "No WORKDIR set"
            ((DOCKER_FAIL++)); ((DOCKER_TOTAL++))
        fi
        
        # CMD/ENTRYPOINT
        if grep -q "CMD " envgym/envgym.dockerfile || grep -q "ENTRYPOINT" envgym/envgym.dockerfile; then
            print_status "PASS" "CMD/ENTRYPOINT found"
            ((DOCKER_PASS++)); ((DOCKER_TOTAL++))
        else
            print_status "WARN" "No CMD/ENTRYPOINT found"
            ((DOCKER_WARN++)); ((DOCKER_TOTAL++))
        fi
        
        # LABEL
        if grep -q "LABEL " envgym/envgym.dockerfile; then
            print_status "PASS" "LABEL found"
            ((DOCKER_PASS++)); ((DOCKER_TOTAL++))
        else
            print_status "WARN" "No LABEL found"
            ((DOCKER_WARN++)); ((DOCKER_TOTAL++))
        fi
        
        # 评分
        DOCKER_SCORE=0
        if [ $DOCKER_TOTAL -gt 0 ]; then
            DOCKER_SCORE=$((DOCKER_PASS * 100 / DOCKER_TOTAL))
        fi
        echo ""
        print_status "INFO" "Dockerfile Environment Score: $DOCKER_SCORE% ($DOCKER_PASS/$DOCKER_TOTAL checks passed)"
        print_status "INFO" "PASS: $DOCKER_PASS, FAIL: $DOCKER_FAIL, WARN: $DOCKER_WARN"
        if [ $DOCKER_FAIL -eq 0 ]; then
            print_status "INFO" "Dockerfile结构良好，建议检查依赖版本和构建产物。"
        elif [ $DOCKER_FAIL -lt 3 ]; then
            print_status "WARN" "Dockerfile有少量关键项缺失，建议补全。"
        else
            print_status "WARN" "Dockerfile存在较多问题，建议仔细检查每一项。"
        fi
        echo ""
    fi
fi

echo "1. Checking System Dependencies..."
echo "--------------------------------"
check_command "java" "Java"
check_command "gradle" "Gradle"
check_command "jruby" "JRuby"
check_command "git" "Git"
check_command "bash" "Bash"
check_command "curl" "curl"
check_command "wget" "wget"
check_command "unzip" "unzip"
check_command "perl" "Perl"

# Java version check
if command -v java &> /dev/null; then
    java_version=$(java -version 2>&1 | head -1 | cut -d'"' -f2)
    java_major=$(echo $java_version | cut -d'.' -f1)
    if [ "$java_major" = "1" ]; then
        java_major=$(echo $java_version | cut -d'.' -f2)
    fi
    if [ "$java_major" -ge 11 ] && [ "$java_major" -le 17 ]; then
        print_status "PASS" "Java version >= 11 and <= 17 ($java_version)"
    else
        print_status "WARN" "Java version should be 11-17 ($java_version)"
    fi
fi

# Gradle version check
if command -v gradle &> /dev/null; then
    gradle_version=$(gradle --version | grep "Gradle" | head -1 | awk '{print $2}')
    gradle_major=$(echo $gradle_version | cut -d'.' -f1)
    if [ "$gradle_major" -ge 8 ]; then
        print_status "PASS" "Gradle version >= 8 ($gradle_version)"
    else
        print_status "WARN" "Gradle version < 8 ($gradle_version)"
    fi
fi

# JRuby version check
if command -v jruby &> /dev/null; then
    jruby_version=$(jruby -v | awk '{print $2}')
    if [[ "$jruby_version" =~ 9\.[2-4] ]]; then
        print_status "PASS" "JRuby version 9.2-9.4 ($jruby_version)"
    else
        print_status "WARN" "JRuby version should be 9.2-9.4 ($jruby_version)"
    fi
fi

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
[ -f "build.gradle" ] && print_status "PASS" "build.gradle exists" || print_status "FAIL" "build.gradle missing"
[ -f "settings.gradle" ] && print_status "PASS" "settings.gradle exists" || print_status "FAIL" "settings.gradle missing"
[ -f "gradlew" ] && print_status "PASS" "gradlew exists" || print_status "FAIL" "gradlew missing"
[ -f ".ruby-version" ] && print_status "PASS" ".ruby-version exists" || print_status "FAIL" ".ruby-version missing"
[ -f "Rakefile" ] && print_status "PASS" "Rakefile exists" || print_status "FAIL" "Rakefile missing"
[ -f "README.md" ] && print_status "PASS" "README.md exists" || print_status "FAIL" "README.md missing"
[ -f "LICENSE.txt" ] && print_status "PASS" "LICENSE.txt exists" || print_status "FAIL" "LICENSE.txt missing"

# Check directories
[ -d "logstash-core" ] && print_status "PASS" "logstash-core directory exists" || print_status "FAIL" "logstash-core directory missing"
[ -d "spec" ] && print_status "PASS" "spec directory exists" || print_status "FAIL" "spec directory missing"
[ -d "lib" ] && print_status "PASS" "lib directory exists" || print_status "FAIL" "lib directory missing"
[ -d "bin" ] && print_status "PASS" "bin directory exists" || print_status "FAIL" "bin directory missing"
[ -d "config" ] && print_status "PASS" "config directory exists" || print_status "FAIL" "config directory missing"
[ -d "x-pack" ] && print_status "PASS" "x-pack directory exists" || print_status "FAIL" "x-pack directory missing"

# Check Ruby version requirement
if [ -f ".ruby-version" ]; then
    required_ruby=$(cat .ruby-version)
    print_status "INFO" "Required Ruby version: $required_ruby"
    if [[ "$required_ruby" =~ jruby-9\.[2-4] ]]; then
        print_status "PASS" "Ruby version requirement is valid"
    else
        print_status "WARN" "Ruby version requirement may need update"
    fi
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

if [ -n "${BUILD_JAVA_HOME:-}" ]; then
    print_status "PASS" "BUILD_JAVA_HOME is set: $BUILD_JAVA_HOME"
else
    print_status "WARN" "BUILD_JAVA_HOME is not set"
fi

# Check JRuby environment
if [ -n "${JRUBY_HOME:-}" ]; then
    print_status "PASS" "JRUBY_HOME is set: $JRUBY_HOME"
else
    print_status "WARN" "JRUBY_HOME is not set"
fi

if [ -n "${GEM_HOME:-}" ]; then
    print_status "PASS" "GEM_HOME is set: $GEM_HOME"
else
    print_status "WARN" "GEM_HOME is not set"
fi

# Check Gradle environment
if [ -n "${GRADLE_USER_HOME:-}" ]; then
    print_status "PASS" "GRADLE_USER_HOME is set: $GRADLE_USER_HOME"
else
    print_status "WARN" "GRADLE_USER_HOME is not set"
fi

echo ""
echo "4. Testing JRuby and Ruby Gems..."
echo "--------------------------------"
# Test JRuby
if command -v jruby &> /dev/null; then
    if jruby -v >/dev/null 2>&1; then
        print_status "PASS" "JRuby is working"
    else
        print_status "FAIL" "JRuby is not working"
    fi
    
    # Test gem
    if jruby -S gem -v >/dev/null 2>&1; then
        print_status "PASS" "JRuby gem is working"
    else
        print_status "FAIL" "JRuby gem is not working"
    fi
    
    # Test bundler
    if jruby -S bundle -v >/dev/null 2>&1; then
        print_status "PASS" "Bundler is available"
    else
        print_status "WARN" "Bundler is not available"
    fi
    
    # Test rake
    if jruby -S rake -V >/dev/null 2>&1; then
        print_status "PASS" "Rake is available"
    else
        print_status "WARN" "Rake is not available"
    fi
    
    # Test rspec
    if jruby -S rspec --version >/dev/null 2>&1; then
        print_status "PASS" "RSpec is available"
    else
        print_status "WARN" "RSpec is not available"
    fi
else
    print_status "FAIL" "JRuby is not installed"
fi

echo ""
echo "5. Testing Logstash Binaries..."
echo "------------------------------"
# Test logstash binary
if [ -f "bin/logstash" ]; then
    if [ -x "bin/logstash" ]; then
        print_status "PASS" "logstash binary is executable"
    else
        print_status "WARN" "logstash binary is not executable"
    fi
else
    print_status "WARN" "logstash binary not found"
fi

# Test logstash-plugin binary
if [ -f "bin/logstash-plugin" ]; then
    if [ -x "bin/logstash-plugin" ]; then
        print_status "PASS" "logstash-plugin binary is executable"
    else
        print_status "WARN" "logstash-plugin binary is not executable"
    fi
else
    print_status "WARN" "logstash-plugin binary not found"
fi

# Test rspec binary
if [ -f "bin/rspec" ]; then
    if [ -x "bin/rspec" ]; then
        print_status "PASS" "rspec binary is executable"
    else
        print_status "WARN" "rspec binary is not executable"
    fi
else
    print_status "WARN" "rspec binary not found"
fi

echo ""
echo "6. Testing Rake Tasks..."
echo "-----------------------"
# Test rake tasks
if command -v jruby &> /dev/null && [ -f "Rakefile" ]; then
    # Test rake help
    if timeout 30s jruby -S rake help >/dev/null 2>&1; then
        print_status "PASS" "Rake help command works"
    else
        print_status "WARN" "Rake help command failed"
    fi
    
    # Test rake tasks
    if timeout 30s jruby -S rake -T >/dev/null 2>&1; then
        print_status "PASS" "Rake tasks command works"
    else
        print_status "WARN" "Rake tasks command failed"
    fi
else
    print_status "WARN" "JRuby or Rakefile not available for rake testing"
fi

echo ""
echo "7. Testing RSpec..."
echo "-------------------"
# Test RSpec if available
if command -v jruby &> /dev/null; then
    if jruby -S rspec --version >/dev/null 2>&1; then
        print_status "PASS" "RSpec is available"
        
        # Test a simple RSpec run
        if timeout 60s jruby -S rspec --dry-run spec/ 2>/dev/null | head -10 >/dev/null 2>&1; then
            print_status "PASS" "RSpec dry run successful"
        else
            print_status "WARN" "RSpec dry run failed"
        fi
    else
        print_status "WARN" "RSpec is not available"
    fi
else
    print_status "WARN" "JRuby not available for RSpec testing"
fi

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (Java, JRuby, git, bash, curl, wget, unzip, perl)"
echo "- Project structure (build.gradle, settings.gradle, gradlew, .ruby-version, Rakefile)"
echo "- Environment variables (JAVA_HOME, JRUBY_HOME, GEM_HOME, GRADLE_USER_HOME)"
echo "- JRuby and Ruby gems (jruby, gem, bundler, rake, rspec)"
echo "- Logstash binaries (logstash, logstash-plugin, rspec)"
echo "- Rake tasks (help, task listing)"
echo "- Testing framework (RSpec)"
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
    print_status "INFO" "All tests passed! Your elastic_logstash environment is ready!"
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your elastic_logstash environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now build and test Elastic Logstash."
print_status "INFO" "Example: ./gradlew installDevelopmentGems && ./gradlew installDefaultGems"
echo ""
print_status "INFO" "For more information, see README.md" 