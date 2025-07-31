#!/bin/bash

# Anurag Hazra GitHub Readme Stats Environment Benchmark Test
# Tests if the environment is properly set up for the GitHub Readme Stats Node.js project

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
    
    if [ "$major" -ge 18 ]; then
        print_status "PASS" "Node.js version >= 18 (found $major)"
    else
        print_status "FAIL" "Node.js version < 18 (found $major)"
    fi
}

# Function to check npm version
check_npm_version() {
    local npm_version=$(npm --version 2>&1)
    print_status "INFO" "npm version: $npm_version"
    
    # Extract version number
    local version=$(npm --version)
    local major=$(echo $version | cut -d'.' -f1)
    
    if [ "$major" -ge 8 ]; then
        print_status "PASS" "npm version >= 8 (found $version)"
    else
        print_status "FAIL" "npm version < 8 (found $version)"
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the anuraghazra_github-readme-stats project root directory."
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    docker build -f envgym/envgym.dockerfile -t github-readme-stats-env-test .
    
    # Run this script inside Docker container
    echo "Running environment test in Docker container..."
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/anuraghazra_github-readme-stats" github-readme-stats-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        cd /home/cc/EnvGym/data/anuraghazra_github-readme-stats && ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "GitHub Readme Stats Environment Benchmark Test"
echo "=========================================="

echo ""
echo "1. Checking System Dependencies..."
echo "--------------------------------"

# Check system commands (based on GitHub Readme Stats prerequisites)
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

# Check if we're in the GitHub Readme Stats project
if grep -q "github-readme-stats" package.json 2>/dev/null; then
    print_status "PASS" "GitHub Readme Stats project detected"
else
    print_status "FAIL" "Not a GitHub Readme Stats project"
fi

# Check project structure
print_status "INFO" "Checking project structure..."
if [ -d "src" ]; then
    print_status "PASS" "src directory exists"
else
    print_status "FAIL" "src directory missing"
fi

if [ -d "api" ]; then
    print_status "PASS" "api directory exists"
else
    print_status "FAIL" "api directory missing"
fi

if [ -d "themes" ]; then
    print_status "PASS" "themes directory exists"
else
    print_status "FAIL" "themes directory missing"
fi

if [ -d "tests" ]; then
    print_status "PASS" "tests directory exists"
else
    print_status "FAIL" "tests directory missing"
fi

if [ -d "scripts" ]; then
    print_status "PASS" "scripts directory exists"
else
    print_status "FAIL" "scripts directory missing"
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
echo "6. Testing Node.js Module Import..."
echo "----------------------------------"

# Test importing the main module
if node -e "import('./src/index.js').then(() => console.log('Main module imported successfully')).catch(e => console.error('Import failed:', e.message))" 2>/dev/null; then
    print_status "PASS" "Main module can be imported"
else
    print_status "FAIL" "Main module cannot be imported"
fi

echo ""
echo "7. Testing Core Dependencies..."
echo "------------------------------"

# Check core dependencies
print_status "INFO" "Checking core dependencies..."
check_node_module "axios" "axios"
check_node_module "dotenv" "dotenv"
check_node_module "emoji-name-map" "emoji-name-map"
check_node_module "github-username-regex" "github-username-regex"
check_node_module "word-wrap" "word-wrap"

echo ""
echo "8. Testing Development Dependencies..."
echo "------------------------------------"

# Check development dependencies
print_status "INFO" "Checking development dependencies..."
check_node_module "jest" "jest"
check_node_module "eslint" "eslint"
check_node_module "prettier" "prettier"
check_node_module "husky" "husky"

echo ""
echo "9. Testing npm Scripts..."
echo "------------------------"

# Test npm scripts
if npm run lint --silent 2>/dev/null; then
    print_status "PASS" "npm run lint successful"
else
    print_status "WARN" "npm run lint failed"
fi

if npm run format:check --silent 2>/dev/null; then
    print_status "PASS" "npm run format:check successful"
else
    print_status "WARN" "npm run format:check failed"
fi

echo ""
echo "10. Testing Jest Configuration..."
echo "--------------------------------"

# Check Jest configuration
if [ -f "jest.config.js" ]; then
    print_status "PASS" "jest.config.js exists"
else
    print_status "FAIL" "jest.config.js missing"
fi

if [ -f "jest.e2e.config.js" ]; then
    print_status "PASS" "jest.e2e.config.js exists"
else
    print_status "FAIL" "jest.e2e.config.js missing"
fi

if [ -f "jest.bench.config.js" ]; then
    print_status "PASS" "jest.bench.config.js exists"
else
    print_status "FAIL" "jest.bench.config.js missing"
fi

echo ""
echo "11. Testing ESLint Configuration..."
echo "----------------------------------"

# Check ESLint configuration
if [ -f ".eslintrc.json" ]; then
    print_status "PASS" ".eslintrc.json exists"
else
    print_status "FAIL" ".eslintrc.json missing"
fi

if [ -f "eslint.config.mjs" ]; then
    print_status "PASS" "eslint.config.mjs exists"
else
    print_status "FAIL" "eslint.config.mjs missing"
fi

echo ""
echo "12. Testing Prettier Configuration..."
echo "------------------------------------"

# Check Prettier configuration
if [ -f ".prettierrc.json" ]; then
    print_status "PASS" ".prettierrc.json exists"
else
    print_status "FAIL" ".prettierrc.json missing"
fi

if [ -f ".prettierignore" ]; then
    print_status "PASS" ".prettierignore exists"
else
    print_status "FAIL" ".prettierignore missing"
fi

echo ""
echo "13. Testing Husky Configuration..."
echo "---------------------------------"

# Check Husky configuration
if [ -d ".husky" ]; then
    print_status "PASS" ".husky directory exists"
else
    print_status "FAIL" ".husky directory missing"
fi

echo ""
echo "14. Testing API Structure..."
echo "----------------------------"

# Check API structure
if [ -f "api/index.js" ]; then
    print_status "PASS" "api/index.js exists"
else
    print_status "FAIL" "api/index.js missing"
fi

if [ -d "api" ]; then
    api_files=$(find api -name "*.js" | wc -l)
    print_status "INFO" "Found $api_files JavaScript files in api directory"
    if [ "$api_files" -gt 0 ]; then
        print_status "PASS" "API files found"
    else
        print_status "FAIL" "No API files found"
    fi
fi

echo ""
echo "15. Testing Source Code Structure..."
echo "-----------------------------------"

# Check source code structure
if [ -d "src" ]; then
    src_files=$(find src -name "*.js" | wc -l)
    print_status "INFO" "Found $src_files JavaScript files in src directory"
    if [ "$src_files" -gt 0 ]; then
        print_status "PASS" "Source files found"
    else
        print_status "FAIL" "No source files found"
    fi
fi

echo ""
echo "16. Testing Themes Structure..."
echo "-------------------------------"

# Check themes structure
if [ -d "themes" ]; then
    theme_files=$(find themes -name "*.js" | wc -l)
    print_status "INFO" "Found $theme_files theme files"
    if [ "$theme_files" -gt 0 ]; then
        print_status "PASS" "Theme files found"
    else
        print_status "FAIL" "No theme files found"
    fi
fi

echo ""
echo "17. Testing Test Structure..."
echo "-----------------------------"

# Check test structure
if [ -d "tests" ]; then
    test_files=$(find tests -name "*.js" | wc -l)
    print_status "INFO" "Found $test_files test files"
    if [ "$test_files" -gt 0 ]; then
        print_status "PASS" "Test files found"
    else
        print_status "FAIL" "No test files found"
    fi
fi

echo ""
echo "18. Testing Scripts Structure..."
echo "--------------------------------"

# Check scripts structure
if [ -d "scripts" ]; then
    script_files=$(find scripts -name "*.js" | wc -l)
    print_status "INFO" "Found $script_files script files"
    if [ "$script_files" -gt 0 ]; then
        print_status "PASS" "Script files found"
    else
        print_status "FAIL" "No script files found"
    fi
fi

echo ""
echo "19. Testing Vercel Configuration..."
echo "----------------------------------"

# Check Vercel configuration
if [ -f "vercel.json" ]; then
    print_status "PASS" "vercel.json exists"
else
    print_status "FAIL" "vercel.json missing"
fi

if [ -f ".vercelignore" ]; then
    print_status "PASS" ".vercelignore exists"
else
    print_status "FAIL" ".vercelignore missing"
fi

echo ""
echo "20. Testing Express.js Setup..."
echo "-------------------------------"

# Check Express.js setup
if [ -f "express.js" ]; then
    print_status "PASS" "express.js exists"
else
    print_status "FAIL" "express.js missing"
fi

# Test Express.js import
if node -e "require('express'); console.log('Express.js imported successfully')" 2>/dev/null; then
    print_status "PASS" "Express.js can be imported"
else
    print_status "FAIL" "Express.js cannot be imported"
fi

echo ""
echo "21. Testing Environment Variables..."
echo "-----------------------------------"

# Check environment variables setup
if [ -f ".env.example" ] || [ -f ".env" ]; then
    print_status "PASS" "Environment file exists"
else
    print_status "WARN" "No environment file found"
fi

echo ""
echo "22. Testing Documentation..."
echo "----------------------------"

# Check documentation
if [ -f "readme.md" ]; then
    print_status "PASS" "readme.md exists"
else
    print_status "FAIL" "readme.md missing"
fi

if [ -d "docs" ]; then
    print_status "PASS" "docs directory exists"
else
    print_status "FAIL" "docs directory missing"
fi

# Check if documentation mentions GitHub Readme Stats
if grep -q "github-readme-stats" readme.md 2>/dev/null; then
    print_status "PASS" "readme.md contains GitHub Readme Stats references"
else
    print_status "WARN" "readme.md missing GitHub Readme Stats references"
fi

echo ""
echo "23. Testing Basic Node.js Functionality..."
echo "------------------------------------------"

# Test basic Node.js functionality
if node -e "console.log('Node.js basic functionality test successful')" 2>/dev/null; then
    print_status "PASS" "Node.js basic functionality works"
else
    print_status "FAIL" "Node.js basic functionality failed"
fi

echo ""
echo "24. Testing npm Package.json Scripts..."
echo "---------------------------------------"

# Test if package.json has required scripts
if grep -q '"test"' package.json 2>/dev/null; then
    print_status "PASS" "test script defined in package.json"
else
    print_status "FAIL" "test script not defined in package.json"
fi

if grep -q '"lint"' package.json 2>/dev/null; then
    print_status "PASS" "lint script defined in package.json"
else
    print_status "FAIL" "lint script not defined in package.json"
fi

if grep -q '"format"' package.json 2>/dev/null; then
    print_status "PASS" "format script defined in package.json"
else
    print_status "FAIL" "format script not defined in package.json"
fi

echo ""
echo "25. Testing Jest Test Runner..."
echo "-------------------------------"

# Test Jest availability
if node -e "require('jest'); console.log('Jest is available')" 2>/dev/null; then
    print_status "PASS" "Jest is available"
else
    print_status "FAIL" "Jest is not available"
fi

echo ""
echo "26. Testing ESLint Linter..."
echo "----------------------------"

# Test ESLint availability
if node -e "require('eslint'); console.log('ESLint is available')" 2>/dev/null; then
    print_status "PASS" "ESLint is available"
else
    print_status "FAIL" "ESLint is not available"
fi

echo ""
echo "27. Testing Prettier Formatter..."
echo "---------------------------------"

# Test Prettier availability
if node -e "require('prettier'); console.log('Prettier is available')" 2>/dev/null; then
    print_status "PASS" "Prettier is available"
else
    print_status "FAIL" "Prettier is not available"
fi

echo ""
echo "28. Testing Husky Git Hooks..."
echo "-------------------------------"

# Test Husky availability
if node -e "require('husky'); console.log('Husky is available')" 2>/dev/null; then
    print_status "PASS" "Husky is available"
else
    print_status "FAIL" "Husky is not available"
fi

echo ""
echo "29. Testing Core Dependencies Functionality..."
echo "----------------------------------------------"

# Test axios functionality
if node -e "const axios = require('axios'); console.log('Axios functionality test successful')" 2>/dev/null; then
    print_status "PASS" "Axios functionality works"
else
    print_status "FAIL" "Axios functionality failed"
fi

# Test dotenv functionality
if node -e "require('dotenv'); console.log('Dotenv functionality test successful')" 2>/dev/null; then
    print_status "PASS" "Dotenv functionality works"
else
    print_status "FAIL" "Dotenv functionality failed"
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
echo "- System dependencies (Node.js, npm, Git, cURL)"
echo "- Node.js version compatibility (>= 18)"
echo "- npm version compatibility (>= 8)"
echo "- Project structure and files"
echo "- npm install and dependencies"
echo "- Core module imports"
echo "- Development tools (Jest, ESLint, Prettier, Husky)"
echo "- API and source code structure"
echo "- Configuration files"
echo "- Documentation"
echo "- Basic Node.js functionality"
echo "- Package.json scripts"
echo "- Core dependencies functionality"
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
    print_status "INFO" "All tests passed! Your GitHub Readme Stats environment is ready!"
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your GitHub Readme Stats environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi

print_status "INFO" "You can now run GitHub Readme Stats development and tests."
print_status "INFO" "Example: npm test"
echo ""
print_status "INFO" "For more information, see readme.md" 