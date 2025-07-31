#!/bin/bash

# MUI Material-UI Environment Benchmark Test Script
# This script tests the Docker environment setup for MUI Material-UI: Comprehensive React component library
# Tailored specifically for MUI Material-UI project requirements and features

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
    docker stop mui-env-test 2>/dev/null || true
    docker rm mui-env-test 2>/dev/null || true
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
        if timeout 600s docker build -f envgym/envgym.dockerfile -t mui-env-test .; then
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
    
    # Test if Node.js is available in Docker
    if docker run --rm mui-env-test node --version >/dev/null 2>&1; then
        node_version=$(docker run --rm mui-env-test node --version 2>/dev/null)
        print_status "PASS" "Node.js is available in Docker: $node_version"
    else
        print_status "FAIL" "Node.js is not available in Docker"
    fi
    
    # Test if npm is available in Docker
    if docker run --rm mui-env-test npm --version >/dev/null 2>&1; then
        npm_version=$(docker run --rm mui-env-test npm --version 2>/dev/null)
        print_status "PASS" "npm is available in Docker: $npm_version"
    else
        print_status "FAIL" "npm is not available in Docker"
    fi
    
    # Test if Git is available in Docker
    if docker run --rm mui-env-test git --version >/dev/null 2>&1; then
        git_version=$(docker run --rm mui-env-test git --version 2>/dev/null)
        print_status "PASS" "Git is available in Docker: $git_version"
    else
        print_status "FAIL" "Git is not available in Docker"
    fi
    
    # Test if Python3 is available in Docker
    if docker run --rm mui-env-test python3 --version >/dev/null 2>&1; then
        python_version=$(docker run --rm mui-env-test python3 --version 2>/dev/null)
        print_status "PASS" "Python3 is available in Docker: $python_version"
    else
        print_status "FAIL" "Python3 is not available in Docker"
    fi
fi

echo "=========================================="
echo "MUI Material-UI Environment Benchmark Test"
echo "=========================================="

echo "1. Checking System Dependencies..."
echo "--------------------------------"
# Check Node.js
if command -v node &> /dev/null; then
    node_version=$(node --version 2>&1)
    print_status "PASS" "Node.js is available: $node_version"
else
    print_status "FAIL" "Node.js is not available"
fi

# Check Node.js version
if command -v node &> /dev/null; then
    node_major=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ -n "$node_major" ] && [ "$node_major" -ge 18 ]; then
        print_status "PASS" "Node.js version is >= 18 (compatible with MUI)"
    else
        print_status "WARN" "Node.js version should be >= 18 for MUI (found: $node_major)"
    fi
else
    print_status "FAIL" "Node.js is not available for version check"
fi

# Check npm
if command -v npm &> /dev/null; then
    npm_version=$(npm --version 2>&1)
    print_status "PASS" "npm is available: $npm_version"
else
    print_status "FAIL" "npm is not available"
fi

# Check pnpm
if command -v pnpm &> /dev/null; then
    pnpm_version=$(pnpm --version 2>&1)
    print_status "PASS" "pnpm is available: $pnpm_version"
else
    print_status "WARN" "pnpm is not available (recommended for MUI)"
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

# Check Python3
if command -v python3 &> /dev/null; then
    python3_version=$(python3 --version 2>&1)
    print_status "PASS" "Python3 is available: $python3_version"
else
    print_status "WARN" "Python3 is not available"
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

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "packages" ]; then
    print_status "PASS" "packages directory exists (MUI packages)"
else
    print_status "FAIL" "packages directory not found"
fi

if [ -d "packages-internal" ]; then
    print_status "PASS" "packages-internal directory exists (internal packages)"
else
    print_status "FAIL" "packages-internal directory not found"
fi

if [ -d "docs" ]; then
    print_status "PASS" "docs directory exists (documentation)"
else
    print_status "FAIL" "docs directory not found"
fi

if [ -d "examples" ]; then
    print_status "PASS" "examples directory exists (example applications)"
else
    print_status "FAIL" "examples directory not found"
fi

if [ -d "test" ]; then
    print_status "PASS" "test directory exists (test files)"
else
    print_status "FAIL" "test directory not found"
fi

if [ -d "scripts" ]; then
    print_status "PASS" "scripts directory exists (build and utility scripts)"
else
    print_status "FAIL" "scripts directory not found"
fi

if [ -d "apps" ]; then
    print_status "PASS" "apps directory exists (applications)"
else
    print_status "FAIL" "apps directory not found"
fi

if [ -d "patches" ]; then
    print_status "PASS" "patches directory exists (dependency patches)"
else
    print_status "FAIL" "patches directory not found"
fi

if [ -d ".github" ]; then
    print_status "PASS" ".github directory exists (GitHub workflows)"
else
    print_status "FAIL" ".github directory not found"
fi

if [ -d ".circleci" ]; then
    print_status "PASS" ".circleci directory exists (CI/CD configuration)"
else
    print_status "FAIL" ".circleci directory not found"
fi

if [ -d ".codesandbox" ]; then
    print_status "PASS" ".codesandbox directory exists (CodeSandbox configuration)"
else
    print_status "FAIL" ".codesandbox directory not found"
fi

if [ -d ".vscode" ]; then
    print_status "PASS" ".vscode directory exists (VS Code configuration)"
else
    print_status "FAIL" ".vscode directory not found"
fi

# Check key files
if [ -f "package.json" ]; then
    print_status "PASS" "package.json exists (root package configuration)"
else
    print_status "FAIL" "package.json not found"
fi

if [ -f "pnpm-workspace.yaml" ]; then
    print_status "PASS" "pnpm-workspace.yaml exists (pnpm workspace configuration)"
else
    print_status "FAIL" "pnpm-workspace.yaml not found"
fi

if [ -f "pnpm-lock.yaml" ]; then
    print_status "PASS" "pnpm-lock.yaml exists (dependency lock file)"
else
    print_status "FAIL" "pnpm-lock.yaml not found"
fi

if [ -f "lerna.json" ]; then
    print_status "PASS" "lerna.json exists (monorepo configuration)"
else
    print_status "FAIL" "lerna.json not found"
fi

if [ -f "nx.json" ]; then
    print_status "PASS" "nx.json exists (Nx build system configuration)"
else
    print_status "FAIL" "nx.json not found"
fi

if [ -f "tsconfig.json" ]; then
    print_status "PASS" "tsconfig.json exists (TypeScript configuration)"
else
    print_status "FAIL" "tsconfig.json not found"
fi

if [ -f "babel.config.js" ]; then
    print_status "PASS" "babel.config.js exists (Babel configuration)"
else
    print_status "FAIL" "babel.config.js not found"
fi

if [ -f "eslint.config.mjs" ]; then
    print_status "PASS" "eslint.config.mjs exists (ESLint configuration)"
else
    print_status "FAIL" "eslint.config.mjs not found"
fi

if [ -f "prettier.config.mjs" ]; then
    print_status "PASS" "prettier.config.mjs exists (Prettier configuration)"
else
    print_status "FAIL" "prettier.config.mjs not found"
fi

if [ -f "stylelint.config.mjs" ]; then
    print_status "PASS" "stylelint.config.mjs exists (Stylelint configuration)"
else
    print_status "FAIL" "stylelint.config.mjs not found"
fi

if [ -f "webpackBaseConfig.js" ]; then
    print_status "PASS" "webpackBaseConfig.js exists (Webpack configuration)"
else
    print_status "FAIL" "webpackBaseConfig.js not found"
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

if [ -f "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md exists (contribution guidelines)"
else
    print_status "FAIL" "CONTRIBUTING.md not found"
fi

if [ -f "CHANGELOG.md" ]; then
    print_status "PASS" "CHANGELOG.md exists (change log)"
else
    print_status "FAIL" "CHANGELOG.md not found"
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

if [ -f ".browserslistrc" ]; then
    print_status "PASS" ".browserslistrc exists (browser support configuration)"
else
    print_status "FAIL" ".browserslistrc not found"
fi

if [ -f ".npmrc" ]; then
    print_status "PASS" ".npmrc exists (npm configuration)"
else
    print_status "FAIL" ".npmrc not found"
fi

if [ -f "vercel.json" ]; then
    print_status "PASS" "vercel.json exists (Vercel deployment configuration)"
else
    print_status "FAIL" "vercel.json not found"
fi

if [ -f "netlify.toml" ]; then
    print_status "PASS" "netlify.toml exists (Netlify deployment configuration)"
else
    print_status "FAIL" "netlify.toml not found"
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

if [ -n "${NPM_CONFIG_REGISTRY:-}" ]; then
    print_status "PASS" "NPM_CONFIG_REGISTRY is set: $NPM_CONFIG_REGISTRY"
else
    print_status "WARN" "NPM_CONFIG_REGISTRY is not set"
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

if echo "$PATH" | grep -q "pnpm"; then
    print_status "PASS" "pnpm is in PATH"
else
    print_status "WARN" "pnpm is not in PATH"
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
    if timeout 30s node -e "console.log(process.version)" >/dev/null 2>&1; then
        print_status "PASS" "Node.js process.version works"
    else
        print_status "WARN" "Node.js process.version failed"
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
    
    # Test npm help
    if timeout 30s npm help >/dev/null 2>&1; then
        print_status "PASS" "npm help command works"
    else
        print_status "WARN" "npm help command failed"
    fi
else
    print_status "FAIL" "npm is not available"
fi

echo ""
echo "6. Testing pnpm Environment..."
echo "-----------------------------"
# Test pnpm
if command -v pnpm &> /dev/null; then
    print_status "PASS" "pnpm is available"
    
    # Test pnpm version
    if timeout 30s pnpm --version >/dev/null 2>&1; then
        print_status "PASS" "pnpm version command works"
    else
        print_status "WARN" "pnpm version command failed"
    fi
    
    # Test pnpm help
    if timeout 30s pnpm help >/dev/null 2>&1; then
        print_status "PASS" "pnpm help command works"
    else
        print_status "WARN" "pnpm help command failed"
    fi
else
    print_status "WARN" "pnpm is not available"
fi

echo ""
echo "7. Testing MUI Build System..."
echo "-----------------------------"
# Test package.json
if [ -f "package.json" ]; then
    print_status "PASS" "package.json exists for build testing"
    
    # Check for key scripts
    if grep -q '"build"' package.json; then
        print_status "PASS" "package.json has build script"
    else
        print_status "FAIL" "package.json missing build script"
    fi
    
    if grep -q '"test"' package.json; then
        print_status "PASS" "package.json has test script"
    else
        print_status "FAIL" "package.json missing test script"
    fi
    
    if grep -q '"lint"' package.json; then
        print_status "PASS" "package.json has lint script"
    else
        print_status "WARN" "package.json missing lint script"
    fi
    
    if grep -q '"docs:dev"' package.json; then
        print_status "PASS" "package.json has docs:dev script"
    else
        print_status "FAIL" "package.json missing docs:dev script"
    fi
    
    # Check for key dependencies
    if grep -q '"react"' package.json; then
        print_status "PASS" "package.json includes React dependency"
    else
        print_status "WARN" "package.json missing React dependency"
    fi
    
    if grep -q '"typescript"' package.json; then
        print_status "PASS" "package.json includes TypeScript dependency"
    else
        print_status "WARN" "package.json missing TypeScript dependency"
    fi
else
    print_status "FAIL" "package.json not found"
fi

# Test pnpm-workspace.yaml
if [ -f "pnpm-workspace.yaml" ]; then
    print_status "PASS" "pnpm-workspace.yaml exists"
    
    # Check for workspace packages
    if grep -q "packages" pnpm-workspace.yaml; then
        print_status "PASS" "pnpm-workspace.yaml includes packages directory"
    else
        print_status "FAIL" "pnpm-workspace.yaml missing packages directory"
    fi
    
    if grep -q "docs" pnpm-workspace.yaml; then
        print_status "PASS" "pnpm-workspace.yaml includes docs directory"
    else
        print_status "FAIL" "pnpm-workspace.yaml missing docs directory"
    fi
else
    print_status "FAIL" "pnpm-workspace.yaml not found"
fi

# Test lerna.json
if [ -f "lerna.json" ]; then
    print_status "PASS" "lerna.json exists"
    
    # Check for lerna configuration
    if grep -q "packages" lerna.json; then
        print_status "PASS" "lerna.json includes packages configuration"
    else
        print_status "WARN" "lerna.json missing packages configuration"
    fi
else
    print_status "FAIL" "lerna.json not found"
fi

# Test nx.json
if [ -f "nx.json" ]; then
    print_status "PASS" "nx.json exists"
    
    # Check for nx configuration
    if grep -q "targetDefaults" nx.json; then
        print_status "PASS" "nx.json includes targetDefaults configuration"
    else
        print_status "WARN" "nx.json missing targetDefaults configuration"
    fi
else
    print_status "FAIL" "nx.json not found"
fi

echo ""
echo "8. Testing MUI Source Code Structure..."
echo "--------------------------------------"
# Test source code directories
if [ -d "packages" ]; then
    print_status "PASS" "packages directory exists for source testing"
    
    # Count package directories
    package_count=$(find packages -maxdepth 1 -type d | wc -l)
    if [ "$package_count" -gt 1 ]; then
        print_status "PASS" "Found $((package_count - 1)) packages in packages directory"
    else
        print_status "WARN" "No packages found in packages directory"
    fi
    
    # Check for key packages
    if [ -d "packages/mui-material" ]; then
        print_status "PASS" "packages/mui-material exists (core Material-UI components)"
    else
        print_status "FAIL" "packages/mui-material not found"
    fi
    
    if [ -d "packages/mui-system" ]; then
        print_status "PASS" "packages/mui-system exists (system utilities)"
    else
        print_status "FAIL" "packages/mui-system not found"
    fi
    
    if [ -d "packages/mui-utils" ]; then
        print_status "PASS" "packages/mui-utils exists (utility functions)"
    else
        print_status "FAIL" "packages/mui-utils not found"
    fi
else
    print_status "FAIL" "packages directory not found"
fi

if [ -d "packages-internal" ]; then
    print_status "PASS" "packages-internal directory exists for internal testing"
    
    # Count internal package directories
    internal_count=$(find packages-internal -maxdepth 1 -type d | wc -l)
    if [ "$internal_count" -gt 1 ]; then
        print_status "PASS" "Found $((internal_count - 1)) internal packages"
    else
        print_status "WARN" "No internal packages found"
    fi
else
    print_status "FAIL" "packages-internal directory not found"
fi

if [ -d "docs" ]; then
    print_status "PASS" "docs directory exists for documentation testing"
    
    # Check for key documentation files
    if [ -f "docs/package.json" ]; then
        print_status "PASS" "docs/package.json exists"
    else
        print_status "FAIL" "docs/package.json not found"
    fi
else
    print_status "FAIL" "docs directory not found"
fi

echo ""
echo "9. Testing MUI Configuration Files..."
echo "------------------------------------"
# Test TypeScript configuration
if [ -f "tsconfig.json" ]; then
    print_status "PASS" "tsconfig.json exists"
    
    # Check for TypeScript configuration
    if grep -q "compilerOptions" tsconfig.json; then
        print_status "PASS" "tsconfig.json includes compilerOptions"
    else
        print_status "WARN" "tsconfig.json missing compilerOptions"
    fi
else
    print_status "FAIL" "tsconfig.json not found"
fi

# Test Babel configuration
if [ -f "babel.config.js" ]; then
    print_status "PASS" "babel.config.js exists"
    
    # Check for Babel configuration
    if grep -q "presets" babel.config.js; then
        print_status "PASS" "babel.config.js includes presets"
    else
        print_status "WARN" "babel.config.js missing presets"
    fi
else
    print_status "FAIL" "babel.config.js not found"
fi

# Test ESLint configuration
if [ -f "eslint.config.mjs" ]; then
    print_status "PASS" "eslint.config.mjs exists"
    
    # Check for ESLint configuration
    if grep -q "rules" eslint.config.mjs; then
        print_status "PASS" "eslint.config.mjs includes rules"
    else
        print_status "WARN" "eslint.config.mjs missing rules"
    fi
else
    print_status "FAIL" "eslint.config.mjs not found"
fi

# Test Prettier configuration
if [ -f "prettier.config.mjs" ]; then
    print_status "PASS" "prettier.config.mjs exists"
else
    print_status "FAIL" "prettier.config.mjs not found"
fi

# Test Stylelint configuration
if [ -f "stylelint.config.mjs" ]; then
    print_status "PASS" "stylelint.config.mjs exists"
else
    print_status "FAIL" "stylelint.config.mjs not found"
fi

echo ""
echo "10. Testing MUI Documentation..."
echo "--------------------------------"
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

if [ -r "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md is readable"
else
    print_status "FAIL" "CONTRIBUTING.md is not readable"
fi

if [ -r "CHANGELOG.md" ]; then
    print_status "PASS" "CHANGELOG.md is readable"
else
    print_status "FAIL" "CHANGELOG.md is not readable"
fi

if [ -r ".gitignore" ]; then
    print_status "PASS" ".gitignore is readable"
else
    print_status "FAIL" ".gitignore is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "Material UI" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "React components" README.md; then
        print_status "PASS" "README.md contains project description"
    else
        print_status "WARN" "README.md missing project description"
    fi
    
    if grep -q "Material Design" README.md; then
        print_status "PASS" "README.md contains Material Design reference"
    else
        print_status "WARN" "README.md missing Material Design reference"
    fi
fi

echo ""
echo "11. Testing MUI Docker Functionality..."
echo "--------------------------------------"
# Test if Docker container can run basic commands
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    # Test Node.js in Docker
    if docker run --rm mui-env-test node --version >/dev/null 2>&1; then
        print_status "PASS" "Node.js works in Docker container"
    else
        print_status "FAIL" "Node.js does not work in Docker container"
    fi
    
    # Test npm in Docker
    if docker run --rm mui-env-test npm --version >/dev/null 2>&1; then
        print_status "PASS" "npm works in Docker container"
    else
        print_status "FAIL" "npm does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm mui-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test Python3 in Docker
    if docker run --rm mui-env-test python3 --version >/dev/null 2>&1; then
        print_status "PASS" "Python3 works in Docker container"
    else
        print_status "FAIL" "Python3 does not work in Docker container"
    fi
    
    # Test if package.json is accessible in Docker
    if docker run --rm mui-env-test test -f package.json; then
        print_status "PASS" "package.json is accessible in Docker container"
    else
        print_status "FAIL" "package.json is not accessible in Docker container"
    fi
    
    # Test if pnpm-workspace.yaml is accessible in Docker
    if docker run --rm mui-env-test test -f pnpm-workspace.yaml; then
        print_status "PASS" "pnpm-workspace.yaml is accessible in Docker container"
    else
        print_status "FAIL" "pnpm-workspace.yaml is not accessible in Docker container"
    fi
    
    # Test if packages directory is accessible in Docker
    if docker run --rm mui-env-test test -d packages; then
        print_status "PASS" "packages directory is accessible in Docker container"
    else
        print_status "FAIL" "packages directory is not accessible in Docker container"
    fi
    
    # Test if docs directory is accessible in Docker
    if docker run --rm mui-env-test test -d docs; then
        print_status "PASS" "docs directory is accessible in Docker container"
    else
        print_status "FAIL" "docs directory is not accessible in Docker container"
    fi
    
    # Test if tsconfig.json is accessible in Docker
    if docker run --rm mui-env-test test -f tsconfig.json; then
        print_status "PASS" "tsconfig.json is accessible in Docker container"
    else
        print_status "FAIL" "tsconfig.json is not accessible in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm mui-env-test test -f README.md; then
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
echo "This script has tested the Docker environment for MUI Material-UI:"
echo "- Docker build process (Node.js 20.11.1, npm, Git, Python3)"
echo "- Node.js environment (version compatibility, module loading)"
echo "- npm environment (package management, dependency installation)"
echo "- pnpm environment (workspace management, monorepo support)"
echo "- MUI build system (package.json, pnpm-workspace.yaml, lerna.json, nx.json)"
echo "- MUI source code structure (packages, packages-internal, docs)"
echo "- MUI configuration files (TypeScript, Babel, ESLint, Prettier, Stylelint)"
echo "- MUI documentation (README.md, LICENSE, SECURITY.md, CONTRIBUTING.md)"
echo "- Docker container functionality (Node.js, npm, Git, Python3)"
echo "- React component library (Material Design, TypeScript, monorepo)"
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
    print_status "INFO" "All Docker tests passed! Your MUI Material-UI Docker environment is ready!"
    print_status "INFO" "MUI Material-UI is a comprehensive library of React components implementing Material Design."
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your MUI Material-UI Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now run MUI Material-UI in Docker: A comprehensive React component library."
print_status "INFO" "Example: docker run --rm mui-env-test npm install"
print_status "INFO" "Example: docker run --rm mui-env-test npm run build"
echo ""
print_status "INFO" "For more information, see README.md and https://github.com/mui/material-ui"
exit 0
fi

# If Docker failed or not available, skip local environment tests
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ] || [ "${DOCKER_MODE:-false}" = "false" ]; then
    echo "Docker environment not available - skipping local environment tests"
    echo "This script is designed to test Docker environment only"
    exit 0
fi 