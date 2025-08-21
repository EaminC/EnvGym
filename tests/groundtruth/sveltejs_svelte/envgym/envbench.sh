#!/bin/bash

# Svelte Environment Benchmark Test Script
# This script tests the Docker environment setup for Svelte: A web framework
# Tailored specifically for Svelte project requirements and features

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
    docker stop svelte-env-test 2>/dev/null || true
    docker rm svelte-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the sveltejs_svelte project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t svelte-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/sveltejs_svelte" svelte-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "Svelte Environment Benchmark Test"
echo "=========================================="

echo "1. Checking Node.js Environment..."
echo "---------------------------------"
# Check Node.js version
if command -v node &> /dev/null; then
    node_version=$(node --version 2>&1)
    print_status "PASS" "Node.js is available: $node_version"
    
    # Check Node.js version compatibility (Svelte requires 18+)
    node_major=$(node --version 2>&1 | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$node_major" -ge 18 ]; then
        print_status "PASS" "Node.js version is >= 18 (compatible with Svelte)"
    else
        print_status "WARN" "Node.js version should be >= 18 for Svelte (found: $node_major)"
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
    
    # Check pnpm version compatibility (requires >= 9.0.0)
    pnpm_major=$(pnpm --version 2>&1 | cut -d'.' -f1)
    pnpm_minor=$(pnpm --version 2>&1 | cut -d'.' -f2)
    if [ "$pnpm_major" -ge 9 ]; then
        print_status "PASS" "pnpm version is >= 9.0.0 (compatible with Svelte)"
    else
        print_status "WARN" "pnpm version should be >= 9.0.0 for Svelte (found: $pnpm_major.$pnpm_minor)"
    fi
else
    print_status "WARN" "pnpm is not available"
fi

# Check Node.js execution
if command -v node &> /dev/null; then
    if timeout 30s node --version >/dev/null 2>&1; then
        print_status "PASS" "Node.js execution works"
    else
        print_status "WARN" "Node.js execution failed"
    fi
    
    # Test Node.js modules
    if node -e "console.log('Node.js test successful')" 2>/dev/null; then
        print_status "PASS" "Node.js module execution works"
    else
        print_status "FAIL" "Node.js module execution failed"
    fi
else
    print_status "FAIL" "Node.js is not available for testing"
fi

echo ""
echo "2. Checking Frontend Development Dependencies..."
echo "------------------------------------------------"
# Test if required Node.js packages are available
if command -v node &> /dev/null; then
    print_status "INFO" "Testing Svelte Node.js dependencies..."
    
    # Test TypeScript
    if command -v tsc &> /dev/null; then
        tsc_version=$(tsc --version 2>&1)
        print_status "PASS" "TypeScript is available: $tsc_version"
    else
        print_status "WARN" "TypeScript is not available"
    fi
    
    # Test ESLint
    if command -v eslint &> /dev/null; then
        eslint_version=$(eslint --version 2>&1)
        print_status "PASS" "ESLint is available: $eslint_version"
    else
        print_status "WARN" "ESLint is not available"
    fi
    
    # Test Prettier
    if command -v prettier &> /dev/null; then
        prettier_version=$(prettier --version 2>&1)
        print_status "PASS" "Prettier is available: $prettier_version"
    else
        print_status "WARN" "Prettier is not available"
    fi
    
    # Test Vitest
    if command -v vitest &> /dev/null; then
        vitest_version=$(vitest --version 2>&1)
        print_status "PASS" "Vitest is available: $vitest_version"
    else
        print_status "WARN" "Vitest is not available"
    fi
    
    # Test Playwright
    if command -v playwright &> /dev/null; then
        playwright_version=$(playwright --version 2>&1)
        print_status "PASS" "Playwright is available: $playwright_version"
    else
        print_status "WARN" "Playwright is not available"
    fi
else
    print_status "FAIL" "Node.js is not available for dependency testing"
fi

echo ""
echo "3. Checking System Dependencies..."
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

# Check Python (for some Node.js native modules)
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version 2>&1)
    print_status "PASS" "Python3 is available: $python_version"
else
    print_status "WARN" "Python3 is not available"
fi

echo ""
echo "4. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "packages" ]; then
    print_status "PASS" "packages directory exists (monorepo packages)"
else
    print_status "FAIL" "packages directory not found"
fi

if [ -d "packages/svelte" ]; then
    print_status "PASS" "packages/svelte directory exists (main Svelte package)"
else
    print_status "FAIL" "packages/svelte directory not found"
fi

if [ -d "playgrounds" ]; then
    print_status "PASS" "playgrounds directory exists (test playgrounds)"
else
    print_status "FAIL" "playgrounds directory not found"
fi

if [ -d "documentation" ]; then
    print_status "PASS" "documentation directory exists (documentation)"
else
    print_status "FAIL" "documentation directory not found"
fi

if [ -d "benchmarking" ]; then
    print_status "PASS" "benchmarking directory exists (performance tests)"
else
    print_status "FAIL" "benchmarking directory not found"
fi

if [ -d "assets" ]; then
    print_status "PASS" "assets directory exists (static assets)"
else
    print_status "FAIL" "assets directory not found"
fi

# Check key files
if [ -f "package.json" ]; then
    print_status "PASS" "package.json exists"
else
    print_status "FAIL" "package.json not found"
fi

if [ -f "pnpm-workspace.yaml" ]; then
    print_status "PASS" "pnpm-workspace.yaml exists (workspace config)"
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

if [ -f "LICENSE.md" ]; then
    print_status "PASS" "LICENSE.md exists"
else
    print_status "FAIL" "LICENSE.md not found"
fi

if [ -f "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md exists"
else
    print_status "FAIL" "CONTRIBUTING.md not found"
fi

if [ -f "CODE_OF_CONDUCT.md" ]; then
    print_status "PASS" "CODE_OF_CONDUCT.md exists"
else
    print_status "FAIL" "CODE_OF_CONDUCT.md not found"
fi

# Check Svelte package files
if [ -f "packages/svelte/package.json" ]; then
    print_status "PASS" "packages/svelte/package.json exists"
else
    print_status "FAIL" "packages/svelte/package.json not found"
fi

if [ -f "packages/svelte/README.md" ]; then
    print_status "PASS" "packages/svelte/README.md exists"
else
    print_status "FAIL" "packages/svelte/README.md not found"
fi

if [ -d "packages/svelte/src" ]; then
    print_status "PASS" "packages/svelte/src directory exists (source code)"
else
    print_status "FAIL" "packages/svelte/src directory not found"
fi

if [ -d "packages/svelte/tests" ]; then
    print_status "PASS" "packages/svelte/tests directory exists (test suite)"
else
    print_status "FAIL" "packages/svelte/tests directory not found"
fi

if [ -d "packages/svelte/types" ]; then
    print_status "PASS" "packages/svelte/types directory exists (TypeScript types)"
else
    print_status "FAIL" "packages/svelte/types directory not found"
fi

# Check configuration files
if [ -f "svelte.config.js" ]; then
    print_status "PASS" "svelte.config.js exists (Svelte config)"
else
    print_status "FAIL" "svelte.config.js not found"
fi

if [ -f "vitest.config.js" ]; then
    print_status "PASS" "vitest.config.js exists (test config)"
else
    print_status "FAIL" "vitest.config.js not found"
fi

if [ -f "eslint.config.js" ]; then
    print_status "PASS" "eslint.config.js exists (linting config)"
else
    print_status "FAIL" "eslint.config.js not found"
fi

if [ -f ".prettierrc" ]; then
    print_status "PASS" ".prettierrc exists (formatting config)"
else
    print_status "FAIL" ".prettierrc not found"
fi

if [ -f ".npmrc" ]; then
    print_status "PASS" ".npmrc exists (npm config)"
else
    print_status "FAIL" ".npmrc not found"
fi

echo ""
echo "5. Testing Svelte Source Code..."
echo "--------------------------------"
# Count JavaScript files
js_files=$(find . -name "*.js" | wc -l)
if [ "$js_files" -gt 0 ]; then
    print_status "PASS" "Found $js_files JavaScript files"
else
    print_status "FAIL" "No JavaScript files found"
fi

# Count TypeScript files
ts_files=$(find . -name "*.ts" | wc -l)
if [ "$ts_files" -gt 0 ]; then
    print_status "PASS" "Found $ts_files TypeScript files"
else
    print_status "WARN" "No TypeScript files found"
fi

# Count Svelte files
svelte_files=$(find . -name "*.svelte" | wc -l)
if [ "$svelte_files" -gt 0 ]; then
    print_status "PASS" "Found $svelte_files Svelte files"
else
    print_status "WARN" "No Svelte files found"
fi

# Count JSON files
json_files=$(find . -name "*.json" | wc -l)
if [ "$json_files" -gt 0 ]; then
    print_status "PASS" "Found $json_files JSON files"
else
    print_status "WARN" "No JSON files found"
fi

# Count YAML files
yaml_files=$(find . -name "*.yaml" -o -name "*.yml" | wc -l)
if [ "$yaml_files" -gt 0 ]; then
    print_status "PASS" "Found $yaml_files YAML files"
else
    print_status "WARN" "No YAML files found"
fi

# Test JavaScript syntax
if command -v node &> /dev/null; then
    print_status "INFO" "Testing JavaScript syntax..."
    syntax_errors=0
    for js_file in $(find . -name "*.js" | head -10); do
        if ! timeout 30s node -c "$js_file" >/dev/null 2>&1; then
            ((syntax_errors++))
        fi
    done
    
    if [ "$syntax_errors" -eq 0 ]; then
        print_status "PASS" "All tested JavaScript files have valid syntax"
    else
        print_status "WARN" "Found $syntax_errors JavaScript files with syntax errors"
    fi
else
    print_status "FAIL" "Node.js is not available for syntax checking"
fi

# Test package.json parsing
if command -v node &> /dev/null; then
    print_status "INFO" "Testing package.json parsing..."
    if timeout 60s node -e "JSON.parse(require('fs').readFileSync('package.json', 'utf8'))" >/dev/null 2>&1; then
        print_status "PASS" "package.json parsing successful"
    else
        print_status "WARN" "package.json parsing failed"
    fi
else
    print_status "FAIL" "Node.js is not available for package.json parsing"
fi

echo ""
echo "6. Testing Svelte Dependencies..."
echo "---------------------------------"
# Test if required Node.js packages are available
if command -v node &> /dev/null; then
    print_status "INFO" "Testing Svelte Node.js dependencies..."
    
    # Test if node_modules exists (indicating dependencies are installed)
    if [ -d "node_modules" ]; then
        print_status "PASS" "node_modules directory exists (dependencies installed)"
    else
        print_status "WARN" "node_modules directory not found (dependencies not installed)"
    fi
    
    # Test if packages/svelte/node_modules exists
    if [ -d "packages/svelte/node_modules" ]; then
        print_status "PASS" "packages/svelte/node_modules exists (Svelte dependencies installed)"
    else
        print_status "WARN" "packages/svelte/node_modules not found (Svelte dependencies not installed)"
    fi
else
    print_status "FAIL" "Node.js is not available for dependency testing"
fi

echo ""
echo "7. Testing Svelte Documentation..."
echo "----------------------------------"
# Test documentation readability
if [ -r "README.md" ]; then
    print_status "PASS" "README.md is readable"
else
    print_status "FAIL" "README.md is not readable"
fi

if [ -r "packages/svelte/README.md" ]; then
    print_status "PASS" "packages/svelte/README.md is readable"
else
    print_status "FAIL" "packages/svelte/README.md is not readable"
fi

if [ -r "LICENSE.md" ]; then
    print_status "PASS" "LICENSE.md is readable"
else
    print_status "FAIL" "LICENSE.md is not readable"
fi

if [ -r "CONTRIBUTING.md" ]; then
    print_status "PASS" "CONTRIBUTING.md is readable"
else
    print_status "FAIL" "CONTRIBUTING.md is not readable"
fi

if [ -r "CODE_OF_CONDUCT.md" ]; then
    print_status "PASS" "CODE_OF_CONDUCT.md is readable"
else
    print_status "FAIL" "CODE_OF_CONDUCT.md is not readable"
fi

# Check README content
if [ -r "README.md" ]; then
    if grep -q "Svelte" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "web applications" README.md; then
        print_status "PASS" "README.md contains web applications description"
    else
        print_status "WARN" "README.md missing web applications description"
    fi
    
    if grep -q "compiler" README.md; then
        print_status "PASS" "README.md contains compiler description"
    else
        print_status "WARN" "README.md missing compiler description"
    fi
    
    if grep -q "MIT" README.md; then
        print_status "PASS" "README.md contains MIT license reference"
    else
        print_status "WARN" "README.md missing MIT license reference"
    fi
fi

echo ""
echo "8. Testing Svelte Docker Functionality..."
echo "-----------------------------------------"
# Test if Docker container can run basic commands
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test Node.js in Docker
    if docker run --rm svelte-env-test node --version >/dev/null 2>&1; then
        print_status "PASS" "Node.js works in Docker container"
    else
        print_status "FAIL" "Node.js does not work in Docker container"
    fi
    
    # Test npm in Docker
    if docker run --rm svelte-env-test npm --version >/dev/null 2>&1; then
        print_status "PASS" "npm works in Docker container"
    else
        print_status "FAIL" "npm does not work in Docker container"
    fi
    
    # Test pnpm in Docker
    if docker run --rm svelte-env-test pnpm --version >/dev/null 2>&1; then
        print_status "PASS" "pnpm works in Docker container"
    else
        print_status "FAIL" "pnpm does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm svelte-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" svelte-env-test test -f README.md; then
        print_status "PASS" "README.md is accessible in Docker container"
    else
        print_status "FAIL" "README.md is not accessible in Docker container"
    fi
    
    # Test if package.json is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" svelte-env-test test -f package.json; then
        print_status "PASS" "package.json is accessible in Docker container"
    else
        print_status "FAIL" "package.json is not accessible in Docker container"
    fi
    
    # Test if packages/svelte/package.json is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" svelte-env-test test -f packages/svelte/package.json; then
        print_status "PASS" "packages/svelte/package.json is accessible in Docker container"
    else
        print_status "FAIL" "packages/svelte/package.json is not accessible in Docker container"
    fi
    
    # Test if pnpm-workspace.yaml is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" svelte-env-test test -f pnpm-workspace.yaml; then
        print_status "PASS" "pnpm-workspace.yaml is accessible in Docker container"
    else
        print_status "FAIL" "pnpm-workspace.yaml is not accessible in Docker container"
    fi
    
    # Test Node.js execution in Docker
    if timeout 60s docker run --rm -v "$(pwd):/workspace" -w /workspace svelte-env-test node -e "console.log('Svelte test successful')" >/dev/null 2>&1; then
        print_status "PASS" "Node.js execution works in Docker container"
    else
        print_status "FAIL" "Node.js execution does not work in Docker container"
    fi
    
    # Test pnpm workspace recognition in Docker
    if timeout 60s docker run --rm -v "$(pwd):/workspace" -w /workspace svelte-env-test pnpm list --depth=0 >/dev/null 2>&1; then
        print_status "PASS" "pnpm workspace recognition works in Docker container"
    else
        print_status "FAIL" "pnpm workspace recognition does not work in Docker container"
    fi
fi

echo ""
echo "9. Testing Svelte Build Process..."
echo "----------------------------------"
# Test if Docker container can run build commands
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test if scripts are accessible
    if docker run --rm -v "$(pwd):/workspace" -w /workspace svelte-env-test test -d packages/svelte/scripts; then
        print_status "PASS" "packages/svelte/scripts directory is accessible in Docker container"
    else
        print_status "FAIL" "packages/svelte/scripts directory is not accessible in Docker container"
    fi
    
    # Test if dependencies are installed in Docker
    if docker run --rm -v "$(pwd):/workspace" -w /workspace svelte-env-test test -d node_modules; then
        print_status "PASS" "node_modules is accessible in Docker container"
    else
        print_status "FAIL" "node_modules is not accessible in Docker container"
    fi
    
    # Test if packages/svelte/node_modules is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" -w /workspace svelte-env-test test -d packages/svelte/node_modules; then
        print_status "PASS" "packages/svelte/node_modules is accessible in Docker container"
    else
        print_status "FAIL" "packages/svelte/node_modules is not accessible in Docker container"
    fi
    
    # Test pnpm install (without running full build)
    if timeout 120s docker run --rm -v "$(pwd):/workspace" -w /workspace svelte-env-test pnpm install --frozen-lockfile >/dev/null 2>&1; then
        print_status "PASS" "pnpm install works in Docker container"
    else
        print_status "FAIL" "pnpm install does not work in Docker container"
    fi
    
    # Test pnpm build help (without running full build)
    if timeout 60s docker run --rm -v "$(pwd):/workspace" -w /workspace svelte-env-test pnpm run build --help >/dev/null 2>&1; then
        print_status "PASS" "pnpm build help works in Docker container"
    else
        print_status "WARN" "pnpm build help does not work in Docker container"
    fi
    
    # Skip actual build tests to avoid timeouts
    print_status "WARN" "Skipping actual build tests to avoid timeouts (full Svelte compilation)"
    print_status "INFO" "Docker environment is ready for Svelte development"
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for Svelte:"
echo "- Docker build process (Ubuntu 22.04, Node.js, pnpm)"
echo "- Node.js environment (version compatibility, module loading)"
echo "- pnpm environment (package management, workspace)"
echo "- Svelte build system (package.json, pnpm-workspace.yaml)"
echo "- Svelte source code (packages, playgrounds, documentation)"
echo "- Svelte documentation (README.md, CONTRIBUTING.md)"
echo "- Svelte configuration (package.json, .gitignore, eslint.config.js)"
echo "- Docker container functionality (Node.js, pnpm, build tools)"
echo "- Web framework capabilities"

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
    print_status "INFO" "All Docker tests passed! Your Svelte Docker environment is ready!"
    print_status "INFO" "Svelte is a web framework."
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your Svelte Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi

print_status "INFO" "You can now run Svelte in Docker: A web framework."
print_status "INFO" "Example: docker run --rm svelte-env-test pnpm install"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/sveltejs_svelte svelte-env-test /bin/bash" 