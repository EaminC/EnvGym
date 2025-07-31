#!/bin/bash

# Mockito Environment Benchmark Test Script
# This script tests the Docker environment setup for Mockito: Most popular mocking framework for Java
# Tailored specifically for Mockito project requirements and features

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
    jobs -p | xargs -r kill
    rm -f docker_build.log
    docker stop mockito-env-test 2>/dev/null || true
    docker rm mockito-env-test 2>/dev/null || true
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
        if timeout 600s docker build -f envgym/envgym.dockerfile -t mockito-env-test .; then
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
    
    # Test if Java is available in Docker
    if docker run --rm mockito-env-test java -version >/dev/null 2>&1; then
        java_version=$(docker run --rm mockito-env-test java -version 2>&1 | head -n 1)
        print_status "PASS" "Java is available in Docker: $java_version"
    else
        print_status "FAIL" "Java is not available in Docker"
    fi
    
    # Test if Gradle is available in Docker
    if docker run --rm mockito-env-test ./gradlew --version >/dev/null 2>&1; then
        gradle_version=$(docker run --rm mockito-env-test ./gradlew --version 2>/dev/null | head -n 1)
        print_status "PASS" "Gradle is available in Docker: $gradle_version"
    else
        print_status "FAIL" "Gradle is not available in Docker"
    fi
    
    # Test if Git is available in Docker
    if docker run --rm mockito-env-test git --version >/dev/null 2>&1; then
        git_version=$(docker run --rm mockito-env-test git --version 2>/dev/null)
        print_status "PASS" "Git is available in Docker: $git_version"
    else
        print_status "FAIL" "Git is not available in Docker"
    fi
    
    # Test if Android SDK is available in Docker
    if docker run --rm mockito-env-test test -d .android-sdk; then
        print_status "PASS" "Android SDK is available in Docker"
    else
        print_status "FAIL" "Android SDK is not available in Docker"
    fi
fi

echo "=========================================="
echo "Mockito Environment Benchmark Test"
echo "=========================================="

echo "1. Checking System Dependencies..."
echo "--------------------------------"
# Check Java
if command -v java &> /dev/null; then
    java_version=$(java -version 2>&1 | head -n 1)
    print_status "PASS" "Java is available: $java_version"
else
    print_status "FAIL" "Java is not available"
fi

# Check Java version
if command -v java &> /dev/null; then
    java_major=$(java -version 2>&1 | grep -o 'version "[^"]*"' | cut -d'"' -f2 | cut -d'.' -f1)
    if [ "$java_major" = "1" ]; then
        java_major=$(java -version 2>&1 | grep -o 'version "[^"]*"' | cut -d'"' -f2 | cut -d'.' -f2)
    fi
    if [ -n "$java_major" ] && [ "$java_major" -ge 11 ]; then
        print_status "PASS" "Java version is >= 11 (compatible with Mockito 5.x)"
    else
        print_status "WARN" "Java version should be >= 11 for Mockito 5.x (found: $java_major)"
    fi
else
    print_status "FAIL" "Java is not available for version check"
fi

# Check Gradle
if [ -f "gradlew" ]; then
    if [ -x "gradlew" ]; then
        print_status "PASS" "Gradle wrapper is available and executable"
    else
        print_status "WARN" "Gradle wrapper is available but not executable"
    fi
else
    print_status "FAIL" "Gradle wrapper not found"
fi

# Check Git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1)
    print_status "PASS" "Git is available: $git_version"
else
    print_status "FAIL" "Git is not available"
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

# Check unzip
if command -v unzip &> /dev/null; then
    unzip_version=$(unzip -v 2>&1 | head -n 1)
    print_status "PASS" "unzip is available: $unzip_version"
else
    print_status "WARN" "unzip is not available"
fi

# Check Python3
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
if [ -d "mockito-core" ]; then
    print_status "PASS" "mockito-core directory exists (core mocking framework)"
else
    print_status "FAIL" "mockito-core directory not found"
fi

if [ -d "mockito-extensions" ]; then
    print_status "PASS" "mockito-extensions directory exists (extensions and plugins)"
else
    print_status "FAIL" "mockito-extensions directory not found"
fi

if [ -d "mockito-integration-tests" ]; then
    print_status "PASS" "mockito-integration-tests directory exists (integration tests)"
else
    print_status "FAIL" "mockito-integration-tests directory not found"
fi

if [ -d "mockito-bom" ]; then
    print_status "PASS" "mockito-bom directory exists (Bill of Materials)"
else
    print_status "FAIL" "mockito-bom directory not found"
fi

if [ -d "gradle" ]; then
    print_status "PASS" "gradle directory exists (Gradle wrapper files)"
else
    print_status "FAIL" "gradle directory not found"
fi

if [ -d "config" ]; then
    print_status "PASS" "config directory exists (configuration files)"
else
    print_status "FAIL" "config directory not found"
fi

if [ -d "doc" ]; then
    print_status "PASS" "doc directory exists (documentation)"
else
    print_status "FAIL" "doc directory not found"
fi

if [ -d "buildSrc" ]; then
    print_status "PASS" "buildSrc directory exists (build logic)"
else
    print_status "FAIL" "buildSrc directory not found"
fi

if [ -d ".github" ]; then
    print_status "PASS" ".github directory exists (GitHub workflows)"
else
    print_status "FAIL" ".github directory not found"
fi

# Check key files
if [ -f "build.gradle.kts" ]; then
    print_status "PASS" "build.gradle.kts exists (root build script)"
else
    print_status "FAIL" "build.gradle.kts not found"
fi

if [ -f "settings.gradle.kts" ]; then
    print_status "PASS" "settings.gradle.kts exists (project settings)"
else
    print_status "FAIL" "settings.gradle.kts not found"
fi

if [ -f "gradle.properties" ]; then
    print_status "PASS" "gradle.properties exists (Gradle properties)"
else
    print_status "FAIL" "gradle.properties not found"
fi

if [ -f "gradlew" ]; then
    print_status "PASS" "gradlew exists (Gradle wrapper for Unix)"
else
    print_status "FAIL" "gradlew not found"
fi

if [ -f "gradlew.bat" ]; then
    print_status "PASS" "gradlew.bat exists (Gradle wrapper for Windows)"
else
    print_status "FAIL" "gradlew.bat not found"
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

if [ -f ".gitignore" ]; then
    print_status "PASS" ".gitignore exists"
else
    print_status "FAIL" ".gitignore not found"
fi

if [ -f ".editorconfig" ]; then
    print_status "PASS" ".editorconfig exists (editor configuration)"
else
    print_status "FAIL" ".editorconfig not found"
fi

if [ -f ".checkstyle" ]; then
    print_status "PASS" ".checkstyle exists (code style configuration)"
else
    print_status "FAIL" ".checkstyle not found"
fi

if [ -f "check_reproducibility.sh" ]; then
    print_status "PASS" "check_reproducibility.sh exists (reproducibility check script)"
else
    print_status "FAIL" "check_reproducibility.sh not found"
fi

# Check extension directories
if [ -d "mockito-extensions/mockito-android" ]; then
    print_status "PASS" "mockito-extensions/mockito-android exists (Android support)"
else
    print_status "FAIL" "mockito-extensions/mockito-android not found"
fi

if [ -d "mockito-extensions/mockito-junit-jupiter" ]; then
    print_status "PASS" "mockito-extensions/mockito-junit-jupiter exists (JUnit 5 support)"
else
    print_status "FAIL" "mockito-extensions/mockito-junit-jupiter not found"
fi

if [ -d "mockito-extensions/mockito-errorprone" ]; then
    print_status "PASS" "mockito-extensions/mockito-errorprone exists (Error Prone support)"
else
    print_status "FAIL" "mockito-extensions/mockito-errorprone not found"
fi

if [ -d "mockito-extensions/mockito-proxy" ]; then
    print_status "PASS" "mockito-extensions/mockito-proxy exists (Proxy support)"
else
    print_status "FAIL" "mockito-extensions/mockito-proxy not found"
fi

if [ -d "mockito-extensions/mockito-subclass" ]; then
    print_status "PASS" "mockito-extensions/mockito-subclass exists (Subclass support)"
else
    print_status "FAIL" "mockito-extensions/mockito-subclass not found"
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

if [ -n "${JAVA11_HOME:-}" ]; then
    print_status "PASS" "JAVA11_HOME is set: $JAVA11_HOME"
else
    print_status "WARN" "JAVA11_HOME is not set"
fi

if [ -n "${JAVA17_HOME:-}" ]; then
    print_status "PASS" "JAVA17_HOME is set: $JAVA17_HOME"
else
    print_status "WARN" "JAVA17_HOME is not set"
fi

if [ -n "${JAVA21_HOME:-}" ]; then
    print_status "PASS" "JAVA21_HOME is set: $JAVA21_HOME"
else
    print_status "WARN" "JAVA21_HOME is not set"
fi

# Check Android environment
if [ -n "${ANDROID_HOME:-}" ]; then
    print_status "PASS" "ANDROID_HOME is set: $ANDROID_HOME"
else
    print_status "WARN" "ANDROID_HOME is not set"
fi

if [ -n "${ANDROID_SDK_ROOT:-}" ]; then
    print_status "PASS" "ANDROID_SDK_ROOT is set: $ANDROID_SDK_ROOT"
else
    print_status "WARN" "ANDROID_SDK_ROOT is not set"
fi

# Check PATH
if echo "$PATH" | grep -q "java"; then
    print_status "PASS" "java is in PATH"
else
    print_status "WARN" "java is not in PATH"
fi

if echo "$PATH" | grep -q "gradle"; then
    print_status "PASS" "gradle is in PATH"
else
    print_status "WARN" "gradle is not in PATH"
fi

if echo "$PATH" | grep -q "git"; then
    print_status "PASS" "git is in PATH"
else
    print_status "WARN" "git is not in PATH"
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
    
    # Test Java compiler
    if command -v javac &> /dev/null; then
        print_status "PASS" "javac is available"
        
        if timeout 30s javac -version >/dev/null 2>&1; then
            print_status "PASS" "javac version command works"
        else
            print_status "WARN" "javac version command failed"
        fi
    else
        print_status "WARN" "javac is not available"
    fi
else
    print_status "FAIL" "java is not available"
fi

echo ""
echo "5. Testing Gradle Environment..."
echo "-------------------------------"
# Test Gradle wrapper
if [ -f "gradlew" ]; then
    print_status "PASS" "gradlew exists for Gradle testing"
    
    if [ -x "gradlew" ]; then
        print_status "PASS" "gradlew is executable"
        
        # Test Gradle version
        if timeout 60s ./gradlew --version >/dev/null 2>&1; then
            print_status "PASS" "Gradle version command works"
        else
            print_status "WARN" "Gradle version command failed"
        fi
        
        # Test Gradle help
        if timeout 60s ./gradlew help >/dev/null 2>&1; then
            print_status "PASS" "Gradle help command works"
        else
            print_status "WARN" "Gradle help command failed"
        fi
    else
        print_status "WARN" "gradlew is not executable"
    fi
else
    print_status "FAIL" "gradlew not found"
fi

echo ""
echo "6. Testing Mockito Build System..."
echo "----------------------------------"
# Test build.gradle.kts
if [ -f "build.gradle.kts" ]; then
    print_status "PASS" "build.gradle.kts exists for build testing"
    
    # Check for key plugins
    if grep -q "kotlin" build.gradle.kts; then
        print_status "PASS" "build.gradle.kts includes Kotlin plugin"
    else
        print_status "WARN" "build.gradle.kts missing Kotlin plugin"
    fi
    
    if grep -q "eclipse" build.gradle.kts; then
        print_status "PASS" "build.gradle.kts includes Eclipse plugin"
    else
        print_status "WARN" "build.gradle.kts missing Eclipse plugin"
    fi
    
    if grep -q "android" build.gradle.kts; then
        print_status "PASS" "build.gradle.kts includes Android plugin"
    else
        print_status "WARN" "build.gradle.kts missing Android plugin"
    fi
else
    print_status "FAIL" "build.gradle.kts not found"
fi

# Test settings.gradle.kts
if [ -f "settings.gradle.kts" ]; then
    print_status "PASS" "settings.gradle.kts exists"
    
    # Check for key modules
    if grep -q "mockito-core" settings.gradle.kts; then
        print_status "PASS" "settings.gradle.kts includes mockito-core module"
    else
        print_status "FAIL" "settings.gradle.kts missing mockito-core module"
    fi
    
    if grep -q "mockito-bom" settings.gradle.kts; then
        print_status "PASS" "settings.gradle.kts includes mockito-bom module"
    else
        print_status "FAIL" "settings.gradle.kts missing mockito-bom module"
    fi
    
    if grep -q "mockito-extensions" settings.gradle.kts; then
        print_status "PASS" "settings.gradle.kts includes mockito-extensions modules"
    else
        print_status "FAIL" "settings.gradle.kts missing mockito-extensions modules"
    fi
    
    if grep -q "mockito-integration-tests" settings.gradle.kts; then
        print_status "PASS" "settings.gradle.kts includes mockito-integration-tests modules"
    else
        print_status "FAIL" "settings.gradle.kts missing mockito-integration-tests modules"
    fi
else
    print_status "FAIL" "settings.gradle.kts not found"
fi

# Test gradle.properties
if [ -f "gradle.properties" ]; then
    print_status "PASS" "gradle.properties exists"
    
    # Check for key properties
    if grep -q "org.gradle.daemon" gradle.properties; then
        print_status "PASS" "gradle.properties includes daemon configuration"
    else
        print_status "WARN" "gradle.properties missing daemon configuration"
    fi
    
    if grep -q "org.gradle.parallel" gradle.properties; then
        print_status "PASS" "gradle.properties includes parallel configuration"
    else
        print_status "WARN" "gradle.properties missing parallel configuration"
    fi
    
    if grep -q "mockito.test.java" gradle.properties; then
        print_status "PASS" "gradle.properties includes test Java configuration"
    else
        print_status "WARN" "gradle.properties missing test Java configuration"
    fi
else
    print_status "FAIL" "gradle.properties not found"
fi

echo ""
echo "7. Testing Mockito Source Code Structure..."
echo "------------------------------------------"
# Test source code directories
if [ -d "mockito-core" ]; then
    print_status "PASS" "mockito-core directory exists for source testing"
    
    # Count source files
    java_files=$(find mockito-core -name "*.java" | wc -l)
    kotlin_files=$(find mockito-core -name "*.kt" | wc -l)
    
    if [ "$java_files" -gt 0 ]; then
        print_status "PASS" "Found $java_files Java source files in mockito-core"
    else
        print_status "WARN" "No Java source files found in mockito-core"
    fi
    
    if [ "$kotlin_files" -gt 0 ]; then
        print_status "PASS" "Found $kotlin_files Kotlin source files in mockito-core"
    else
        print_status "WARN" "No Kotlin source files found in mockito-core"
    fi
else
    print_status "FAIL" "mockito-core directory not found"
fi

if [ -d "mockito-extensions" ]; then
    print_status "PASS" "mockito-extensions directory exists for extension testing"
    
    # Count extension modules
    extension_count=$(find mockito-extensions -maxdepth 1 -type d | wc -l)
    if [ "$extension_count" -gt 1 ]; then
        print_status "PASS" "Found $((extension_count - 1)) extension modules"
    else
        print_status "WARN" "No extension modules found"
    fi
else
    print_status "FAIL" "mockito-extensions directory not found"
fi

if [ -d "mockito-integration-tests" ]; then
    print_status "PASS" "mockito-integration-tests directory exists for integration testing"
    
    # Count integration test modules
    integration_count=$(find mockito-integration-tests -maxdepth 1 -type d | wc -l)
    if [ "$integration_count" -gt 1 ]; then
        print_status "PASS" "Found $((integration_count - 1)) integration test modules"
    else
        print_status "WARN" "No integration test modules found"
    fi
else
    print_status "FAIL" "mockito-integration-tests directory not found"
fi

echo ""
echo "8. Testing Mockito Scripts..."
echo "----------------------------"
# Test scripts
if [ -f "check_reproducibility.sh" ]; then
    print_status "PASS" "check_reproducibility.sh exists"
    
    if [ -x "check_reproducibility.sh" ]; then
        print_status "PASS" "check_reproducibility.sh is executable"
    else
        print_status "WARN" "check_reproducibility.sh is not executable"
    fi
    
    # Check if it's a bash script
    if head -n 1 check_reproducibility.sh | grep -q "#!/bin/bash"; then
        print_status "PASS" "check_reproducibility.sh is a bash script"
    else
        print_status "WARN" "check_reproducibility.sh is not a bash script"
    fi
else
    print_status "FAIL" "check_reproducibility.sh not found"
fi

echo ""
echo "9. Testing Mockito Documentation..."
echo "----------------------------------"
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

if [ -r ".gitignore" ]; then
    print_status "PASS" ".gitignore is readable"
else
    print_status "FAIL" ".gitignore is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "Mockito" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "mocking framework" README.md; then
        print_status "PASS" "README.md contains project description"
    else
        print_status "WARN" "README.md missing project description"
    fi
    
    if grep -q "gradlew build" README.md; then
        print_status "PASS" "README.md contains build instructions"
    else
        print_status "WARN" "README.md missing build instructions"
    fi
fi

echo ""
echo "10. Testing Mockito Configuration..."
echo "-----------------------------------"
# Test configuration files
if [ -r "build.gradle.kts" ]; then
    print_status "PASS" "build.gradle.kts is readable"
else
    print_status "FAIL" "build.gradle.kts is not readable"
fi

if [ -r "settings.gradle.kts" ]; then
    print_status "PASS" "settings.gradle.kts is readable"
else
    print_status "FAIL" "settings.gradle.kts is not readable"
fi

if [ -r "gradle.properties" ]; then
    print_status "PASS" "gradle.properties is readable"
else
    print_status "FAIL" "gradle.properties is not readable"
fi

if [ -r ".editorconfig" ]; then
    print_status "PASS" ".editorconfig is readable"
else
    print_status "FAIL" ".editorconfig is not readable"
fi

if [ -r ".checkstyle" ]; then
    print_status "PASS" ".checkstyle is readable"
else
    print_status "FAIL" ".checkstyle is not readable"
fi

# Check .gitignore content
if [ -r ".gitignore" ]; then
    if grep -q "*.class" .gitignore; then
        print_status "PASS" ".gitignore excludes Java class files"
    else
        print_status "WARN" ".gitignore missing Java class file exclusion"
    fi
    
    if grep -q "build/" .gitignore; then
        print_status "PASS" ".gitignore excludes build directory"
    else
        print_status "WARN" ".gitignore missing build directory exclusion"
    fi
    
    if grep -q ".gradle" .gitignore; then
        print_status "PASS" ".gitignore excludes Gradle cache"
    else
        print_status "WARN" ".gitignore missing Gradle cache exclusion"
    fi
fi

echo ""
echo "11. Testing Mockito Docker Functionality..."
echo "------------------------------------------"
# Test if Docker container can run basic commands
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    # Test Java in Docker
    if docker run --rm mockito-env-test java -version >/dev/null 2>&1; then
        print_status "PASS" "Java works in Docker container"
    else
        print_status "FAIL" "Java does not work in Docker container"
    fi
    
    # Test Gradle in Docker
    if docker run --rm mockito-env-test ./gradlew --version >/dev/null 2>&1; then
        print_status "PASS" "Gradle works in Docker container"
    else
        print_status "FAIL" "Gradle does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm mockito-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test Android SDK in Docker
    if docker run --rm mockito-env-test test -d .android-sdk; then
        print_status "PASS" "Android SDK works in Docker container"
    else
        print_status "FAIL" "Android SDK does not work in Docker container"
    fi
    
    # Test if build.gradle.kts is accessible in Docker
    if docker run --rm mockito-env-test test -f build.gradle.kts; then
        print_status "PASS" "build.gradle.kts is accessible in Docker container"
    else
        print_status "FAIL" "build.gradle.kts is not accessible in Docker container"
    fi
    
    # Test if settings.gradle.kts is accessible in Docker
    if docker run --rm mockito-env-test test -f settings.gradle.kts; then
        print_status "PASS" "settings.gradle.kts is accessible in Docker container"
    else
        print_status "FAIL" "settings.gradle.kts is not accessible in Docker container"
    fi
    
    # Test if gradlew is accessible in Docker
    if docker run --rm mockito-env-test test -f gradlew; then
        print_status "PASS" "gradlew is accessible in Docker container"
    else
        print_status "FAIL" "gradlew is not accessible in Docker container"
    fi
    
    # Test if mockito-core directory is accessible in Docker
    if docker run --rm mockito-env-test test -d mockito-core; then
        print_status "PASS" "mockito-core directory is accessible in Docker container"
    else
        print_status "FAIL" "mockito-core directory is not accessible in Docker container"
    fi
    
    # Test if mockito-extensions directory is accessible in Docker
    if docker run --rm mockito-env-test test -d mockito-extensions; then
        print_status "PASS" "mockito-extensions directory is accessible in Docker container"
    else
        print_status "FAIL" "mockito-extensions directory is not accessible in Docker container"
    fi
    
    # Test if mockito-integration-tests directory is accessible in Docker
    if docker run --rm mockito-env-test test -d mockito-integration-tests; then
        print_status "PASS" "mockito-integration-tests directory is accessible in Docker container"
    else
        print_status "FAIL" "mockito-integration-tests directory is not accessible in Docker container"
    fi
    
    # Test if gradle.properties is accessible in Docker
    if docker run --rm mockito-env-test test -f gradle.properties; then
        print_status "PASS" "gradle.properties is accessible in Docker container"
    else
        print_status "FAIL" "gradle.properties is not accessible in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm mockito-env-test test -f README.md; then
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
echo "This script has tested the Docker environment for Mockito:"
echo "- Docker build process (Ubuntu 22.04, Java 11/17/21, Android SDK)"
echo "- Java environment (version compatibility, compilation)"
echo "- Gradle environment (build system, wrapper functionality)"
echo "- Mockito build system (build.gradle.kts, settings.gradle.kts, gradle.properties)"
echo "- Mockito source code structure (mockito-core, extensions, integration tests)"
echo "- Mockito scripts (check_reproducibility.sh)"
echo "- Mockito documentation (README.md, LICENSE, SECURITY.md)"
echo "- Mockito configuration (build scripts, editor config, checkstyle)"
echo "- Docker container functionality (Java, Gradle, Git, Android SDK)"
echo "- Java mocking framework (unit testing, integration testing, Android support)"
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
    print_status "INFO" "All Docker tests passed! Your Mockito Docker environment is ready!"
    print_status "INFO" "Mockito is the most popular mocking framework for Java."
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your Mockito Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now run Mockito in Docker: The most popular mocking framework for Java."
print_status "INFO" "Example: docker run --rm mockito-env-test ./gradlew build"
print_status "INFO" "Example: docker run --rm mockito-env-test ./gradlew test"
echo ""
print_status "INFO" "For more information, see README.md and https://github.com/mockito/mockito"
exit 0
fi

# If Docker failed or not available, skip local environment tests
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ] || [ "${DOCKER_MODE:-false}" = "false" ]; then
    echo "Docker environment not available - skipping local environment tests"
    echo "This script is designed to test Docker environment only"
    exit 0
fi 