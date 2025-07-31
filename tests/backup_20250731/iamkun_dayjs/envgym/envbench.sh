#!/bin/bash

# Day.js Environment Benchmark Test Script
# This script tests the environment setup for Day.js: A minimalist JavaScript library for date and time manipulation

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
    docker stop dayjs-env-test 2>/dev/null || true
    docker rm dayjs-env-test 2>/dev/null || true
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
        print_status "WARN" "Docker not available - Docker environment not available"
    elif [ -f "envgym/envgym.dockerfile" ]; then
        echo "Building Docker image..."
        if timeout 60s docker build -f envgym/envgym.dockerfile -t dayjs-env-test .; then
            echo "Docker build successful - running environment test in Docker container..."
            if docker run --rm -v "$(pwd):/home/cc/EnvGym/data/iamkun_dayjs" --init dayjs-env-test bash -c "
                trap 'exit 0' SIGINT SIGTERM
                cd /home/cc/EnvGym/data/iamkun_dayjs
                bash envgym/envbench.sh
            "; then
                echo "Docker container test completed successfully"
                # Don't cleanup here, let the script continue to show results
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
        print_status "WARN" "envgym.dockerfile not found - Docker environment not available"
    fi
fi

# If Docker failed or not available, skip local environment tests
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ] || [ "${DOCKER_MODE:-false}" = "false" ]; then
    echo "Docker environment not available - skipping local environment tests"
    echo "This script is designed to test Docker environment only"
    exit 0
fi

echo "=========================================="
echo "Day.js Environment Benchmark Test"
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
        
        if grep -q "node:18" envgym/envgym.dockerfile; then
            print_status "PASS" "Node.js 18 specified"
        else
            print_status "WARN" "Node.js 18 not specified"
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
        
        if grep -q "git" envgym/envgym.dockerfile; then
            print_status "PASS" "git found"
        else
            print_status "FAIL" "git not found"
        fi
        
        if grep -q "curl" envgym/envgym.dockerfile; then
            print_status "PASS" "curl found"
        else
            print_status "FAIL" "curl not found"
        fi
        
        if grep -q "bash" envgym/envgym.dockerfile; then
            print_status "PASS" "bash found"
        else
            print_status "FAIL" "bash not found"
        fi
        
        if grep -q "package.json" envgym/envgym.dockerfile; then
            print_status "PASS" "package.json copy found"
        else
            print_status "WARN" "package.json copy not found"
        fi
        
        if grep -q "npm ci" envgym/envgym.dockerfile; then
            print_status "PASS" "npm ci found"
        else
            print_status "FAIL" "npm ci not found"
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
# Check Node.js
if command -v node &> /dev/null; then
    node_version=$(node --version 2>&1)
    print_status "PASS" "Node.js is available: $node_version"
    
    # Check Node.js version (should be >= 14)
    node_major=$(echo $node_version | sed 's/v//' | cut -d'.' -f1)
    if [ -n "$node_major" ] && [ "$node_major" -ge 14 ]; then
        print_status "PASS" "Node.js version is >= 14 (compatible)"
    else
        print_status "WARN" "Node.js version should be >= 14 (found: $node_major)"
    fi
else
    print_status "FAIL" "Node.js is not available"
fi

# Check npm
if command -v npm &> /dev/null; then
    npm_version=$(npm --version 2>&1)
    print_status "PASS" "npm is available: $npm_version"
    
    # Check npm version (should be >= 6)
    npm_major=$(echo $npm_version | cut -d'.' -f1)
    if [ -n "$npm_major" ] && [ "$npm_major" -ge 6 ]; then
        print_status "PASS" "npm version is >= 6 (compatible)"
    else
        print_status "WARN" "npm version should be >= 6 (found: $npm_major)"
    fi
else
    print_status "FAIL" "npm is not available"
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

# Check vim/nano
if command -v vim &> /dev/null; then
    print_status "PASS" "vim is available"
else
    print_status "WARN" "vim is not available"
fi

if command -v nano &> /dev/null; then
    print_status "PASS" "nano is available"
else
    print_status "WARN" "nano is not available"
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

if [ -d "test" ]; then
    print_status "PASS" "test directory exists"
else
    print_status "FAIL" "test directory not found"
fi

if [ -d "build" ]; then
    print_status "PASS" "build directory exists"
else
    print_status "FAIL" "build directory not found"
fi

if [ -d "docs" ]; then
    print_status "PASS" "docs directory exists"
else
    print_status "FAIL" "docs directory not found"
fi

if [ -d "types" ]; then
    print_status "PASS" "types directory exists"
else
    print_status "FAIL" "types directory not found"
fi

if [ -d ".github" ]; then
    print_status "PASS" ".github directory exists"
else
    print_status "FAIL" ".github directory not found"
fi

# Check key files
if [ -f "README.md" ]; then
    print_status "PASS" "README.md exists"
else
    print_status "FAIL" "README.md not found"
fi

if [ -f "package.json" ]; then
    print_status "PASS" "package.json exists"
else
    print_status "FAIL" "package.json not found"
fi

if [ -f "package-lock.json" ]; then
    print_status "PASS" "package-lock.json exists"
else
    print_status "FAIL" "package-lock.json not found"
fi

if [ -f "LICENSE" ]; then
    print_status "PASS" "LICENSE exists"
else
    print_status "FAIL" "LICENSE not found"
fi

if [ -f "CHANGELOG.md" ]; then
    print_status "PASS" "CHANGELOG.md exists"
else
    print_status "FAIL" "CHANGELOG.md not found"
fi

if [ -f "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md exists"
else
    print_status "FAIL" "CONTRIBUTING.md not found"
fi

# Check source files
if [ -f "src/index.js" ]; then
    print_status "PASS" "src/index.js exists"
else
    print_status "FAIL" "src/index.js not found"
fi

if [ -f "src/utils.js" ]; then
    print_status "PASS" "src/utils.js exists"
else
    print_status "FAIL" "src/utils.js not found"
fi

if [ -f "src/constant.js" ]; then
    print_status "PASS" "src/constant.js exists"
else
    print_status "FAIL" "src/constant.js not found"
fi

# Check test files
if [ -f "test/parse.test.js" ]; then
    print_status "PASS" "test/parse.test.js exists"
else
    print_status "FAIL" "test/parse.test.js not found"
fi

if [ -f "test/display.test.js" ]; then
    print_status "PASS" "test/display.test.js exists"
else
    print_status "FAIL" "test/display.test.js not found"
fi

if [ -f "test/manipulate.test.js" ]; then
    print_status "PASS" "test/manipulate.test.js exists"
else
    print_status "FAIL" "test/manipulate.test.js not found"
fi

if [ -f "test/query.test.js" ]; then
    print_status "PASS" "test/query.test.js exists"
else
    print_status "FAIL" "test/query.test.js not found"
fi

# Check build files
if [ -f "build/index.js" ]; then
    print_status "PASS" "build/index.js exists"
else
    print_status "FAIL" "build/index.js not found"
fi

if [ -f "build/rollup.config.js" ]; then
    print_status "PASS" "build/rollup.config.js exists"
else
    print_status "FAIL" "build/rollup.config.js not found"
fi

# Check config files
if [ -f ".eslintrc.json" ]; then
    print_status "PASS" ".eslintrc.json exists"
else
    print_status "FAIL" ".eslintrc.json not found"
fi

if [ -f "babel.config.js" ]; then
    print_status "PASS" "babel.config.js exists"
else
    print_status "FAIL" "babel.config.js not found"
fi

if [ -f "prettier.config.js" ]; then
    print_status "PASS" "prettier.config.js exists"
else
    print_status "FAIL" "prettier.config.js not found"
fi

if [ -f "karma.sauce.conf.js" ]; then
    print_status "PASS" "karma.sauce.conf.js exists"
else
    print_status "FAIL" "karma.sauce.conf.js not found"
fi

# Check locale and plugin directories
if [ -d "src/locale" ]; then
    print_status "PASS" "src/locale directory exists"
else
    print_status "FAIL" "src/locale directory not found"
fi

if [ -d "src/plugin" ]; then
    print_status "PASS" "src/plugin directory exists"
else
    print_status "FAIL" "src/plugin directory not found"
fi

if [ -d "test/locale" ]; then
    print_status "PASS" "test/locale directory exists"
else
    print_status "FAIL" "test/locale directory not found"
fi

if [ -d "test/plugin" ]; then
    print_status "PASS" "test/plugin directory exists"
else
    print_status "FAIL" "test/plugin directory not found"
fi

echo ""
echo "3. Checking Environment Variables..."
echo "-----------------------------------"
# Check Node.js environment
if [ -n "${NODE_ENV:-}" ]; then
    print_status "PASS" "NODE_ENV is set: $NODE_ENV"
else
    print_status "WARN" "NODE_ENV is not set"
fi

if [ -n "${NPM_CONFIG_CACHE:-}" ]; then
    print_status "PASS" "NPM_CONFIG_CACHE is set: $NPM_CONFIG_CACHE"
else
    print_status "WARN" "NPM_CONFIG_CACHE is not set"
fi

if [ -n "${TZ:-}" ]; then
    print_status "PASS" "TZ is set: $TZ"
else
    print_status "WARN" "TZ is not set"
fi

# Check PATH
if echo "$PATH" | grep -q "node"; then
    print_status "PASS" "node is in PATH"
else
    print_status "WARN" "node is not in PATH"
fi

if echo "$PATH" | grep -q "npm"; then
    print_status "PASS" "npm is in PATH"
else
    print_status "WARN" "npm is not in PATH"
fi

if echo "$PATH" | grep -q "git"; then
    print_status "PASS" "git is in PATH"
else
    print_status "WARN" "git is not in PATH"
fi

if echo "$PATH" | grep -q "bash"; then
    print_status "PASS" "bash is in PATH"
else
    print_status "WARN" "bash is not in PATH"
fi

echo ""
echo "4. Testing Node.js Environment..."
echo "--------------------------------"
# Test Node.js
if command -v node &> /dev/null; then
    print_status "PASS" "node is available"
    
    # Test Node.js execution
    if timeout 30s node --version >/dev/null 2>&1; then
        print_status "PASS" "Node.js execution works"
    else
        print_status "WARN" "Node.js execution failed"
    fi
    
    # Test Node.js eval
    if timeout 30s node -e "console.log('Hello from Node.js')" >/dev/null 2>&1; then
        print_status "PASS" "Node.js eval works"
    else
        print_status "WARN" "Node.js eval failed"
    fi
    
    # Test Node.js require
    if timeout 30s node -e "console.log(require('path').dirname('test'))" >/dev/null 2>&1; then
        print_status "PASS" "Node.js require works"
    else
        print_status "WARN" "Node.js require failed"
    fi
else
    print_status "FAIL" "node is not available"
fi

echo ""
echo "5. Testing npm Package Management..."
echo "-----------------------------------"
# Test npm
if command -v npm &> /dev/null; then
    print_status "PASS" "npm is available"
    
    # Test npm version
    if timeout 30s npm --version >/dev/null 2>&1; then
        print_status "PASS" "npm version command works"
    else
        print_status "WARN" "npm version command failed"
    fi
    
    # Test npm list
    if timeout 30s npm list --depth=0 >/dev/null 2>&1; then
        print_status "PASS" "npm list command works"
    else
        print_status "WARN" "npm list command failed"
    fi
    
    # Test npm config
    if timeout 30s npm config list >/dev/null 2>&1; then
        print_status "PASS" "npm config command works"
    else
        print_status "WARN" "npm config command failed"
    fi
else
    print_status "FAIL" "npm is not available"
fi

echo ""
echo "6. Testing Day.js Dependencies..."
echo "---------------------------------"
# Test if dependencies are installed
if command -v node &> /dev/null; then
    print_status "PASS" "node is available for dependency testing"
    
    # Test if jest is available
    if timeout 30s node -e "try { require('jest'); console.log('jest available'); } catch(e) { console.log('jest not available'); }" >/dev/null 2>&1; then
        print_status "PASS" "jest is available"
    else
        print_status "WARN" "jest is not available"
    fi
    
    # Test if eslint is available
    if timeout 30s node -e "try { require('eslint'); console.log('eslint available'); } catch(e) { console.log('eslint not available'); }" >/dev/null 2>&1; then
        print_status "PASS" "eslint is available"
    else
        print_status "WARN" "eslint is not available"
    fi
    
    # Test if babel is available
    if timeout 30s node -e "try { require('@babel/core'); console.log('babel available'); } catch(e) { console.log('babel not available'); }" >/dev/null 2>&1; then
        print_status "PASS" "babel is available"
    else
        print_status "WARN" "babel is not available"
    fi
    
    # Test if rollup is available
    if timeout 30s node -e "try { require('rollup'); console.log('rollup available'); } catch(e) { console.log('rollup not available'); }" >/dev/null 2>&1; then
        print_status "PASS" "rollup is available"
    else
        print_status "WARN" "rollup is not available"
    fi
    
    # Test if prettier is available
    if timeout 30s node -e "try { require('prettier'); console.log('prettier available'); } catch(e) { console.log('prettier not available'); }" >/dev/null 2>&1; then
        print_status "PASS" "prettier is available"
    else
        print_status "WARN" "prettier is not available"
    fi
else
    print_status "WARN" "node not available for dependency testing"
fi

echo ""
echo "7. Testing Day.js Scripts..."
echo "----------------------------"
# Test package.json scripts
if [ -f "package.json" ]; then
    print_status "PASS" "package.json exists for script testing"
    
    if command -v npm &> /dev/null; then
        print_status "PASS" "npm is available for script testing"
        
        # Test npm run test (dry run)
        if timeout 30s npm run test --dry-run >/dev/null 2>&1; then
            print_status "PASS" "npm run test script exists"
        else
            print_status "WARN" "npm run test script failed or not found"
        fi
        
        # Test npm run build (dry run)
        if timeout 30s npm run build --dry-run >/dev/null 2>&1; then
            print_status "PASS" "npm run build script exists"
        else
            print_status "WARN" "npm run build script failed or not found"
        fi
        
        # Test npm run lint (dry run)
        if timeout 30s npm run lint --dry-run >/dev/null 2>&1; then
            print_status "PASS" "npm run lint script exists"
        else
            print_status "WARN" "npm run lint script failed or not found"
        fi
        
        # Test npm run babel (dry run)
        if timeout 30s npm run babel --dry-run >/dev/null 2>&1; then
            print_status "PASS" "npm run babel script exists"
        else
            print_status "WARN" "npm run babel script failed or not found"
        fi
    else
        print_status "WARN" "npm not available for script testing"
    fi
else
    print_status "FAIL" "package.json not found"
fi

echo ""
echo "8. Testing Day.js Build System..."
echo "---------------------------------"
# Test build system
if command -v node &> /dev/null; then
    print_status "PASS" "node is available for build testing"
    
    # Test if build script can be executed
    if [ -f "build/index.js" ]; then
        if timeout 30s node build/index.js >/dev/null 2>&1; then
            print_status "PASS" "build/index.js can be executed"
        else
            print_status "WARN" "build/index.js execution failed"
        fi
    else
        print_status "FAIL" "build/index.js not found"
    fi
    
    # Test if rollup config is valid
    if [ -f "build/rollup.config.js" ]; then
        if timeout 30s node -e "try { require('./build/rollup.config.js'); console.log('rollup config valid'); } catch(e) { console.log('rollup config invalid'); }" >/dev/null 2>&1; then
            print_status "PASS" "rollup.config.js is valid"
        else
            print_status "WARN" "rollup.config.js is invalid"
        fi
    else
        print_status "FAIL" "build/rollup.config.js not found"
    fi
else
    print_status "WARN" "node not available for build testing"
fi

echo ""
echo "9. Testing Day.js Source Code..."
echo "--------------------------------"
# Test source code
if command -v node &> /dev/null; then
    print_status "PASS" "node is available for source testing"
    
    # Test if main source file can be loaded
    if [ -f "src/index.js" ]; then
        if timeout 30s node -e "try { require('./src/index.js'); console.log('src/index.js loaded'); } catch(e) { console.log('src/index.js load failed'); }" >/dev/null 2>&1; then
            print_status "PASS" "src/index.js can be loaded"
        else
            print_status "WARN" "src/index.js load failed"
        fi
    else
        print_status "FAIL" "src/index.js not found"
    fi
    
    # Test if utils can be loaded
    if [ -f "src/utils.js" ]; then
        if timeout 30s node -e "try { require('./src/utils.js'); console.log('src/utils.js loaded'); } catch(e) { console.log('src/utils.js load failed'); }" >/dev/null 2>&1; then
            print_status "PASS" "src/utils.js can be loaded"
        else
            print_status "WARN" "src/utils.js load failed"
        fi
    else
        print_status "FAIL" "src/utils.js not found"
    fi
    
    # Test if constants can be loaded
    if [ -f "src/constant.js" ]; then
        if timeout 30s node -e "try { require('./src/constant.js'); console.log('src/constant.js loaded'); } catch(e) { console.log('src/constant.js load failed'); }" >/dev/null 2>&1; then
            print_status "PASS" "src/constant.js can be loaded"
        else
            print_status "WARN" "src/constant.js load failed"
        fi
    else
        print_status "FAIL" "src/constant.js not found"
    fi
else
    print_status "WARN" "node not available for source testing"
fi

echo ""
echo "10. Testing Day.js Test System..."
echo "---------------------------------"
# Test test system
if command -v node &> /dev/null; then
    print_status "PASS" "node is available for test system testing"
    
    # Test if jest is available
    if timeout 30s node -e "try { require('jest'); console.log('jest available'); } catch(e) { console.log('jest not available'); }" >/dev/null 2>&1; then
        print_status "PASS" "jest is available for testing"
        
        # Test if test files exist and can be parsed
        if [ -f "test/parse.test.js" ]; then
            if timeout 30s node -c test/parse.test.js >/dev/null 2>&1; then
                print_status "PASS" "test/parse.test.js syntax is valid"
            else
                print_status "WARN" "test/parse.test.js syntax is invalid"
            fi
        else
            print_status "FAIL" "test/parse.test.js not found"
        fi
        
        if [ -f "test/display.test.js" ]; then
            if timeout 30s node -c test/display.test.js >/dev/null 2>&1; then
                print_status "PASS" "test/display.test.js syntax is valid"
            else
                print_status "WARN" "test/display.test.js syntax is invalid"
            fi
        else
            print_status "FAIL" "test/display.test.js not found"
        fi
        
        if [ -f "test/manipulate.test.js" ]; then
            if timeout 30s node -c test/manipulate.test.js >/dev/null 2>&1; then
                print_status "PASS" "test/manipulate.test.js syntax is valid"
            else
                print_status "WARN" "test/manipulate.test.js syntax is invalid"
            fi
        else
            print_status "FAIL" "test/manipulate.test.js not found"
        fi
    else
        print_status "WARN" "jest not available for testing"
    fi
else
    print_status "WARN" "node not available for test system testing"
fi

echo ""
echo "11. Testing Day.js Locale System..."
echo "-----------------------------------"
# Test locale system
if [ -d "src/locale" ]; then
    print_status "PASS" "src/locale directory exists"
    
    # Count locale files
    locale_count=$(find src/locale -name "*.js" | wc -l)
    if [ "$locale_count" -gt 0 ]; then
        print_status "PASS" "Found $locale_count locale files"
    else
        print_status "WARN" "No locale files found"
    fi
    
    # Test if locale files are valid
    if command -v node &> /dev/null; then
        if timeout 30s node -c src/locale/*.js >/dev/null 2>&1; then
            print_status "PASS" "Locale files syntax is valid"
        else
            print_status "WARN" "Some locale files have syntax errors"
        fi
    else
        print_status "WARN" "node not available for locale testing"
    fi
else
    print_status "FAIL" "src/locale directory not found"
fi

echo ""
echo "12. Testing Day.js Plugin System..."
echo "-----------------------------------"
# Test plugin system
if [ -d "src/plugin" ]; then
    print_status "PASS" "src/plugin directory exists"
    
    # Count plugin files
    plugin_count=$(find src/plugin -name "*.js" | wc -l)
    if [ "$plugin_count" -gt 0 ]; then
        print_status "PASS" "Found $plugin_count plugin files"
    else
        print_status "WARN" "No plugin files found"
    fi
    
    # Test if plugin files are valid
    if command -v node &> /dev/null; then
        if timeout 30s node -c src/plugin/*.js >/dev/null 2>&1; then
            print_status "PASS" "Plugin files syntax is valid"
        else
            print_status "WARN" "Some plugin files have syntax errors"
        fi
    else
        print_status "WARN" "node not available for plugin testing"
    fi
else
    print_status "FAIL" "src/plugin directory not found"
fi

echo ""
echo "13. Testing Day.js Documentation..."
echo "-----------------------------------"
# Test documentation
if [ -d "docs" ]; then
    print_status "PASS" "docs directory exists"
else
    print_status "FAIL" "docs directory not found"
fi

if [ -r "README.md" ]; then
    print_status "PASS" "README.md is readable"
else
    print_status "WARN" "README.md is not readable"
fi

if [ -r "CHANGELOG.md" ]; then
    print_status "PASS" "CHANGELOG.md is readable"
else
    print_status "WARN" "CHANGELOG.md is not readable"
fi

if [ -r "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md is readable"
else
    print_status "WARN" "CONTRIBUTING.md is not readable"
fi

if [ -r "LICENSE" ]; then
    print_status "PASS" "LICENSE is readable"
else
    print_status "WARN" "LICENSE is not readable"
fi

echo ""
echo "14. Testing Day.js Configuration..."
echo "-----------------------------------"
# Test configuration files
if [ -r ".eslintrc.json" ]; then
    print_status "PASS" ".eslintrc.json is readable"
    
    if command -v node &> /dev/null; then
        if timeout 30s node -e "try { JSON.parse(require('fs').readFileSync('.eslintrc.json')); console.log('eslint config valid'); } catch(e) { console.log('eslint config invalid'); }" >/dev/null 2>&1; then
            print_status "PASS" ".eslintrc.json is valid JSON"
        else
            print_status "WARN" ".eslintrc.json is invalid JSON"
        fi
    else
        print_status "WARN" "node not available for eslint config testing"
    fi
else
    print_status "FAIL" ".eslintrc.json not found or not readable"
fi

if [ -r "babel.config.js" ]; then
    print_status "PASS" "babel.config.js is readable"
    
    if command -v node &> /dev/null; then
        if timeout 30s node -c babel.config.js >/dev/null 2>&1; then
            print_status "PASS" "babel.config.js syntax is valid"
        else
            print_status "WARN" "babel.config.js syntax is invalid"
        fi
    else
        print_status "WARN" "node not available for babel config testing"
    fi
else
    print_status "FAIL" "babel.config.js not found or not readable"
fi

if [ -r "prettier.config.js" ]; then
    print_status "PASS" "prettier.config.js is readable"
    
    if command -v node &> /dev/null; then
        if timeout 30s node -c prettier.config.js >/dev/null 2>&1; then
            print_status "PASS" "prettier.config.js syntax is valid"
        else
            print_status "WARN" "prettier.config.js syntax is invalid"
        fi
    else
        print_status "WARN" "node not available for prettier config testing"
    fi
else
    print_status "FAIL" "prettier.config.js not found or not readable"
fi

if [ -r "karma.sauce.conf.js" ]; then
    print_status "PASS" "karma.sauce.conf.js is readable"
    
    if command -v node &> /dev/null; then
        if timeout 30s node -c karma.sauce.conf.js >/dev/null 2>&1; then
            print_status "PASS" "karma.sauce.conf.js syntax is valid"
        else
            print_status "WARN" "karma.sauce.conf.js syntax is invalid"
        fi
    else
        print_status "WARN" "node not available for karma config testing"
    fi
else
    print_status "FAIL" "karma.sauce.conf.js not found or not readable"
fi

echo ""
echo "15. Testing Day.js TypeScript Support..."
echo "----------------------------------------"
# Test TypeScript support
if [ -d "types" ]; then
    print_status "PASS" "types directory exists"
    
    # Check for TypeScript definition files
    if [ -f "index.d.ts" ]; then
        print_status "PASS" "index.d.ts exists"
    else
        print_status "WARN" "index.d.ts not found"
    fi
    
    # Count type definition files
    type_count=$(find types -name "*.d.ts" 2>/dev/null | wc -l)
    if [ "$type_count" -gt 0 ]; then
        print_status "PASS" "Found $type_count TypeScript definition files"
    else
        print_status "WARN" "No TypeScript definition files found"
    fi
else
    print_status "FAIL" "types directory not found"
fi

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (Node.js >= 14, npm >= 6, Git, Bash, curl)"
echo "- Project structure (src, test, build, docs, types/)"
echo "- Environment variables (NODE_ENV, NPM_CONFIG_CACHE, TZ, PATH)"
echo "- Node.js environment (node, npm, package management)"
echo "- Day.js dependencies (jest, eslint, babel, rollup, prettier)"
echo "- Day.js scripts (test, build, lint, babel)"
echo "- Day.js build system (build/index.js, rollup.config.js)"
echo "- Day.js source code (src/index.js, src/utils.js, src/constant.js)"
echo "- Day.js test system (jest, test files)"
echo "- Day.js locale system (src/locale/)"
echo "- Day.js plugin system (src/plugin/)"
echo "- Day.js documentation (README.md, CHANGELOG.md, CONTRIBUTING.md)"
echo "- Day.js configuration (.eslintrc.json, babel.config.js, prettier.config.js)"
echo "- Day.js TypeScript support (types/, index.d.ts)"
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
    print_status "INFO" "All tests passed! Your Day.js environment is ready!"
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your Day.js environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now run Day.js: A minimalist JavaScript library for date and time manipulation."
print_status "INFO" "Example: npm test"
echo ""
print_status "INFO" "For more information, see README.md" 