#!/bin/bash
# darkreader_darkreader Environment Benchmark Test
# Tests if the environment is properly set up for the Dark Reader browser extension project
# Don't exit on error - continue testing even if some tests fail
# set -e  # Exit on any error
trap 'echo -e "\n\033[0;31m[ERROR] Script interrupted by user\033[0m"; exit 1' INT TERM

# Function to ensure clean exit
cleanup() {
    echo -e "\n\033[0;34m[INFO] Cleaning up...\033[0m"
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

print_status() {
    local status=$1
    local message=$2
    case $status in
        "PASS") echo -e "${GREEN}[PASS]${NC} $message"; ((PASS_COUNT++)); ;;
        "FAIL") echo -e "${RED}[FAIL]${NC} $message"; ((FAIL_COUNT++)); ;;
        "WARN") echo -e "${YELLOW}[WARN]${NC} $message"; ((WARN_COUNT++)); ;;
        "INFO") echo -e "${BLUE}[INFO]${NC} $message"; ;;
        *) echo "[$status] $message"; ;;
    esac
}

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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the darkreader_darkreader project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t darkreader-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/darkreader_darkreader" darkreader-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "darkreader_darkreader Environment Benchmark Test"
echo "=========================================="
echo ""


echo "1. Checking System Dependencies..."
echo "--------------------------------"
check_command "node" "Node.js"
check_command "npm" "npm"
check_command "git" "Git"
check_command "bash" "Bash"
check_command "curl" "curl"
check_command "deno" "Deno (optional)"

# Node version check
if command -v node &> /dev/null; then
    node_version=$(node -v | sed 's/v//')
    node_major=$(echo $node_version | cut -d'.' -f1)
    if [ "$node_major" -ge 18 ]; then
        print_status "PASS" "Node.js version >= 18 ($node_version)"
    else
        print_status "WARN" "Node.js version < 18 ($node_version)"
    fi
fi

echo ""
echo "2. Checking NPM Dependencies..."
echo "-------------------------------"
if [ -f "package.json" ]; then
    print_status "PASS" "package.json exists"
    if [ -f "package-lock.json" ]; then
        print_status "PASS" "package-lock.json exists"
    else
        print_status "WARN" "package-lock.json missing"
    fi
    if npm install --ignore-scripts --no-audit --no-fund; then
        print_status "PASS" "npm install completed successfully"
    else
        print_status "FAIL" "npm install failed"
    fi
else
    print_status "FAIL" "package.json missing"
fi

echo ""
echo "3. Checking Project Structure..."
echo "-------------------------------"
[ -d "src" ] && print_status "PASS" "src directory exists" || print_status "FAIL" "src directory missing"
[ -d "tasks" ] && print_status "PASS" "tasks directory exists" || print_status "FAIL" "tasks directory missing"
[ -d "tests" ] && print_status "PASS" "tests directory exists" || print_status "FAIL" "tests directory missing"
[ -d "build" ] && print_status "PASS" "build directory exists" || print_status "WARN" "build directory missing (will be created after build)"

# Check for main scripts
[ -f "tasks/cli.js" ] && print_status "PASS" "tasks/cli.js exists" || print_status "FAIL" "tasks/cli.js missing"
[ -f "eslint.config.js" ] && print_status "PASS" "eslint.config.js exists" || print_status "FAIL" "eslint.config.js missing"

# Check for README and LICENSE
[ -f "README.md" ] && print_status "PASS" "README.md exists" || print_status "FAIL" "README.md missing"
[ -f "LICENSE" ] && print_status "PASS" "LICENSE exists" || print_status "FAIL" "LICENSE missing"

# Check for TypeScript config
[ -f "src/tsconfig.json" ] && print_status "PASS" "src/tsconfig.json exists" || print_status "WARN" "src/tsconfig.json missing"

# Check for test config
[ -f "tests/unit/jest.config.mjs" ] && print_status "PASS" "tests/unit/jest.config.mjs exists" || print_status "WARN" "tests/unit/jest.config.mjs missing"
[ -f "tests/inject/karma.conf.cjs" ] && print_status "PASS" "tests/inject/karma.conf.cjs exists" || print_status "WARN" "tests/inject/karma.conf.cjs missing"

echo ""
echo "4. Testing Build..."
echo "-------------------"
if npm run build:all; then
    print_status "PASS" "npm run build:all successful"
else
    print_status "FAIL" "npm run build:all failed"
fi

# Check build artifacts
if [ -d "build/release" ]; then
    print_status "PASS" "build/release directory exists"
    [ -f "build/release/darkreader-chrome.zip" ] && print_status "PASS" "darkreader-chrome.zip exists" || print_status "WARN" "darkreader-chrome.zip missing"
    [ -f "build/release/darkreader-firefox.xpi" ] && print_status "PASS" "darkreader-firefox.xpi exists" || print_status "WARN" "darkreader-firefox.xpi missing"
else
    print_status "WARN" "build/release directory missing (build may have failed)"
fi

echo ""
echo "5. Linting..."
echo "-------------"
if npm run lint; then
    print_status "PASS" "npm run lint successful"
else
    print_status "WARN" "npm run lint failed"
fi

echo ""
echo "6. Unit Tests..."
echo "----------------"
if npm run test:unit; then
    print_status "PASS" "npm run test:unit successful"
else
    print_status "FAIL" "npm run test:unit failed"
fi

echo ""
echo "7. Browser/Inject Tests (Optional)..."
echo "-------------------------------------"
timeout 60s npm run test:inject 2>&1 | tee inject_test.log
if grep -q "No binary for Chrome browser" inject_test.log; then
    print_status "WARN" "Chrome/Chromium not found, browser tests skipped"
elif grep -q "Karma.*ERROR" inject_test.log; then
    print_status "WARN" "Karma error, browser tests skipped"
elif grep -q "PASS" inject_test.log; then
    print_status "PASS" "npm run test:inject successful"
else
    print_status "WARN" "npm run test:inject failed or skipped (browser may not be available)"
fi
rm -f inject_test.log

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (Node.js, npm, git, bash, curl, deno)"
echo "- NPM dependencies (package.json, package-lock.json, npm install)"
echo "- Project structure (src, tasks, tests, build, main scripts, configs)"
echo "- Build process (npm run build:all, build artifacts)"
echo "- Linting (npm run lint)"
echo "- Unit tests (npm run test:unit)"
echo "- Browser/inject tests (npm run test:inject)"
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
    print_status "INFO" "All tests passed! Your darkreader_darkreader environment is ready!"
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your darkreader_darkreader environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi

print_status "INFO" "You can now build and test Dark Reader."
print_status "INFO" "Example: npm install && npm run build:all && npm run test:unit"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/darkreader_darkreader darkreader-env-test /bin/bash" 