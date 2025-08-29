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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the elastic_logstash project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t elastic-logstash-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/elastic_logstash" --entrypoint="" elastic-logstash-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        # Source environment variables
        source /etc/profile.d/envgym_java.sh
        cd /home/cc/EnvGym/data/elastic_logstash
        bash envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "Elastic Logstash Environment Benchmark Test"
echo "=========================================="
echo ""


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
    if [ -n "$gradle_version" ] && [ "$gradle_version" != "to" ]; then
        gradle_major=$(echo "$gradle_version" | cut -d'.' -f1)
        if [ -n "$gradle_major" ] && [ "$gradle_major" -ge 8 ]; then
            print_status "PASS" "Gradle version >= 8 ($gradle_version)"
        else
            print_status "WARN" "Gradle version < 8 ($gradle_version)"
        fi
    else
        print_status "WARN" "Could not determine Gradle version"
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
echo "8. Testing Bundle Install..."
echo "---------------------------"
# Test bundle install functionality
if command -v jruby &> /dev/null; then
    if jruby -S bundle -v >/dev/null 2>&1; then
        print_status "PASS" "Bundler is available"
        
        # Test bundle install (critical for development environment)
        if [ -f "Gemfile" ]; then
            print_status "PASS" "Gemfile exists"
            
            if timeout 300s jruby -S bundle install >/dev/null 2>&1; then
                print_status "PASS" "Bundle install successful"
            else
                print_status "FAIL" "Bundle install failed"
            fi
        else
            print_status "WARN" "Gemfile not found"
        fi
    else
        print_status "FAIL" "Bundler is not available"
    fi
else
    print_status "FAIL" "JRuby not available for bundle testing"
fi

echo ""
echo "9. Testing Gradle Build System..."
echo "--------------------------------"
# Test actual gradle functionality (not just presence)
if command -v gradle &> /dev/null || [ -f "./gradlew" ]; then
    gradle_cmd="gradle"
    if [ -f "./gradlew" ]; then
        gradle_cmd="./gradlew"
        print_status "PASS" "Gradle wrapper available"
    else
        print_status "PASS" "Gradle available"
    fi
    
    # Test gradle tasks
    if timeout 60s $gradle_cmd tasks >/dev/null 2>&1; then
        print_status "PASS" "Gradle tasks command works"
    else
        print_status "WARN" "Gradle tasks command failed"
    fi
    
    # Test installDevelopmentGems (critical for development)
    if timeout 300s $gradle_cmd installDevelopmentGems >/dev/null 2>&1; then
        print_status "PASS" "Gradle installDevelopmentGems successful"
    else
        print_status "FAIL" "Gradle installDevelopmentGems failed"
    fi
    
    # Test installDefaultGems
    if timeout 300s $gradle_cmd installDefaultGems >/dev/null 2>&1; then
        print_status "PASS" "Gradle installDefaultGems successful"
    else
        print_status "WARN" "Gradle installDefaultGems failed"
    fi
else
    print_status "FAIL" "Gradle or gradlew not available"
fi

echo ""
echo "10. Testing Logstash Plugin Functionality..."
echo "-------------------------------------------"
# Test logstash-plugin actual functionality
if [ -f "bin/logstash-plugin" ] && [ -x "bin/logstash-plugin" ]; then
    print_status "PASS" "logstash-plugin binary is available"
    
    # Test logstash-plugin list (core functionality)
    if timeout 60s bin/logstash-plugin list >/dev/null 2>&1; then
        print_status "PASS" "logstash-plugin list works"
    else
        print_status "FAIL" "logstash-plugin list failed"
    fi
    
    # Test logstash-plugin help
    if timeout 30s bin/logstash-plugin --help >/dev/null 2>&1; then
        print_status "PASS" "logstash-plugin help works"
    else
        print_status "WARN" "logstash-plugin help failed"
    fi
else
    print_status "FAIL" "logstash-plugin binary not available"
fi

echo ""
echo "11. Testing Logstash Startup (Primary Verification)..."
echo "----------------------------------------------------"
# Test the primary verification from documentation
if [ -f "bin/logstash" ] && [ -x "bin/logstash" ]; then
    print_status "PASS" "logstash binary is available"
    
    # Test logstash help first
    if timeout 30s bin/logstash --help >/dev/null 2>&1; then
        print_status "PASS" "logstash help works"
    else
        print_status "WARN" "logstash help failed"
    fi
    
    # Test the primary verification command from docs (non-interactive)
    # bin/logstash -e 'input { stdin { } } output { stdout {} }'
    # We'll test this by starting it and checking if it initializes properly
    if timeout 120s bin/logstash -e 'input { generator { count => 1 } } output { stdout {} }' >/dev/null 2>&1; then
        print_status "PASS" "Logstash startup and basic pipeline execution successful"
    else
        print_status "FAIL" "Logstash startup or pipeline execution failed"
    fi
    
    # Test logstash version
    if timeout 30s bin/logstash --version >/dev/null 2>&1; then
        print_status "PASS" "logstash version command works"
    else
        print_status "WARN" "logstash version command failed"
    fi
else
    print_status "FAIL" "logstash binary not available"
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
echo "- Bundle install functionality (critical for development)"
echo "- Gradle build system (tasks, installDevelopmentGems, installDefaultGems)"
echo "- Logstash plugin functionality (list, help commands)"
echo "- Logstash startup and pipeline execution (primary verification test)"
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
    print_status "INFO" "All tests passed! Your elastic_logstash environment is ready!"
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your elastic_logstash environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi

print_status "INFO" "You can now build and test Elastic Logstash."
print_status "INFO" "Example: ./gradlew installDevelopmentGems && ./gradlew installDefaultGems"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/elastic_logstash elastic-logstash-env-test /bin/bash"
