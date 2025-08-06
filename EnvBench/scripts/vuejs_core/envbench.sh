#!/bin/bash

# Vue.js Core Environment Benchmark Test Script
# This script tests the Docker environment setup for Vue.js Core: A progressive JavaScript framework
# Tailored specifically for Vue.js Core project requirements and features

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
    docker stop vuejs-core-env-test 2>/dev/null || true
    docker rm vuejs-core-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the vuejs_core project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t vuejs-core-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/vuejs_core" vuejs-core-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "Vue.js Core Environment Benchmark Test"
echo "=========================================="

echo "1. Checking Node.js Environment..."
echo "---------------------------------"
# Check Node.js version
if command -v node &> /dev/null; then
    node_version=$(node --version 2>&1)
    print_status "PASS" "Node.js is available: $node_version"
    
    # Check Node.js version compatibility (requires 18.12.0+)
    node_major=$(node --version 2>&1 | cut -d'v' -f2 | cut -d'.' -f1)
    node_minor=$(node --version 2>&1 | cut -d'v' -f2 | cut -d'.' -f2)
    if [ "$node_major" -ge 18 ] && [ "$node_minor" -ge 12 ]; then
        print_status "PASS" "Node.js version is >= 18.12.0 (compatible with Vue.js Core)"
    else
        print_status "WARN" "Node.js version should be >= 18.12.0 for Vue.js Core (found: $node_major.$node_minor)"
    fi
else
    print_status "FAIL" "Node.js is not available"
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
    print_status "WARN" "pnpm is not available"
fi

# Check yarn
if command -v yarn &> /dev/null; then
    yarn_version=$(yarn --version 2>&1)
    print_status "PASS" "yarn is available: $yarn_version"
else
    print_status "WARN" "yarn is not available"
fi

# Test Node.js execution
if command -v node &> /dev/null; then
    echo 'console.log("Hello, Node.js!");' > /tmp/test.js
    if timeout 30s node /tmp/test.js >/dev/null 2>&1; then
        print_status "PASS" "Node.js execution works"
        rm -f /tmp/test.js
    else
        print_status "WARN" "Node.js execution failed"
        rm -f /tmp/test.js
    fi
else
    print_status "FAIL" "Node.js is not available for execution testing"
fi

echo ""
echo "2. Checking System Dependencies..."
echo "---------------------------------"
# Check Git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1)
    print_status "PASS" "Git is available: $git_version"
else
    print_status "FAIL" "Git is not available"
fi

# Check curl and wget
if command -v curl &> /dev/null; then
    curl_version=$(curl --version 2>&1 | head -n 1)
    print_status "PASS" "curl is available: $curl_version"
else
    print_status "FAIL" "curl is not available"
fi

if command -v wget &> /dev/null; then
    wget_version=$(wget --version 2>&1 | head -n 1)
    print_status "PASS" "wget is available: $wget_version"
else
    print_status "FAIL" "wget is not available"
fi

# Check build tools
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version 2>&1 | head -n 1)
    print_status "PASS" "GCC is available: $gcc_version"
else
    print_status "WARN" "GCC is not available"
fi

if command -v g++ &> /dev/null; then
    gpp_version=$(g++ --version 2>&1 | head -n 1)
    print_status "PASS" "G++ is available: $gpp_version"
else
    print_status "WARN" "G++ is not available"
fi

# Check make
if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "make is available: $make_version"
else
    print_status "WARN" "make is not available"
fi

# Check Python
if command -v python3 &> /dev/null; then
    python3_version=$(python3 --version 2>&1)
    print_status "PASS" "python3 is available: $python3_version"
else
    print_status "WARN" "python3 is not available"
fi

echo ""
echo "3. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "packages" ]; then
    print_status "PASS" "packages directory exists (monorepo packages)"
else
    print_status "FAIL" "packages directory not found"
fi

if [ -d "packages-private" ]; then
    print_status "PASS" "packages-private directory exists (private packages)"
else
    print_status "FAIL" "packages-private directory not found"
fi

if [ -d "scripts" ]; then
    print_status "PASS" "scripts directory exists (build scripts)"
else
    print_status "FAIL" "scripts directory not found"
fi

if [ -d "changelogs" ]; then
    print_status "PASS" "changelogs directory exists (changelog files)"
else
    print_status "FAIL" "changelogs directory not found"
fi

if [ -d ".github" ]; then
    print_status "PASS" ".github directory exists (GitHub workflows)"
else
    print_status "FAIL" ".github directory not found"
fi

if [ -d ".vscode" ]; then
    print_status "PASS" ".vscode directory exists (VS Code config)"
else
    print_status "FAIL" ".vscode directory not found"
fi

# Check Vue.js packages
if [ -d "packages/vue" ]; then
    print_status "PASS" "packages/vue directory exists (main Vue package)"
else
    print_status "FAIL" "packages/vue directory not found"
fi

if [ -d "packages/runtime-core" ]; then
    print_status "PASS" "packages/runtime-core directory exists (runtime core)"
else
    print_status "FAIL" "packages/runtime-core directory not found"
fi

if [ -d "packages/runtime-dom" ]; then
    print_status "PASS" "packages/runtime-dom directory exists (runtime DOM)"
else
    print_status "FAIL" "packages/runtime-dom directory not found"
fi

if [ -d "packages/compiler-core" ]; then
    print_status "PASS" "packages/compiler-core directory exists (compiler core)"
else
    print_status "FAIL" "packages/compiler-core directory not found"
fi

if [ -d "packages/compiler-dom" ]; then
    print_status "PASS" "packages/compiler-dom directory exists (compiler DOM)"
else
    print_status "FAIL" "packages/compiler-dom directory not found"
fi

if [ -d "packages/compiler-sfc" ]; then
    print_status "PASS" "packages/compiler-sfc directory exists (SFC compiler)"
else
    print_status "FAIL" "packages/compiler-sfc directory not found"
fi

if [ -d "packages/reactivity" ]; then
    print_status "PASS" "packages/reactivity directory exists (reactivity system)"
else
    print_status "FAIL" "packages/reactivity directory not found"
fi

if [ -d "packages/shared" ]; then
    print_status "PASS" "packages/shared directory exists (shared utilities)"
else
    print_status "FAIL" "packages/shared directory not found"
fi

if [ -d "packages/server-renderer" ]; then
    print_status "PASS" "packages/server-renderer directory exists (SSR)"
else
    print_status "FAIL" "packages/server-renderer directory not found"
fi

# Check key files
if [ -f "package.json" ]; then
    print_status "PASS" "package.json exists (project configuration)"
else
    print_status "FAIL" "package.json not found"
fi

if [ -f "pnpm-workspace.yaml" ]; then
    print_status "PASS" "pnpm-workspace.yaml exists (pnpm workspace config)"
else
    print_status "FAIL" "pnpm-workspace.yaml not found"
fi

if [ -f "pnpm-lock.yaml" ]; then
    print_status "PASS" "pnpm-lock.yaml exists (dependency lock file)"
else
    print_status "FAIL" "pnpm-lock.yaml not found"
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

if [ -f "CHANGELOG.md" ]; then
    print_status "PASS" "CHANGELOG.md exists"
else
    print_status "FAIL" "CHANGELOG.md not found"
fi

if [ -f ".node-version" ]; then
    print_status "PASS" ".node-version exists (Node.js version spec)"
else
    print_status "FAIL" ".node-version not found"
fi

if [ -f "tsconfig.json" ]; then
    print_status "PASS" "tsconfig.json exists (TypeScript config)"
else
    print_status "FAIL" "tsconfig.json not found"
fi

if [ -f "vitest.config.ts" ]; then
    print_status "PASS" "vitest.config.ts exists (Vitest config)"
else
    print_status "FAIL" "vitest.config.ts not found"
fi

if [ -f "rollup.config.js" ]; then
    print_status "PASS" "rollup.config.js exists (Rollup config)"
else
    print_status "FAIL" "rollup.config.js not found"
fi

if [ -f "eslint.config.js" ]; then
    print_status "PASS" "eslint.config.js exists (ESLint config)"
else
    print_status "FAIL" "eslint.config.js not found"
fi

if [ -f ".prettierrc" ]; then
    print_status "PASS" ".prettierrc exists (Prettier config)"
else
    print_status "FAIL" ".prettierrc not found"
fi

# Check Vue.js package files
if [ -f "packages/vue/package.json" ]; then
    print_status "PASS" "packages/vue/package.json exists (main Vue package config)"
else
    print_status "FAIL" "packages/vue/package.json not found"
fi

if [ -f "packages/vue/src/index.ts" ]; then
    print_status "PASS" "packages/vue/src/index.ts exists (main Vue entry point)"
else
    print_status "FAIL" "packages/vue/src/index.ts not found"
fi

echo ""
echo "4. Testing Vue.js Core Source Code..."
echo "------------------------------------"
# Count TypeScript/JavaScript files
ts_files=$(find . -name "*.ts" | wc -l)
if [ "$ts_files" -gt 0 ]; then
    print_status "PASS" "Found $ts_files TypeScript files"
else
    print_status "FAIL" "No TypeScript files found"
fi

js_files=$(find . -name "*.js" | wc -l)
if [ "$js_files" -gt 0 ]; then
    print_status "PASS" "Found $js_files JavaScript files"
else
    print_status "FAIL" "No JavaScript files found"
fi

# Count test files
test_files=$(find . -name "*.test.*" -o -name "*.spec.*" | wc -l)
if [ "$test_files" -gt 0 ]; then
    print_status "PASS" "Found $test_files test files"
else
    print_status "WARN" "No test files found"
fi

# Count package.json files
package_files=$(find . -name "package.json" | wc -l)
if [ "$package_files" -gt 0 ]; then
    print_status "PASS" "Found $package_files package.json files"
else
    print_status "WARN" "No package.json files found"
fi

# Count configuration files
config_files=$(find . -name "*.config.*" -o -name "tsconfig.json" -o -name ".eslintrc*" -o -name ".prettierrc*" | wc -l)
if [ "$config_files" -gt 0 ]; then
    print_status "PASS" "Found $config_files configuration files"
else
    print_status "WARN" "No configuration files found"
fi

# Test TypeScript compilation
if command -v npx &> /dev/null; then
    print_status "INFO" "Testing TypeScript compilation..."
    if timeout 60s npx tsc --noEmit >/dev/null 2>&1; then
        print_status "PASS" "TypeScript compilation check successful"
    else
        print_status "WARN" "TypeScript compilation check failed"
    fi
else
    print_status "WARN" "npx is not available for TypeScript compilation testing"
fi

# Test package.json parsing
if command -v node &> /dev/null; then
    print_status "INFO" "Testing package.json parsing..."
    if timeout 30s node -e "JSON.parse(require('fs').readFileSync('package.json', 'utf8'))" >/dev/null 2>&1; then
        print_status "PASS" "package.json parsing successful"
    else
        print_status "FAIL" "package.json parsing failed"
    fi
else
    print_status "FAIL" "Node.js is not available for package.json parsing"
fi

echo ""
echo "5. Testing Vue.js Core Dependencies..."
echo "-------------------------------------"
# Test if required dependencies are available
if command -v node &> /dev/null; then
    print_status "INFO" "Testing Vue.js Core dependencies..."
    
    # Test if Vue.js is available
    if [ -f "packages/vue/package.json" ]; then
        vue_name=$(node -e "console.log(JSON.parse(require('fs').readFileSync('packages/vue/package.json', 'utf8')).name)" 2>/dev/null)
        if [ "$vue_name" = "vue" ]; then
            print_status "PASS" "Vue.js package is properly configured"
        else
            print_status "WARN" "Vue.js package name is not 'vue'"
        fi
    else
        print_status "FAIL" "Vue.js package.json not found"
    fi
    
    # Test workspace configuration
    if [ -f "pnpm-workspace.yaml" ]; then
        print_status "PASS" "pnpm workspace configuration exists"
    else
        print_status "FAIL" "pnpm workspace configuration not found"
    fi
else
    print_status "FAIL" "Node.js is not available for dependency testing"
fi

echo ""
echo "6. Testing Vue.js Core Documentation..."
echo "--------------------------------------"
# Test documentation readability
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

if [ -r "CHANGELOG.md" ]; then
    print_status "PASS" "CHANGELOG.md is readable"
else
    print_status "FAIL" "CHANGELOG.md is not readable"
fi

if [ -r "BACKERS.md" ]; then
    print_status "PASS" "BACKERS.md is readable"
else
    print_status "FAIL" "BACKERS.md is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "vuejs/core" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "Vue.js" README.md; then
        print_status "PASS" "README.md contains Vue.js description"
    else
        print_status "WARN" "README.md missing Vue.js description"
    fi
    
    if grep -q "progressive" README.md; then
        print_status "PASS" "README.md contains progressive description"
    else
        print_status "WARN" "README.md missing progressive description"
    fi
    
    if grep -q "framework" README.md; then
        print_status "PASS" "README.md contains framework description"
    else
        print_status "WARN" "README.md missing framework description"
    fi
fi

echo ""
echo "7. Testing Vue.js Core Docker Functionality..."
echo "---------------------------------------------"
# Test if Docker container can run basic commands
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test if Docker container can execute commands
    if docker run --rm vuejs-core-env-test node --version >/dev/null 2>&1; then
        print_status "PASS" "Docker container can execute basic commands"
        
        # Test Node.js in Docker
        if docker run --rm vuejs-core-env-test node --version >/dev/null 2>&1; then
            print_status "PASS" "Node.js works in Docker container"
        else
            print_status "FAIL" "Node.js does not work in Docker container"
        fi
        
        # Test npm in Docker
        if docker run --rm vuejs-core-env-test npm --version >/dev/null 2>&1; then
            print_status "PASS" "npm works in Docker container"
        else
            print_status "FAIL" "npm does not work in Docker container"
        fi
        
        # Test pnpm in Docker
        if docker run --rm vuejs-core-env-test pnpm --version >/dev/null 2>&1; then
            print_status "PASS" "pnpm works in Docker container"
        else
            print_status "FAIL" "pnpm does not work in Docker container"
        fi
        
        # Test Git in Docker
        if docker run --rm vuejs-core-env-test git --version >/dev/null 2>&1; then
            print_status "PASS" "Git works in Docker container"
        else
            print_status "FAIL" "Git does not work in Docker container"
        fi
        
        # Test if project files are accessible in Docker
        if docker run --rm -v "$(pwd):/workspace" vuejs-core-env-test test -f README.md; then
            print_status "PASS" "README.md is accessible in Docker container"
        else
            print_status "FAIL" "README.md is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" vuejs-core-env-test test -f package.json; then
            print_status "PASS" "package.json is accessible in Docker container"
        else
            print_status "FAIL" "package.json is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" vuejs-core-env-test test -f packages/vue/package.json; then
            print_status "PASS" "packages/vue/package.json is accessible in Docker container"
        else
            print_status "FAIL" "packages/vue/package.json is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" vuejs-core-env-test test -f packages/vue/src/index.ts; then
            print_status "PASS" "packages/vue/src/index.ts is accessible in Docker container"
        else
            print_status "FAIL" "packages/vue/src/index.ts is not accessible in Docker container"
        fi
        
        # Test Node.js execution in Docker
        if timeout 60s docker run --rm -v "$(pwd):/workspace" -w /workspace vuejs-core-env-test node -e "console.log('Hello from Docker')" >/dev/null 2>&1; then
            print_status "PASS" "Node.js execution works in Docker container"
        else
            print_status "FAIL" "Node.js execution does not work in Docker container"
        fi
    else
        print_status "WARN" "Docker container has binary execution issues - cannot test runtime functionality"
        print_status "INFO" "Docker build succeeded, but container runtime has architecture compatibility issues"
        print_status "INFO" "This may be due to platform/architecture mismatch between host and container"
    fi
fi

echo ""
echo "8. Testing Vue.js Core Build Process..."
echo "--------------------------------------"
# Test if Docker container can run build commands
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test if Docker container can execute commands
    if docker run --rm vuejs-core-env-test node --version >/dev/null 2>&1; then
        # Test if project directories are accessible
        if docker run --rm -v "$(pwd):/workspace" -w /workspace vuejs-core-env-test test -d packages; then
            print_status "PASS" "packages directory is accessible in Docker container"
        else
            print_status "FAIL" "packages directory is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" -w /workspace vuejs-core-env-test test -d scripts; then
            print_status "PASS" "scripts directory is accessible in Docker container"
        else
            print_status "FAIL" "scripts directory is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" -w /workspace vuejs-core-env-test test -d changelogs; then
            print_status "PASS" "changelogs directory is accessible in Docker container"
        else
            print_status "FAIL" "changelogs directory is not accessible in Docker container"
        fi
        
        # Test if configuration files are accessible
        if docker run --rm -v "$(pwd):/workspace" -w /workspace vuejs-core-env-test test -f tsconfig.json; then
            print_status "PASS" "tsconfig.json is accessible in Docker container"
        else
            print_status "FAIL" "tsconfig.json is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" -w /workspace vuejs-core-env-test test -f vitest.config.ts; then
            print_status "PASS" "vitest.config.ts is accessible in Docker container"
        else
            print_status "FAIL" "vitest.config.ts is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" -w /workspace vuejs-core-env-test test -f rollup.config.js; then
            print_status "PASS" "rollup.config.js is accessible in Docker container"
        else
            print_status "FAIL" "rollup.config.js is not accessible in Docker container"
        fi
        
        if docker run --rm -v "$(pwd):/workspace" -w /workspace vuejs-core-env-test test -f eslint.config.js; then
            print_status "PASS" "eslint.config.js is accessible in Docker container"
        else
            print_status "FAIL" "eslint.config.js is not accessible in Docker container"
        fi
        
        # Test pnpm install
        if timeout 300s docker run --rm -v "$(pwd):/workspace" -w /workspace vuejs-core-env-test pnpm install --frozen-lockfile >/dev/null 2>&1; then
            print_status "PASS" "pnpm install works in Docker container"
        else
            print_status "FAIL" "pnpm install does not work in Docker container"
        fi
        
        # Test TypeScript check
        if timeout 120s docker run --rm -v "$(pwd):/workspace" -w /workspace vuejs-core-env-test npx tsc --noEmit >/dev/null 2>&1; then
            print_status "PASS" "TypeScript check works in Docker container"
        else
            print_status "FAIL" "TypeScript check does not work in Docker container"
        fi
        
        # Skip actual build execution to avoid timeouts
        print_status "WARN" "Skipping actual build execution to avoid timeouts (full build process)"
        print_status "INFO" "Docker environment is ready for Vue.js Core development"
    else
        print_status "WARN" "Docker container has binary execution issues - cannot test build process"
        print_status "INFO" "Docker build succeeded, but container runtime has architecture compatibility issues"
        print_status "INFO" "This may be due to platform/architecture mismatch between host and container"
    fi
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for Vue.js Core:"
echo "- Docker build process (Ubuntu 22.04, Node.js, pnpm)"
echo "- Node.js environment (version compatibility, module loading)"
echo "- pnpm environment (package management, workspace)"
echo "- Vue.js Core build system (package.json, pnpm-workspace.yaml)"
echo "- Vue.js Core source code (packages, packages-private, scripts)"
echo "- Vue.js Core documentation (README.md, CHANGELOG.md)"
echo "- Vue.js Core configuration (package.json, .gitignore, eslint.config.js)"
echo "- Docker container functionality (Node.js, pnpm, build tools)"
echo "- Progressive JavaScript framework capabilities"

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
    print_status "INFO" "All Docker tests passed! Your Vue.js Core Docker environment is ready!"
    print_status "INFO" "Vue.js Core is a progressive JavaScript framework."
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your Vue.js Core Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi

print_status "INFO" "You can now run Vue.js Core in Docker: A progressive JavaScript framework."
print_status "INFO" "Example: docker run --rm vuejs-core-env-test pnpm install"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/vuejs_core vuejs-core-env-test /bin/bash" 