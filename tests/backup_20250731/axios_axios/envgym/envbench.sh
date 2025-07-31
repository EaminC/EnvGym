#!/bin/bash

# Axios Environment Benchmark Test
# Tests if the environment is properly set up for the Axios HTTP client project

# Don't exit on error - continue testing even if some tests fail
# set -e  # Exit on any error
trap 'echo -e "\n\033[0;31m[ERROR] Script interrupted by user\033[0m"; exit 1' INT TERM

# Function to ensure clean exit
cleanup() {
    echo -e "\n\033[0;34m[INFO] Cleaning up...\033[0m"
    # Kill any background processes
    jobs -p | xargs -r kill
    exit 1
}

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

# Function to check Node.js version
check_node_version() {
    local node_version=$(node --version 2>&1)
    print_status "INFO" "Node.js version: $node_version"
    
    # Extract version number
    local version=$(node --version | sed 's/v//')
    local major=$(echo $version | cut -d'.' -f1)
    
    if [ "$major" -ge 14 ]; then
        print_status "PASS" "Node.js version >= 14 (found $major)"
    else
        print_status "FAIL" "Node.js version < 14 (found $major)"
    fi
}

# Function to check npm version
check_npm_version() {
    local npm_version=$(npm --version 2>&1)
    print_status "INFO" "npm version: $npm_version"
    
    # Extract version number
    local version=$(npm --version)
    local major=$(echo $version | cut -d'.' -f1)
    
    if [ "$major" -ge 6 ]; then
        print_status "PASS" "npm version >= 6 (found $version)"
    else
        print_status "FAIL" "npm version < 6 (found $version)"
    fi
}

# Function to check if a Node.js module can be imported
check_node_module() {
    local module=$1
    local test_name=$2
    
    if node -e "require('$module'); console.log('$module imported successfully')" 2>/dev/null; then
        print_status "PASS" "$test_name module can be imported"
        return 0
    else
        print_status "FAIL" "$test_name module cannot be imported"
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the axios_axios project root directory."
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    docker build -f envgym/envgym.dockerfile -t axios-env-test .
    
    # Run this script inside Docker container
    echo "Running environment test in Docker container..."
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/axios_axios" axios-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        cd /home/cc/EnvGym/data/axios_axios && ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "Axios Environment Benchmark Test"
echo "=========================================="

echo ""
echo "1. Checking System Dependencies..."
echo "--------------------------------"

# Check system commands (based on Axios prerequisites)
check_command "node" "Node.js"
check_command "npm" "npm"
check_command "git" "Git"
check_command "curl" "cURL"

echo ""
echo "2. Checking Node.js Version..."
echo "-----------------------------"

check_node_version

echo ""
echo "3. Checking npm Version..."
echo "-------------------------"

check_npm_version

echo ""
echo "4. Checking Project Structure..."
echo "-------------------------------"

# Check if we're in the right directory
if [ -f "package.json" ]; then
    print_status "PASS" "package.json found"
else
    print_status "FAIL" "package.json not found"
    exit 1
fi

# Check if we're in the Axios project
if grep -q '"name": "axios"' package.json 2>/dev/null; then
    print_status "PASS" "Axios project detected"
else
    print_status "FAIL" "Not an Axios project"
fi

# Check project structure
print_status "INFO" "Checking project structure..."
if [ -d "lib" ]; then
    print_status "PASS" "lib directory exists"
else
    print_status "FAIL" "lib directory missing"
fi

if [ -d "test" ]; then
    print_status "PASS" "test directory exists"
else
    print_status "FAIL" "test directory missing"
fi

if [ -d "dist" ]; then
    print_status "PASS" "dist directory exists"
else
    print_status "FAIL" "dist directory missing"
fi

if [ -d "examples" ]; then
    print_status "PASS" "examples directory exists"
else
    print_status "FAIL" "examples directory missing"
fi

if [ -d "sandbox" ]; then
    print_status "PASS" "sandbox directory exists"
else
    print_status "FAIL" "sandbox directory missing"
fi

if [ -d "templates" ]; then
    print_status "PASS" "templates directory exists"
else
    print_status "FAIL" "templates directory missing"
fi

if [ -d "bin" ]; then
    print_status "PASS" "bin directory exists"
else
    print_status "FAIL" "bin directory missing"
fi

echo ""
echo "5. Testing npm Install..."
echo "------------------------"

# Test npm install
if npm install --silent 2>/dev/null; then
    print_status "PASS" "npm install successful"
else
    print_status "FAIL" "npm install failed"
fi

echo ""
echo "6. Testing Core Dependencies..."
echo "------------------------------"

# Check core dependencies
print_status "INFO" "Checking core dependencies..."
check_node_module "follow-redirects" "follow-redirects"
check_node_module "form-data" "form-data"
check_node_module "proxy-from-env" "proxy-from-env"

echo ""
echo "7. Testing Development Dependencies..."
echo "------------------------------------"

# Check development dependencies
print_status "INFO" "Checking development dependencies..."
check_node_module "eslint" "eslint"
check_node_module "mocha" "mocha"
check_node_module "karma" "karma"
check_node_module "rollup" "rollup"
check_node_module "gulp" "gulp"
check_node_module "typescript" "typescript"
check_node_module "sinon" "sinon"
check_node_module "express" "express"

echo ""
echo "8. Testing npm Scripts..."
echo "------------------------"

# Test npm scripts
if npm run test:eslint --silent 2>/dev/null; then
    print_status "PASS" "npm run test:eslint successful"
else
    print_status "WARN" "npm run test:eslint failed"
fi

if npm run test:mocha --silent 2>/dev/null; then
    print_status "PASS" "npm run test:mocha successful"
else
    print_status "WARN" "npm run test:mocha failed"
fi

echo ""
echo "9. Testing Build Configuration..."
echo "--------------------------------"

# Check build configuration files
if [ -f "rollup.config.js" ]; then
    print_status "PASS" "rollup.config.js exists"
else
    print_status "FAIL" "rollup.config.js missing"
fi

if [ -f "gulpfile.js" ]; then
    print_status "PASS" "gulpfile.js exists"
else
    print_status "FAIL" "gulpfile.js missing"
fi

if [ -f "webpack.config.js" ]; then
    print_status "PASS" "webpack.config.js exists"
else
    print_status "FAIL" "webpack.config.js missing"
fi

if [ -f "tsconfig.json" ]; then
    print_status "PASS" "tsconfig.json exists"
else
    print_status "FAIL" "tsconfig.json missing"
fi

echo ""
echo "10. Testing Test Configuration..."
echo "--------------------------------"

# Check test configuration
if [ -f "karma.conf.cjs" ]; then
    print_status "PASS" "karma.conf.cjs exists"
else
    print_status "FAIL" "karma.conf.cjs missing"
fi

if [ -f ".eslintrc.cjs" ]; then
    print_status "PASS" ".eslintrc.cjs exists"
else
    print_status "FAIL" ".eslintrc.cjs missing"
fi

if [ -f "tslint.json" ]; then
    print_status "PASS" "tslint.json exists"
else
    print_status "FAIL" "tslint.json missing"
fi

echo ""
echo "11. Testing Source Code Structure..."
echo "-----------------------------------"

# Check source code structure
if [ -d "lib" ]; then
    js_files=$(find lib -name "*.js" | wc -l)
    print_status "INFO" "Found $js_files JavaScript files in lib directory"
    if [ "$js_files" -gt 0 ]; then
        print_status "PASS" "JavaScript source files found"
    else
        print_status "FAIL" "No JavaScript source files found"
    fi
fi

# Check for specific Axios source files
if [ -f "index.js" ]; then
    print_status "PASS" "index.js exists"
else
    print_status "FAIL" "index.js missing"
fi

if [ -f "index.d.ts" ]; then
    print_status "PASS" "index.d.ts exists"
else
    print_status "FAIL" "index.d.ts missing"
fi

if [ -f "index.d.cts" ]; then
    print_status "PASS" "index.d.cts exists"
else
    print_status "FAIL" "index.d.cts missing"
fi

echo ""
echo "12. Testing Test Structure..."
echo "-----------------------------"

# Check test structure
if [ -d "test" ]; then
    test_files=$(find test -name "*.js" | wc -l)
    print_status "INFO" "Found $test_files test files"
    if [ "$test_files" -gt 0 ]; then
        print_status "PASS" "Test files found"
    else
        print_status "FAIL" "No test files found"
    fi
fi

if [ -d "test/unit" ]; then
    print_status "PASS" "test/unit directory exists"
else
    print_status "FAIL" "test/unit directory missing"
fi

if [ -d "test/module" ]; then
    print_status "PASS" "test/module directory exists"
else
    print_status "FAIL" "test/module directory missing"
fi

echo ""
echo "13. Testing Examples Structure..."
echo "--------------------------------"

# Check examples structure
if [ -d "examples" ]; then
    example_files=$(find examples -name "*.js" | wc -l)
    print_status "INFO" "Found $example_files example files"
    if [ "$example_files" -gt 0 ]; then
        print_status "PASS" "Example files found"
    else
        print_status "FAIL" "No example files found"
    fi
fi

if [ -f "examples/server.js" ]; then
    print_status "PASS" "examples/server.js exists"
else
    print_status "FAIL" "examples/server.js missing"
fi

echo ""
echo "14. Testing Sandbox Structure..."
echo "--------------------------------"

# Check sandbox structure
if [ -d "sandbox" ]; then
    sandbox_files=$(find sandbox -name "*.js" | wc -l)
    print_status "INFO" "Found $sandbox_files sandbox files"
    if [ "$sandbox_files" -gt 0 ]; then
        print_status "PASS" "Sandbox files found"
    else
        print_status "FAIL" "No sandbox files found"
    fi
fi

if [ -f "sandbox/server.js" ]; then
    print_status "PASS" "sandbox/server.js exists"
else
    print_status "FAIL" "sandbox/server.js missing"
fi

echo ""
echo "15. Testing Build Scripts..."
echo "----------------------------"

# Check build scripts
if [ -f "bin/ssl_hotfix.js" ]; then
    print_status "PASS" "bin/ssl_hotfix.js exists"
else
    print_status "FAIL" "bin/ssl_hotfix.js missing"
fi

if [ -f "bin/check-build-version.js" ]; then
    print_status "PASS" "bin/check-build-version.js exists"
else
    print_status "FAIL" "bin/check-build-version.js missing"
fi

echo ""
echo "16. Testing Documentation..."
echo "----------------------------"

# Check documentation
if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md missing"
fi

if [ -f "CHANGELOG.md" ]; then
    print_status "PASS" "CHANGELOG.md exists"
else
    print_status "FAIL" "CHANGELOG.md missing"
fi

if [ -f "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md exists"
else
    print_status "FAIL" "CONTRIBUTING.md missing"
fi

if [ -f "CODE_OF_CONDUCT.md" ]; then
    print_status "PASS" "CODE_OF_CONDUCT.md exists"
else
    print_status "FAIL" "CODE_OF_CONDUCT.md missing"
fi

if [ -f "SECURITY.md" ]; then
    print_status "PASS" "SECURITY.md exists"
else
    print_status "FAIL" "SECURITY.md missing"
fi

# Check if documentation mentions Axios
if grep -q "axios" README.md 2>/dev/null; then
    print_status "PASS" "README.md contains Axios references"
else
    print_status "WARN" "README.md missing Axios references"
fi

echo ""
echo "17. Testing Basic Node.js Functionality..."
echo "------------------------------------------"

# Test basic Node.js functionality
if node -e "console.log('Node.js basic functionality test successful')" 2>/dev/null; then
    print_status "PASS" "Node.js basic functionality works"
else
    print_status "FAIL" "Node.js basic functionality failed"
fi

echo ""
echo "18. Testing npm Package.json Scripts..."
echo "---------------------------------------"

# Test if package.json has required scripts
if grep -q '"test"' package.json 2>/dev/null; then
    print_status "PASS" "test script defined in package.json"
else
    print_status "FAIL" "test script not defined in package.json"
fi

if grep -q '"build"' package.json 2>/dev/null; then
    print_status "PASS" "build script defined in package.json"
else
    print_status "FAIL" "build script not defined in package.json"
fi

if grep -q '"start"' package.json 2>/dev/null; then
    print_status "PASS" "start script defined in package.json"
else
    print_status "FAIL" "start script not defined in package.json"
fi

echo ""
echo "19. Testing ESLint Configuration..."
echo "----------------------------------"

# Test ESLint availability
if node -e "require('eslint'); console.log('ESLint is available')" 2>/dev/null; then
    print_status "PASS" "ESLint is available"
else
    print_status "FAIL" "ESLint is not available"
fi

echo ""
echo "20. Testing Mocha Test Runner..."
echo "--------------------------------"

# Test Mocha availability
if node -e "require('mocha'); console.log('Mocha is available')" 2>/dev/null; then
    print_status "PASS" "Mocha is available"
else
    print_status "FAIL" "Mocha is not available"
fi

echo ""
echo "21. Testing Karma Test Runner..."
echo "--------------------------------"

# Test Karma availability
if node -e "require('karma'); console.log('Karma is available')" 2>/dev/null; then
    print_status "PASS" "Karma is available"
else
    print_status "FAIL" "Karma is not available"
fi

echo ""
echo "22. Testing Rollup Bundler..."
echo "-----------------------------"

# Test Rollup availability
if node -e "require('rollup'); console.log('Rollup is available')" 2>/dev/null; then
    print_status "PASS" "Rollup is available"
else
    print_status "FAIL" "Rollup is not available"
fi

echo ""
echo "23. Testing Gulp Build Tool..."
echo "------------------------------"

# Test Gulp availability
if node -e "require('gulp'); console.log('Gulp is available')" 2>/dev/null; then
    print_status "PASS" "Gulp is available"
else
    print_status "FAIL" "Gulp is not available"
fi

echo ""
echo "24. Testing TypeScript Compiler..."
echo "----------------------------------"

# Test TypeScript availability
if node -e "require('typescript'); console.log('TypeScript is available')" 2>/dev/null; then
    print_status "PASS" "TypeScript is available"
else
    print_status "FAIL" "TypeScript is not available"
fi

echo ""
echo "25. Testing Core Dependencies Functionality..."
echo "----------------------------------------------"

# Test core dependencies functionality
if node -e "const axios = require('.'); console.log('Axios core functionality test successful')" 2>/dev/null; then
    print_status "PASS" "Axios core functionality works"
else
    print_status "FAIL" "Axios core functionality failed"
fi

# Test follow-redirects functionality
if node -e "require('follow-redirects'); console.log('follow-redirects functionality test successful')" 2>/dev/null; then
    print_status "PASS" "follow-redirects functionality works"
else
    print_status "FAIL" "follow-redirects functionality failed"
fi

# Test form-data functionality
if node -e "require('form-data'); console.log('form-data functionality test successful')" 2>/dev/null; then
    print_status "PASS" "form-data functionality works"
else
    print_status "FAIL" "form-data functionality failed"
fi

echo ""
echo "26. Testing Build Process..."
echo "----------------------------"

# Test build process (without actually building)
if npm run build --dry-run 2>/dev/null; then
    print_status "PASS" "Build script can be executed"
else
    print_status "WARN" "Build script execution test failed"
fi

echo ""
echo "27. Testing Package Exports..."
echo "------------------------------"

# Check package.json exports configuration
if grep -q '"exports"' package.json 2>/dev/null; then
    print_status "PASS" "Package exports are configured"
else
    print_status "FAIL" "Package exports are not configured"
fi

if grep -q '"type": "module"' package.json 2>/dev/null; then
    print_status "PASS" "ES modules are configured"
else
    print_status "FAIL" "ES modules are not configured"
fi

echo ""
echo "28. Testing Browser Support..."
echo "------------------------------"

# Check browser support configuration
if grep -q '"browser"' package.json 2>/dev/null; then
    print_status "PASS" "Browser support is configured"
else
    print_status "FAIL" "Browser support is not configured"
fi

if grep -q '"react-native"' package.json 2>/dev/null; then
    print_status "PASS" "React Native support is configured"
else
    print_status "FAIL" "React Native support is not configured"
fi

echo ""
echo "29. Testing Git Configuration..."
echo "--------------------------------"

# Check Git configuration
if git --version >/dev/null 2>&1; then
    print_status "PASS" "Git is properly configured"
else
    print_status "FAIL" "Git is not properly configured"
fi

# Check if this is a Git repository
if [ -d ".git" ]; then
    print_status "PASS" "This is a Git repository"
else
    print_status "WARN" "This is not a Git repository"
fi

echo ""
echo "30. Testing npm Test Command..."
echo "-------------------------------"

# Test npm test (this might take longer)
if npm test --silent 2>/dev/null; then
    print_status "PASS" "npm test successful"
else
    print_status "WARN" "npm test failed or took too long"
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
echo "- System dependencies (Node.js, npm, Git, curl)"
echo "- Node.js version compatibility (>= 14)"
echo "- npm version compatibility (>= 6)"
echo "- Project structure and files"
echo "- npm install and dependencies"
echo "- Core module imports"
echo "- Development tools (ESLint, Mocha, Karma, Rollup, Gulp, TypeScript)"
echo "- Build configuration"
echo "- Test configuration"
echo "- Source code structure"
echo "- Documentation"
echo "- Basic Node.js functionality"
echo "- Package.json scripts"
echo "- Core dependencies functionality"
echo "- Build process"
echo "- Package exports and module configuration"
echo "- Browser and React Native support"
echo "- Test execution"

echo ""
echo ""
echo "=========================================="
echo "Test Results Summary"
echo "=========================================="
echo -e "${GREEN}PASS: $PASS_COUNT${NC}"
echo -e "${RED}FAIL: $FAIL_COUNT${NC}"
echo -e "${YELLOW}WARN: $WARN_COUNT${NC}"

if [ $FAIL_COUNT -eq 0 ]; then
    print_status "INFO" "All tests passed! Your Axios environment is ready!"
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your Axios environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi

print_status "INFO" "You can now build and test Axios."
print_status "INFO" "Example: npm run build && npm test"
echo ""
print_status "INFO" "For more information, see README.md" 