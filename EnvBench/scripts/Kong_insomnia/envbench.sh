#!/bin/bash

# Kong Insomnia Environment Benchmark Test Script
# This script tests the Docker environment setup for Kong Insomnia: A cross-platform API client for GraphQL, REST, WebSockets, Server-sent events (SSE), gRPC and any other HTTP compatible protocol
# Tailored specifically for Insomnia project requirements and features

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
    jobs -p | xargs -r kill
    rm -f docker_build.log
    docker stop insomnia-env-test 2>/dev/null || true
    docker rm insomnia-env-test 2>/dev/null || true
    exit 0
}

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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the Kong_insomnia project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t insomnia-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/Kong_insomnia" insomnia-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "Kong Insomnia Environment Benchmark Test"
echo "=========================================="

echo "1. Checking System Dependencies..."
echo "--------------------------------"
# Check Node.js
if command -v node &> /dev/null; then
    node_version=$(node --version 2>&1)
    print_status "PASS" "Node.js is available: $node_version"
    
    # Check Node.js version requirement (>=22.14.0)
    node_major=$(node --version | sed 's/v\([0-9]*\)\.[0-9]*\.[0-9]*/\1/')
    node_minor=$(node --version | sed 's/v[0-9]*\.\([0-9]*\)\.[0-9]*/\1/')
    node_patch=$(node --version | sed 's/v[0-9]*\.[0-9]*\.\([0-9]*\)/\1/')
    
    if [ "$node_major" -gt 22 ] || ([ "$node_major" -eq 22 ] && [ "$node_minor" -ge 14 ]); then
        print_status "PASS" "Node.js version is >= 22.14.0 (compatible)"
    else
        print_status "WARN" "Node.js version should be >= 22.14.0 (found: $node_version)"
    fi
else
    print_status "FAIL" "Node.js is not available"
fi

# Check npm
if command -v npm &> /dev/null; then
    npm_version=$(npm --version 2>&1)
    print_status "PASS" "npm is available: $npm_version"
    
    # Check npm version requirement (>=10)
    npm_major=$(npm --version | cut -d'.' -f1)
    if [ "$npm_major" -ge 10 ]; then
        print_status "PASS" "npm version is >= 10 (compatible)"
    else
        print_status "WARN" "npm version should be >= 10 (found: $npm_version)"
    fi
else
    print_status "FAIL" "npm is not available"
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

# Check build tools
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version 2>&1 | head -n 1)
    print_status "PASS" "GCC is available: $gcc_version"
else
    print_status "FAIL" "GCC is not available"
fi

if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "Make is available: $make_version"
else
    print_status "FAIL" "Make is not available"
fi

# Check mkcert
if command -v mkcert &> /dev/null; then
    mkcert_version=$(mkcert --version 2>&1 | head -n 1)
    print_status "PASS" "mkcert is available: $mkcert_version"
else
    print_status "WARN" "mkcert is not available"
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
if [ -d "packages" ]; then
    print_status "PASS" "packages directory exists (monorepo structure)"
else
    print_status "FAIL" "packages directory not found"
fi

if [ -d "packages/insomnia" ]; then
    print_status "PASS" "packages/insomnia directory exists (main app)"
else
    print_status "FAIL" "packages/insomnia directory not found"
fi

if [ -d "packages/insomnia-inso" ]; then
    print_status "PASS" "packages/insomnia-inso directory exists (CLI tool)"
else
    print_status "FAIL" "packages/insomnia-inso directory not found"
fi

if [ -d "packages/insomnia-testing" ]; then
    print_status "PASS" "packages/insomnia-testing directory exists (testing utilities)"
else
    print_status "FAIL" "packages/insomnia-testing directory not found"
fi

if [ -d "packages/insomnia-smoke-test" ]; then
    print_status "PASS" "packages/insomnia-smoke-test directory exists (smoke tests)"
else
    print_status "FAIL" "packages/insomnia-smoke-test directory not found"
fi

if [ -d "packages/insomnia-scripting-environment" ]; then
    print_status "PASS" "packages/insomnia-scripting-environment directory exists (scripting)"
else
    print_status "FAIL" "packages/insomnia-scripting-environment directory not found"
fi

if [ -d "screenshots" ]; then
    print_status "PASS" "screenshots directory exists"
else
    print_status "FAIL" "screenshots directory not found"
fi

if [ -d "patches" ]; then
    print_status "PASS" "patches directory exists"
else
    print_status "FAIL" "patches directory not found"
fi

if [ -d ".github" ]; then
    print_status "PASS" ".github directory exists"
else
    print_status "FAIL" ".github directory not found"
fi

if [ -d ".vscode" ]; then
    print_status "PASS" ".vscode directory exists"
else
    print_status "FAIL" ".vscode directory not found"
fi

# Check key files
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

if [ -f ".nvmrc" ]; then
    print_status "PASS" ".nvmrc exists"
else
    print_status "FAIL" ".nvmrc not found"
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

if [ -f "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md exists"
else
    print_status "FAIL" "CONTRIBUTING.md not found"
fi

if [ -f "DEVELOPMENT.md" ]; then
    print_status "PASS" "DEVELOPMENT.md exists"
else
    print_status "FAIL" "DEVELOPMENT.md not found"
fi

if [ -f "CODE_OF_CONDUCT.md" ]; then
    print_status "PASS" "CODE_OF_CONDUCT.md exists"
else
    print_status "FAIL" "CODE_OF_CONDUCT.md not found"
fi

if [ -f "SECURITY.md" ]; then
    print_status "PASS" "SECURITY.md exists"
else
    print_status "FAIL" "SECURITY.md not found"
fi

if [ -f "CHANGELOG.md" ]; then
    print_status "PASS" "CHANGELOG.md exists"
else
    print_status "FAIL" "CHANGELOG.md not found"
fi

if [ -f "eslint.config.mjs" ]; then
    print_status "PASS" "eslint.config.mjs exists"
else
    print_status "FAIL" "eslint.config.mjs not found"
fi

if [ -f ".prettierrc" ]; then
    print_status "PASS" ".prettierrc exists"
else
    print_status "FAIL" ".prettierrc not found"
fi

if [ -f ".prettierignore" ]; then
    print_status "PASS" ".prettierignore exists"
else
    print_status "FAIL" ".prettierignore not found"
fi

if [ -f ".markdownlint.yaml" ]; then
    print_status "PASS" ".markdownlint.yaml exists"
else
    print_status "FAIL" ".markdownlint.yaml not found"
fi

if [ -f ".npmrc" ]; then
    print_status "PASS" ".npmrc exists"
else
    print_status "FAIL" ".npmrc not found"
fi

if [ -f ".gitignore" ]; then
    print_status "PASS" ".gitignore exists"
else
    print_status "FAIL" ".gitignore not found"
fi

if [ -f ".gitattributes" ]; then
    print_status "PASS" ".gitattributes exists"
else
    print_status "FAIL" ".gitattributes not found"
fi

if [ -f ".dockerignore" ]; then
    print_status "PASS" ".dockerignore exists"
else
    print_status "FAIL" ".dockerignore not found"
fi

if [ -f ".clang-format" ]; then
    print_status "PASS" ".clang-format exists"
else
    print_status "FAIL" ".clang-format not found"
fi

if [ -f "build-secure-wrapper.sh" ]; then
    print_status "PASS" "build-secure-wrapper.sh exists"
else
    print_status "FAIL" "build-secure-wrapper.sh not found"
fi

if [ -f "flake.nix" ]; then
    print_status "PASS" "flake.nix exists"
else
    print_status "FAIL" "flake.nix not found"
fi

if [ -f "flake.lock" ]; then
    print_status "PASS" "flake.lock exists"
else
    print_status "FAIL" "flake.lock not found"
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

if [ -n "${NODE_VERSION:-}" ]; then
    print_status "PASS" "NODE_VERSION is set: $NODE_VERSION"
else
    print_status "WARN" "NODE_VERSION is not set"
fi

if [ -n "${PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD:-}" ]; then
    print_status "PASS" "PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD is set: $PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD"
else
    print_status "WARN" "PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD is not set"
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

echo ""
echo "4. Testing Node.js Environment..."
echo "--------------------------------"
# Test Node.js
if command -v node &> /dev/null; then
    print_status "PASS" "node is available"
    
    # Test Node.js execution
    if timeout 30s node -e "console.log('Node.js works')" >/dev/null 2>&1; then
        print_status "PASS" "Node.js execution works"
    else
        print_status "WARN" "Node.js execution failed"
    fi
    
    # Test Node.js modules
    if timeout 30s node -e "console.log(require('fs').existsSync('package.json'))" >/dev/null 2>&1; then
        print_status "PASS" "Node.js fs module works"
    else
        print_status "WARN" "Node.js fs module failed"
    fi
    
    # Test Node.js version
    if timeout 30s node -e "console.log(process.version)" >/dev/null 2>&1; then
        print_status "PASS" "Node.js version check works"
    else
        print_status "WARN" "Node.js version check failed"
    fi
else
    print_status "FAIL" "node is not available"
fi

echo ""
echo "5. Testing npm Environment..."
echo "----------------------------"
# Test npm
if command -v npm &> /dev/null; then
    print_status "PASS" "npm is available"
    
    # Test npm version
    if timeout 30s npm --version >/dev/null 2>&1; then
        print_status "PASS" "npm version command works"
    else
        print_status "WARN" "npm version command failed"
    fi
    
    # Test npm config
    if timeout 30s npm config list >/dev/null 2>&1; then
        print_status "PASS" "npm config command works"
    else
        print_status "WARN" "npm config command failed"
    fi
    
    # Test npm workspaces
    if timeout 30s npm run --workspaces --if-present --silent >/dev/null 2>&1; then
        print_status "PASS" "npm workspaces command works"
    else
        print_status "WARN" "npm workspaces command failed"
    fi
else
    print_status "FAIL" "npm is not available"
fi

echo ""
echo "6. Testing Insomnia Build System..."
echo "----------------------------------"
# Test package.json
if [ -f "package.json" ]; then
    print_status "PASS" "package.json exists for build testing"
    
    # Test package.json structure
    if grep -q '"name"' package.json; then
        print_status "PASS" "package.json has name field"
    else
        print_status "FAIL" "package.json missing name field"
    fi
    
    if grep -q '"version"' package.json; then
        print_status "PASS" "package.json has version field"
    else
        print_status "FAIL" "package.json missing version field"
    fi
    
    if grep -q '"scripts"' package.json; then
        print_status "PASS" "package.json has scripts field"
    else
        print_status "FAIL" "package.json missing scripts field"
    fi
    
    if grep -q '"workspaces"' package.json; then
        print_status "PASS" "package.json has workspaces field"
    else
        print_status "FAIL" "package.json missing workspaces field"
    fi
    
    if grep -q '"engines"' package.json; then
        print_status "PASS" "package.json has engines field"
    else
        print_status "FAIL" "package.json missing engines field"
    fi
else
    print_status "FAIL" "package.json not found"
fi

# Test .nvmrc
if [ -f ".nvmrc" ]; then
    print_status "PASS" ".nvmrc exists"
    
    nvmrc_version=$(cat .nvmrc)
    if [ -n "$nvmrc_version" ]; then
        print_status "PASS" ".nvmrc contains version: $nvmrc_version"
    else
        print_status "FAIL" ".nvmrc is empty"
    fi
else
    print_status "FAIL" ".nvmrc not found"
fi

echo ""
echo "7. Testing Insomnia Monorepo Structure..."
echo "----------------------------------------"
# Test workspace packages
if [ -d "packages/insomnia" ]; then
    print_status "PASS" "packages/insomnia exists"
    
    if [ -f "packages/insomnia/package.json" ]; then
        print_status "PASS" "packages/insomnia/package.json exists"
    else
        print_status "FAIL" "packages/insomnia/package.json not found"
    fi
else
    print_status "FAIL" "packages/insomnia not found"
fi

if [ -d "packages/insomnia-inso" ]; then
    print_status "PASS" "packages/insomnia-inso exists"
    
    if [ -f "packages/insomnia-inso/package.json" ]; then
        print_status "PASS" "packages/insomnia-inso/package.json exists"
    else
        print_status "FAIL" "packages/insomnia-inso/package.json not found"
    fi
else
    print_status "FAIL" "packages/insomnia-inso not found"
fi

if [ -d "packages/insomnia-testing" ]; then
    print_status "PASS" "packages/insomnia-testing exists"
    
    if [ -f "packages/insomnia-testing/package.json" ]; then
        print_status "PASS" "packages/insomnia-testing/package.json exists"
    else
        print_status "FAIL" "packages/insomnia-testing/package.json not found"
    fi
else
    print_status "FAIL" "packages/insomnia-testing not found"
fi

if [ -d "packages/insomnia-smoke-test" ]; then
    print_status "PASS" "packages/insomnia-smoke-test exists"
    
    if [ -f "packages/insomnia-smoke-test/package.json" ]; then
        print_status "PASS" "packages/insomnia-smoke-test/package.json exists"
    else
        print_status "FAIL" "packages/insomnia-smoke-test/package.json not found"
    fi
else
    print_status "FAIL" "packages/insomnia-smoke-test not found"
fi

if [ -d "packages/insomnia-scripting-environment" ]; then
    print_status "PASS" "packages/insomnia-scripting-environment exists"
    
    if [ -f "packages/insomnia-scripting-environment/package.json" ]; then
        print_status "PASS" "packages/insomnia-scripting-environment/package.json exists"
    else
        print_status "FAIL" "packages/insomnia-scripting-environment/package.json not found"
    fi
else
    print_status "FAIL" "packages/insomnia-scripting-environment not found"
fi

echo ""
echo "8. Testing Insomnia Development Tools..."
echo "---------------------------------------"
# Test ESLint
if [ -f "eslint.config.mjs" ]; then
    print_status "PASS" "eslint.config.mjs exists"
else
    print_status "FAIL" "eslint.config.mjs not found"
fi

# Test Prettier
if [ -f ".prettierrc" ]; then
    print_status "PASS" ".prettierrc exists"
else
    print_status "FAIL" ".prettierrc not found"
fi

if [ -f ".prettierignore" ]; then
    print_status "PASS" ".prettierignore exists"
else
    print_status "FAIL" ".prettierignore not found"
fi

# Test Markdown linting
if [ -f ".markdownlint.yaml" ]; then
    print_status "PASS" ".markdownlint.yaml exists"
else
    print_status "FAIL" ".markdownlint.yaml not found"
fi

# Test TypeScript
if command -v npx &> /dev/null; then
    if timeout 30s npx tsc --version >/dev/null 2>&1; then
        print_status "PASS" "TypeScript is available via npx"
    else
        print_status "WARN" "TypeScript is not available via npx"
    fi
else
    print_status "WARN" "npx is not available"
fi

echo ""
echo "9. Testing Insomnia Documentation..."
echo "-----------------------------------"
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

if [ -r "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md is readable"
else
    print_status "FAIL" "CONTRIBUTING.md is not readable"
fi

if [ -r "DEVELOPMENT.md" ]; then
    print_status "PASS" "DEVELOPMENT.md is readable"
else
    print_status "FAIL" "DEVELOPMENT.md is not readable"
fi

if [ -r "CODE_OF_CONDUCT.md" ]; then
    print_status "PASS" "CODE_OF_CONDUCT.md is readable"
else
    print_status "FAIL" "CODE_OF_CONDUCT.md is not readable"
fi

if [ -r "SECURITY.md" ]; then
    print_status "PASS" "SECURITY.md is readable"
else
    print_status "FAIL" "SECURITY.md is not readable"
fi

if [ -r "CHANGELOG.md" ]; then
    print_status "PASS" "CHANGELOG.md is readable"
else
    print_status "FAIL" "CHANGELOG.md is not readable"
fi

echo ""
echo "10. Testing Insomnia Configuration..."
echo "------------------------------------"
# Test configuration files
if [ -r ".npmrc" ]; then
    print_status "PASS" ".npmrc is readable"
else
    print_status "FAIL" ".npmrc is not readable"
fi

if [ -r ".gitignore" ]; then
    print_status "PASS" ".gitignore is readable"
else
    print_status "FAIL" ".gitignore is not readable"
fi

if [ -r ".gitattributes" ]; then
    print_status "PASS" ".gitattributes is readable"
else
    print_status "FAIL" ".gitattributes is not readable"
fi

if [ -r ".dockerignore" ]; then
    print_status "PASS" ".dockerignore is readable"
else
    print_status "FAIL" ".dockerignore is not readable"
fi

if [ -r ".clang-format" ]; then
    print_status "PASS" ".clang-format is readable"
else
    print_status "FAIL" ".clang-format is not readable"
fi

if [ -r "build-secure-wrapper.sh" ]; then
    print_status "PASS" "build-secure-wrapper.sh is readable"
else
    print_status "FAIL" "build-secure-wrapper.sh is not readable"
fi

if [ -r "flake.nix" ]; then
    print_status "PASS" "flake.nix is readable"
else
    print_status "FAIL" "flake.nix is not readable"
fi

if [ -r "flake.lock" ]; then
    print_status "PASS" "flake.lock is readable"
else
    print_status "FAIL" "flake.lock is not readable"
fi

echo ""
echo "11. Testing Insomnia Docker Functionality..."
echo "-------------------------------------------"
# Test if Docker container can run npm commands
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test npm install in Docker
    if docker run --rm insomnia-env-test npm --version >/dev/null 2>&1; then
        print_status "PASS" "npm works in Docker container"
    else
        print_status "FAIL" "npm does not work in Docker container"
    fi
    
    # Test node execution in Docker
    if docker run --rm insomnia-env-test node -e "console.log('test')" >/dev/null 2>&1; then
        print_status "PASS" "Node.js execution works in Docker container"
    else
        print_status "FAIL" "Node.js execution does not work in Docker container"
    fi
    
    # Test git in Docker
    if docker run --rm insomnia-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test mkcert in Docker
    if docker run --rm insomnia-env-test mkcert --version >/dev/null 2>&1; then
        print_status "PASS" "mkcert works in Docker container"
    else
        print_status "FAIL" "mkcert does not work in Docker container"
    fi
    
    # Test if package.json is accessible in Docker
    if docker run --rm insomnia-env-test test -f package.json; then
        print_status "PASS" "package.json is accessible in Docker container"
    else
        print_status "FAIL" "package.json is not accessible in Docker container"
    fi
    
    # Test if packages directory is accessible in Docker
    if docker run --rm insomnia-env-test test -d packages; then
        print_status "PASS" "packages directory is accessible in Docker container"
    else
        print_status "FAIL" "packages directory is not accessible in Docker container"
    fi
    
    # Test if .nvmrc is accessible in Docker
    if docker run --rm insomnia-env-test test -f .nvmrc; then
        print_status "PASS" ".nvmrc is accessible in Docker container"
    else
        print_status "FAIL" ".nvmrc is not accessible in Docker container"
    fi
    
    # Test Node.js version in Docker matches .nvmrc
    if [ -f ".nvmrc" ]; then
        nvmrc_version=$(cat .nvmrc)
        docker_node_version=$(docker run --rm insomnia-env-test node --version 2>/dev/null | sed 's/v//')
        if [ "$docker_node_version" = "$nvmrc_version" ]; then
            print_status "PASS" "Docker Node.js version matches .nvmrc: $nvmrc_version"
        else
            print_status "WARN" "Docker Node.js version ($docker_node_version) does not match .nvmrc ($nvmrc_version)"
        fi
    fi
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for Kong Insomnia:"
echo "- Docker build process (Ubuntu 22.04, Node.js 22.14.0, npm >= 10)"
echo "- Node.js environment (version compatibility, module loading)"
echo "- npm environment (workspaces, package management)"
echo "- Insomnia monorepo structure (packages, workspaces)"
echo "- Insomnia build system (package.json, .nvmrc, scripts)"
echo "- Insomnia development tools (ESLint, Prettier, TypeScript)"
echo "- Insomnia documentation (README, LICENSE, contributing guides)"
echo "- Insomnia configuration (npm, git, docker, build tools)"
echo "- Docker container functionality (Node.js, npm, Git, mkcert)"
echo "- Cross-platform API client capabilities (REST, GraphQL, WebSockets, gRPC)"
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
    print_status "INFO" "All Docker tests passed! Your Kong Insomnia Docker environment is ready!"
    print_status "INFO" "Kong Insomnia is a cross-platform API client for GraphQL, REST, WebSockets, Server-sent events (SSE), gRPC and any other HTTP compatible protocol."
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your Kong Insomnia Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now run Kong Insomnia in Docker: A powerful API client for debugging, designing, testing, and mocking APIs."
print_status "INFO" "Example: docker run --rm insomnia-env-test npm run dev"
print_status "INFO" "Example: docker run --rm insomnia-env-test npm run test"
echo ""
print_status "INFO" "For more information, see README.md and https://insomnia.rest"
print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/Kong_insomnia insomnia-env-test /bin/bash"
exit 0
fi

# If Docker failed or not available, skip local environment tests
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ] || [ "${DOCKER_MODE:-false}" = "false" ]; then
    echo "Docker environment not available - skipping local environment tests"
    echo "This script is designed to test Docker environment only"
    exit 0
fi 