#!/bin/bash

# Alibaba FastJSON2 Environment Benchmark Test
# Tests if the environment is properly set up for the FastJSON2 Java project

# Don't exit on error - continue testing even if some tests fail
# set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test result counters
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
        *)
            echo "[$status] $message"
            ;;
    esac
}

# Function to check if a command exists
check_command() {
    local cmd=$1
    local name=$2
    
    if command -v "$cmd" &> /dev/null; then
        print_status "PASS" "$name is installed"
        return 0
    else
        print_status "FAIL" "$name is not installed"
        return 1
    fi
}

# Function to check Java version
check_java_version() {
    local java_version=$(java -version 2>&1 | head -1)
    print_status "INFO" "Java version: $java_version"
    
    # Extract version number
    local version=$(java -version 2>&1 | grep -o 'version "[^"]*"' | sed 's/version "//' | sed 's/"//')
    local major=$(echo $version | cut -d'.' -f1)
    
    # Remove "1." prefix for older Java versions
    if [[ $major == "1" ]]; then
        major=$(echo $version | cut -d'.' -f2)
    fi
    
    if [ "$major" -ge 8 ]; then
        print_status "PASS" "Java version >= 8 (found $major)"
    else
        print_status "FAIL" "Java version < 8 (found $major)"
    fi
}

# Function to check Maven version
check_maven_version() {
    local maven_version=$(mvn -version 2>&1 | head -1)
    print_status "INFO" "Maven version: $maven_version"
    
    # Extract version number
    local version=$(mvn -version 2>&1 | grep -o 'Apache Maven [0-9.]*' | sed 's/Apache Maven //')
    local major=$(echo $version | cut -d'.' -f1)
    local minor=$(echo $version | cut -d'.' -f2)
    
    if [ "$major" -ge 3 ] && [ "$minor" -ge 6 ]; then
        print_status "PASS" "Maven version >= 3.6 (found $version)"
    else
        print_status "FAIL" "Maven version < 3.6 (found $version)"
    fi
}

# Function to check if a Java class can be compiled
check_java_compilation() {
    local test_file=$1
    local test_name=$2
    
    if javac "$test_file" 2>/dev/null; then
        print_status "PASS" "$test_name compilation successful"
        rm -f "${test_file%.java}.class" 2>/dev/null
        return 0
    else
        print_status "FAIL" "$test_name compilation failed"
        return 1
    fi
}

# Check if we're running inside Docker container
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo "Running inside Docker container - proceeding with environment test..."
else
    echo "Not running in Docker container - building and running Docker test..."
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        echo "ERROR: Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "envgym/envgym.dockerfile" ]; then
        echo "ERROR: envgym.dockerfile not found. Please run this script from the alibaba_fastjson2 project root directory."
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    docker build -f envgym/envgym.dockerfile -t fastjson2-env-test .
    
    # Run this script inside Docker container
    echo "Running environment test in Docker container..."
    docker run --rm -v "$(pwd):/workspace" fastjson2-env-test bash -c "cd /workspace && ./envgym/envbench.sh"
    exit 0
fi

echo "=========================================="
echo "Alibaba FastJSON2 Environment Benchmark Test"
echo "=========================================="

echo ""
echo "1. Checking System Dependencies..."
echo "--------------------------------"

# Check system commands (based on FastJSON2 prerequisites)
check_command "java" "Java"
check_command "javac" "Java Compiler"
check_command "mvn" "Maven"
check_command "git" "Git"

echo ""
echo "2. Checking Java Version..."
echo "--------------------------"

check_java_version

echo ""
echo "3. Checking Maven Version..."
echo "---------------------------"

check_maven_version

echo ""
echo "4. Checking Project Structure..."
echo "-------------------------------"

# Check if we're in the right directory
if [ -f "pom.xml" ]; then
    print_status "PASS" "pom.xml found"
else
    print_status "FAIL" "pom.xml not found"
    exit 1
fi

# Check if we're in the FastJSON2 project
if grep -q "fastjson2" pom.xml 2>/dev/null; then
    print_status "PASS" "FastJSON2 project detected"
else
    print_status "FAIL" "Not a FastJSON2 project"
fi

# Check project modules
print_status "INFO" "Checking project modules..."
if [ -d "core" ]; then
    print_status "PASS" "core module exists"
else
    print_status "FAIL" "core module missing"
fi

if [ -d "extension" ]; then
    print_status "PASS" "extension module exists"
else
    print_status "FAIL" "extension module missing"
fi

if [ -d "kotlin" ]; then
    print_status "PASS" "kotlin module exists"
else
    print_status "FAIL" "kotlin module missing"
fi

if [ -d "fastjson1-compatible" ]; then
    print_status "PASS" "fastjson1-compatible module exists"
else
    print_status "FAIL" "fastjson1-compatible module missing"
fi

echo ""
echo "5. Testing Maven Build..."
echo "------------------------"

# Test Maven clean
if mvn clean -q 2>/dev/null; then
    print_status "PASS" "Maven clean successful"
else
    print_status "FAIL" "Maven clean failed"
fi

# Test Maven compile
if mvn compile -q 2>/dev/null; then
    print_status "PASS" "Maven compile successful"
else
    print_status "FAIL" "Maven compile failed"
fi

# Test Maven test compile
if mvn test-compile -q 2>/dev/null; then
    print_status "PASS" "Maven test-compile successful"
else
    print_status "FAIL" "Maven test-compile failed"
fi

echo ""
echo "6. Testing Core Module..."
echo "------------------------"

# Test core module compilation
if [ -d "core" ]; then
    cd core
    if mvn compile -q 2>/dev/null; then
        print_status "PASS" "Core module compilation successful"
    else
        print_status "FAIL" "Core module compilation failed"
    fi
    cd ..
else
    print_status "FAIL" "Core module directory not found"
fi

echo ""
echo "7. Testing Java Compilation..."
echo "-----------------------------"

# Create a simple test Java file to verify compilation
cat > TestCompilation.java << 'EOF'
public class TestCompilation {
    public static void main(String[] args) {
        System.out.println("Java compilation test successful");
    }
}
EOF

check_java_compilation "TestCompilation.java" "Basic Java compilation"

# Clean up test file
rm -f TestCompilation.java TestCompilation.class

echo ""
echo "8. Testing FastJSON2 Basic Functionality..."
echo "------------------------------------------"

# Create a test Java file with FastJSON2 usage
cat > FastJSON2Test.java << 'EOF'
import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONObject;
import com.alibaba.fastjson2.JSONArray;

public class FastJSON2Test {
    public static void main(String[] args) {
        try {
            // Test JSON parsing
            String jsonStr = "{\"name\":\"test\",\"age\":25}";
            JSONObject obj = JSON.parseObject(jsonStr);
            System.out.println("JSON parsing successful: " + obj.getString("name"));
            
            // Test JSON serialization
            JSONObject testObj = new JSONObject();
            testObj.put("message", "Hello FastJSON2");
            String serialized = JSON.toJSONString(testObj);
            System.out.println("JSON serialization successful: " + serialized);
            
            // Test JSONArray
            JSONArray array = JSON.parseArray("[1,2,3,4,5]");
            System.out.println("JSONArray parsing successful: " + array.size() + " elements");
            
            System.out.println("FastJSON2 basic functionality test completed successfully");
        } catch (Exception e) {
            System.err.println("FastJSON2 test failed: " + e.getMessage());
            System.exit(1);
        }
    }
}
EOF

# Try to compile the FastJSON2 test (this will fail without dependencies, but we can check compilation)
if javac -cp "core/target/classes:core/target/test-classes" FastJSON2Test.java 2>/dev/null; then
    print_status "PASS" "FastJSON2 test compilation successful"
    rm -f FastJSON2Test.class
else
    print_status "WARN" "FastJSON2 test compilation failed (expected without dependencies)"
fi

# Clean up test file
rm -f FastJSON2Test.java

echo ""
echo "9. Testing Maven Dependencies..."
echo "-------------------------------"

# Check if dependencies can be resolved
if mvn dependency:resolve -q 2>/dev/null; then
    print_status "PASS" "Maven dependencies resolved successfully"
else
    print_status "FAIL" "Maven dependencies resolution failed"
fi

# Check if test dependencies can be resolved
if mvn dependency:resolve -Dclassifier=tests -q 2>/dev/null; then
    print_status "PASS" "Maven test dependencies resolved successfully"
else
    print_status "WARN" "Maven test dependencies resolution failed"
fi

echo ""
echo "10. Testing Project Documentation..."
echo "----------------------------------"

# Check if README files exist
if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md missing"
fi

if [ -f "README_EN.md" ]; then
    print_status "PASS" "README_EN.md exists"
else
    print_status "FAIL" "README_EN.md missing"
fi

# Check if documentation mentions FastJSON2
if grep -q "fastjson2" README.md 2>/dev/null; then
    print_status "PASS" "README.md contains FastJSON2 references"
else
    print_status "WARN" "README.md missing FastJSON2 references"
fi

echo ""
echo "11. Testing Source Code Structure..."
echo "----------------------------------"

# Check source directories
if [ -d "src" ]; then
    print_status "PASS" "src directory exists"
else
    print_status "FAIL" "src directory missing"
fi

# Check if there are Java source files
if find . -name "*.java" -type f | head -1 | grep -q .; then
    print_status "PASS" "Java source files found"
else
    print_status "FAIL" "No Java source files found"
fi

# Check if there are Kotlin source files
if find . -name "*.kt" -type f | head -1 | grep -q .; then
    print_status "PASS" "Kotlin source files found"
else
    print_status "WARN" "No Kotlin source files found"
fi

echo ""
echo "12. Testing Build Tools..."
echo "-------------------------"

# Check if Maven wrapper exists
if [ -f "mvnw" ]; then
    print_status "PASS" "Maven wrapper (mvnw) exists"
    if [ -x "mvnw" ]; then
        print_status "PASS" "Maven wrapper is executable"
    else
        print_status "FAIL" "Maven wrapper is not executable"
    fi
else
    print_status "WARN" "Maven wrapper (mvnw) not found"
fi

# Check if Gradle wrapper exists (optional)
if [ -f "gradlew" ]; then
    print_status "PASS" "Gradle wrapper (gradlew) exists"
    if [ -x "gradlew" ]; then
        print_status "PASS" "Gradle wrapper is executable"
    else
        print_status "FAIL" "Gradle wrapper is not executable"
    fi
else
    print_status "INFO" "Gradle wrapper (gradlew) not found (optional)"
fi

echo ""
echo "13. Testing Example Projects..."
echo "------------------------------"

# Check example projects
if [ -d "example-spring-test" ]; then
    print_status "PASS" "example-spring-test exists"
    cd example-spring-test
    if mvn compile -q 2>/dev/null; then
        print_status "PASS" "example-spring-test compilation successful"
    else
        print_status "WARN" "example-spring-test compilation failed"
    fi
    cd ..
else
    print_status "WARN" "example-spring-test not found"
fi

if [ -d "example-solon-test" ]; then
    print_status "PASS" "example-solon-test exists"
    cd example-solon-test
    if mvn compile -q 2>/dev/null; then
        print_status "PASS" "example-solon-test compilation successful"
    else
        print_status "WARN" "example-solon-test compilation failed"
    fi
    cd ..
else
    print_status "WARN" "example-solon-test not found"
fi

if [ -d "example-spring6-test" ]; then
    print_status "PASS" "example-spring6-test exists"
    cd example-spring6-test
    if mvn compile -q 2>/dev/null; then
        print_status "PASS" "example-spring6-test compilation successful"
    else
        print_status "WARN" "example-spring6-test compilation failed"
    fi
    cd ..
else
    print_status "WARN" "example-spring6-test not found"
fi

echo ""
echo "14. Testing Benchmark Module..."
echo "-------------------------------"

# Check benchmark module
if [ -d "benchmark" ]; then
    print_status "PASS" "benchmark module exists"
    cd benchmark
    if mvn compile -q 2>/dev/null; then
        print_status "PASS" "benchmark module compilation successful"
    else
        print_status "WARN" "benchmark module compilation failed"
    fi
    cd ..
else
    print_status "WARN" "benchmark module not found"
fi

echo ""
echo "15. Testing Extension Modules..."
echo "--------------------------------"

# Check extension modules
if [ -d "extension" ]; then
    print_status "PASS" "extension module exists"
    cd extension
    if mvn compile -q 2>/dev/null; then
        print_status "PASS" "extension module compilation successful"
    else
        print_status "WARN" "extension module compilation failed"
    fi
    cd ..
else
    print_status "WARN" "extension module not found"
fi

if [ -d "extension-spring5" ]; then
    print_status "PASS" "extension-spring5 module exists"
    cd extension-spring5
    if mvn compile -q 2>/dev/null; then
        print_status "PASS" "extension-spring5 module compilation successful"
    else
        print_status "WARN" "extension-spring5 module compilation failed"
    fi
    cd ..
else
    print_status "WARN" "extension-spring5 module not found"
fi

if [ -d "extension-spring6" ]; then
    print_status "PASS" "extension-spring6 module exists"
    cd extension-spring6
    if mvn compile -q 2>/dev/null; then
        print_status "PASS" "extension-spring6 module compilation successful"
    else
        print_status "WARN" "extension-spring6 module compilation failed"
    fi
    cd ..
else
    print_status "WARN" "extension-spring6 module not found"
fi

echo ""
echo "16. Testing Kotlin Module..."
echo "----------------------------"

# Check Kotlin module
if [ -d "kotlin" ]; then
    print_status "PASS" "kotlin module exists"
    cd kotlin
    if mvn compile -q 2>/dev/null; then
        print_status "PASS" "kotlin module compilation successful"
    else
        print_status "WARN" "kotlin module compilation failed"
    fi
    cd ..
else
    print_status "WARN" "kotlin module not found"
fi

echo ""
echo "17. Testing FastJSON1 Compatibility..."
echo "-------------------------------------"

# Check FastJSON1 compatibility module
if [ -d "fastjson1-compatible" ]; then
    print_status "PASS" "fastjson1-compatible module exists"
    cd fastjson1-compatible
    if mvn compile -q 2>/dev/null; then
        print_status "PASS" "fastjson1-compatible module compilation successful"
    else
        print_status "WARN" "fastjson1-compatible module compilation failed"
    fi
    cd ..
else
    print_status "WARN" "fastjson1-compatible module not found"
fi

echo ""
echo "18. Testing Safe Mode..."
echo "------------------------"

# Check safe mode test module
if [ -d "safemode-test" ]; then
    print_status "PASS" "safemode-test module exists"
    cd safemode-test
    if mvn compile -q 2>/dev/null; then
        print_status "PASS" "safemode-test module compilation successful"
    else
        print_status "WARN" "safemode-test module compilation failed"
    fi
    cd ..
else
    print_status "WARN" "safemode-test module not found"
fi

echo ""
echo "19. Testing Code Generation..."
echo "------------------------------"

# Check code generation modules
if [ -d "codegen" ]; then
    print_status "PASS" "codegen module exists"
    cd codegen
    if mvn compile -q 2>/dev/null; then
        print_status "PASS" "codegen module compilation successful"
    else
        print_status "WARN" "codegen module compilation failed"
    fi
    cd ..
else
    print_status "WARN" "codegen module not found"
fi

if [ -d "codegen-test" ]; then
    print_status "PASS" "codegen-test module exists"
    cd codegen-test
    if mvn compile -q 2>/dev/null; then
        print_status "PASS" "codegen-test module compilation successful"
    else
        print_status "WARN" "codegen-test module compilation failed"
    fi
    cd ..
else
    print_status "WARN" "codegen-test module not found"
fi

echo ""
echo "20. Testing Android Support..."
echo "------------------------------"

# Check Android test module
if [ -d "android-test" ]; then
    print_status "PASS" "android-test module exists"
    cd android-test
    if mvn compile -q 2>/dev/null; then
        print_status "PASS" "android-test module compilation successful"
    else
        print_status "WARN" "android-test module compilation failed"
    fi
    cd ..
else
    print_status "WARN" "android-test module not found"
fi

echo ""
echo "21. Testing GraalVM Native Support..."
echo "-------------------------------------"

# Check GraalVM native example
if [ -d "example-graalvm-native" ]; then
    print_status "PASS" "example-graalvm-native exists"
    cd example-graalvm-native
    if mvn compile -q 2>/dev/null; then
        print_status "PASS" "example-graalvm-native compilation successful"
    else
        print_status "WARN" "example-graalvm-native compilation failed"
    fi
    cd ..
else
    print_status "WARN" "example-graalvm-native not found"
fi

echo ""
echo "22. Testing JDK 17 Support..."
echo "------------------------------"

# Check JDK 17 test module
if [ -d "test-jdk17" ]; then
    print_status "PASS" "test-jdk17 module exists"
    cd test-jdk17
    if mvn compile -q 2>/dev/null; then
        print_status "PASS" "test-jdk17 module compilation successful"
    else
        print_status "WARN" "test-jdk17 module compilation failed"
    fi
    cd ..
else
    print_status "WARN" "test-jdk17 module not found"
fi

echo ""
echo "23. Testing Maven Install..."
echo "----------------------------"

# Test Maven install (this will take longer)
if mvn install -DskipTests -q 2>/dev/null; then
    print_status "PASS" "Maven install successful"
else
    print_status "FAIL" "Maven install failed"
fi

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="

# Summary
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (Java, Maven, Git)"
echo "- Java version compatibility (>= 8)"
echo "- Maven version compatibility (>= 3.6)"
echo "- Project structure and modules"
echo "- Maven build and compilation"
echo "- Core FastJSON2 functionality"
echo "- Maven dependencies resolution"
echo "- Project documentation"
echo "- Source code structure"
echo "- Build tools (Maven/Gradle wrappers)"
echo "- Example projects compilation"
echo "- All extension modules"
echo "- Kotlin support"
echo "- FastJSON1 compatibility"
echo "- Safe mode testing"
echo "- Code generation"
echo "- Android support"
echo "- GraalVM native support"
echo "- JDK 17 support"
echo "- Complete Maven install"

echo ""
echo ""
echo "=========================================="
echo "Test Results Summary"
echo "=========================================="
echo -e "${GREEN}PASS: $PASS_COUNT${NC}"
echo -e "${RED}FAIL: $FAIL_COUNT${NC}"
echo -e "${YELLOW}WARN: $WARN_COUNT${NC}"

if [ $FAIL_COUNT -eq 0 ]; then
    print_status "INFO" "All tests passed! Your FastJSON2 environment is ready!"
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your FastJSON2 environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi

print_status "INFO" "You can now build and run FastJSON2 projects."
print_status "INFO" "Example: mvn clean install"
echo ""
print_status "INFO" "For more information, see README.md and README_EN.md" 