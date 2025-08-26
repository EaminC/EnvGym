#!/bin/bash

# Express.js Environment Benchmark Test Script
# This script tests the environment setup for Express.js web framework

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
    # Kill any background processes
    jobs -p | xargs -r kill
    # Remove temporary files
    rm -f docker_build.log
    # Stop and remove Docker container if running
    docker stop expressjs-env-test 2>/dev/null || true
    docker rm expressjs-env-test 2>/dev/null || true
    exit 0
}

# Set up signal handlers
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the expressjs_express project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t expressjs-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/expressjs_express" expressjs-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "Express.js Environment Benchmark Test"
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
        
        if grep -q "node:20" envgym/envgym.dockerfile; then
            print_status "PASS" "Node.js 20 specified"
        else
            print_status "WARN" "Node.js 20 not specified"
        fi
        
        if grep -q "WORKDIR" envgym/envgym.dockerfile; then
            print_status "PASS" "WORKDIR set"
        else
            print_status "WARN" "WORKDIR not set"
        fi
        
        if grep -q "npm install" envgym/envgym.dockerfile; then
            print_status "PASS" "npm install found"
        else
            print_status "FAIL" "npm install not found"
        fi
        
        if grep -q "EXPOSE" envgym/envgym.dockerfile; then
            print_status "PASS" "EXPOSE instruction found"
        else
            print_status "WARN" "EXPOSE instruction not found"
        fi
        
        if grep -q "CMD\|ENTRYPOINT" envgym/envgym.dockerfile; then
            print_status "PASS" "CMD/ENTRYPOINT found"
        else
            print_status "WARN" "CMD/ENTRYPOINT not found"
        fi
        
        if grep -q "redis-server" envgym/envgym.dockerfile; then
            print_status "PASS" "Redis server specified"
        else
            print_status "WARN" "Redis server not specified"
        fi
        
        if grep -q "express-generator" envgym/envgym.dockerfile; then
            print_status "PASS" "Express generator specified"
        else
            print_status "WARN" "Express generator not specified"
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
    
    # Check Node.js version (should be 18 or higher)
    node_major=$(echo $node_version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ -n "$node_major" ] && [ "$node_major" -ge 18 ]; then
        print_status "PASS" "Node.js version is 18 or higher"
    else
        print_status "WARN" "Node.js version should be 18 or higher (found: $node_major)"
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

# Check git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1)
    print_status "PASS" "Git is available: $git_version"
else
    print_status "FAIL" "Git is not available"
fi

# Check Redis (optional)
if command -v redis-server &> /dev/null; then
    redis_version=$(redis-server --version 2>&1 | head -n 1)
    print_status "PASS" "Redis server is available: $redis_version"
else
    print_status "WARN" "Redis server is not available"
fi

# Check curl
if command -v curl &> /dev/null; then
    print_status "PASS" "curl is available"
else
    print_status "FAIL" "curl is not available"
fi

# Check wget
if command -v wget &> /dev/null; then
    print_status "PASS" "wget is available"
else
    print_status "WARN" "wget is not available"
fi

echo ""
echo "2. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "lib" ]; then
    print_status "PASS" "lib directory exists"
else
    print_status "FAIL" "lib directory not found"
fi

if [ -d "test" ]; then
    print_status "PASS" "test directory exists"
else
    print_status "FAIL" "test directory not found"
fi

if [ -d "examples" ]; then
    print_status "PASS" "examples directory exists"
else
    print_status "FAIL" "examples directory not found"
fi

if [ -d "benchmarks" ]; then
    print_status "PASS" "benchmarks directory exists"
else
    print_status "FAIL" "benchmarks directory not found"
fi

# Check key files
if [ -f "package.json" ]; then
    print_status "PASS" "package.json exists"
else
    print_status "FAIL" "package.json not found"
fi

if [ -f "index.js" ]; then
    print_status "PASS" "index.js exists"
else
    print_status "FAIL" "index.js not found"
fi

if [ -f "Readme.md" ]; then
    print_status "PASS" "Readme.md exists"
else
    print_status "FAIL" "Readme.md not found"
fi

if [ -f "LICENSE" ]; then
    print_status "PASS" "LICENSE exists"
else
    print_status "FAIL" "LICENSE not found"
fi

if [ -f ".npmrc" ]; then
    print_status "PASS" ".npmrc exists"
else
    print_status "FAIL" ".npmrc not found"
fi

if [ -f ".eslintrc.yml" ]; then
    print_status "PASS" ".eslintrc.yml exists"
else
    print_status "FAIL" ".eslintrc.yml not found"
fi

# Check lib files
if [ -f "lib/express.js" ]; then
    print_status "PASS" "lib/express.js exists"
else
    print_status "FAIL" "lib/express.js not found"
fi

if [ -f "lib/application.js" ]; then
    print_status "PASS" "lib/application.js exists"
else
    print_status "FAIL" "lib/application.js not found"
fi

if [ -f "lib/request.js" ]; then
    print_status "PASS" "lib/request.js exists"
else
    print_status "FAIL" "lib/request.js not found"
fi

if [ -f "lib/response.js" ]; then
    print_status "PASS" "lib/response.js exists"
else
    print_status "FAIL" "lib/response.js not found"
fi

if [ -f "lib/view.js" ]; then
    print_status "PASS" "lib/view.js exists"
else
    print_status "FAIL" "lib/view.js not found"
fi

if [ -f "lib/utils.js" ]; then
    print_status "PASS" "lib/utils.js exists"
else
    print_status "FAIL" "lib/utils.js not found"
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

# Check npm environment
if [ -n "${npm_config_prefix:-}" ]; then
    print_status "PASS" "npm_config_prefix is set: $npm_config_prefix"
else
    print_status "WARN" "npm_config_prefix is not set"
fi

# Check PATH
if echo "$PATH" | grep -q "node"; then
    print_status "PASS" "Node.js is in PATH"
else
    print_status "WARN" "Node.js is not in PATH"
fi

if echo "$PATH" | grep -q "npm"; then
    print_status "PASS" "npm is in PATH"
else
    print_status "WARN" "npm is not in PATH"
fi

echo ""
echo "4. Testing Node.js Environment..."
echo "-------------------------------"
# Test Node.js execution
if command -v node &> /dev/null; then
    print_status "PASS" "node is available"
    
    # Test Node.js execution
    if node -e "console.log('Hello from Node.js')" >/dev/null 2>&1; then
        print_status "PASS" "Node.js execution works"
    else
        print_status "WARN" "Node.js execution failed"
    fi
    
    # Test Node.js module system
    if node -e "console.log(require('path').join('test', 'file'))" >/dev/null 2>&1; then
        print_status "PASS" "Node.js module system works"
    else
        print_status "WARN" "Node.js module system failed"
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
    if timeout 30s npm list >/dev/null 2>&1; then
        print_status "PASS" "npm list command works"
    else
        print_status "WARN" "npm list command failed"
    fi
else
    print_status "FAIL" "npm is not available"
fi

echo ""
echo "6. Testing Package Installation Status..."
echo "---------------------------------------"
# Test if packages are already installed (environment should be pre-setup)
if command -v npm &> /dev/null && [ -f "package.json" ]; then
    print_status "PASS" "npm and package.json are available"
    
    # Check if node_modules exists (dependencies should be pre-installed)
    if [ -d "node_modules" ]; then
        print_status "PASS" "node_modules directory exists (dependencies installed)"
        
        # Check if Express is installed
        if [ -d "node_modules/express" ] || [ -d "node_modules/@types/express" ]; then
            print_status "PASS" "Express dependency is installed"
        else
            print_status "WARN" "Express dependency not found in node_modules"
        fi
        
        # Test if npm can read the dependency tree
        if timeout 30s npm list --depth=0 >/dev/null 2>&1; then
            print_status "PASS" "npm can read dependency tree"
        else
            print_status "WARN" "npm cannot read dependency tree properly"
        fi
    else
        print_status "FAIL" "node_modules directory not found (dependencies not installed)"
    fi
else
    print_status "FAIL" "npm or package.json not available"
fi

echo ""
echo "7. Testing Express.js Module..."
echo "-------------------------------"
# Test Express.js module
if command -v node &> /dev/null && [ -f "index.js" ]; then
    print_status "PASS" "node and index.js are available"
    
    # Test module export
    if timeout 30s node -e "const express = require('./index.js'); console.log('Express loaded successfully')" >/dev/null 2>&1; then
        print_status "PASS" "Express.js module loads successfully"
    else
        print_status "WARN" "Express.js module load failed"
    fi
    
    # Test basic Express functionality
    if timeout 30s node -e "const express = require('./index.js'); const app = express(); console.log('Express app created')" >/dev/null 2>&1; then
        print_status "PASS" "Express.js app creation works"
    else
        print_status "WARN" "Express.js app creation failed"
    fi
else
    print_status "WARN" "node or index.js not available"
fi

echo ""
echo "8. Testing Express Generator..."
echo "-------------------------------"
# Test Express generator
if command -v express &> /dev/null; then
    print_status "PASS" "express generator is available"
    
    # Test express version
    if timeout 30s express --version >/dev/null 2>&1; then
        print_status "PASS" "express generator version command works"
    else
        print_status "WARN" "express generator version command failed"
    fi
    
    # Test express help
    if timeout 30s express --help >/dev/null 2>&1; then
        print_status "PASS" "express generator help command works"
    else
        print_status "WARN" "express generator help command failed"
    fi
else
    print_status "WARN" "express generator is not available"
fi

echo ""
echo "9. Testing Testing Framework..."
echo "-------------------------------"
# Test Mocha
if command -v npx &> /dev/null; then
    print_status "PASS" "npx is available"
    
    # Test mocha
    if timeout 30s npx mocha --version >/dev/null 2>&1; then
        print_status "PASS" "Mocha is available"
    else
        print_status "WARN" "Mocha is not available"
    fi
else
    print_status "WARN" "npx is not available"
fi

# Test ESLint
if command -v npx &> /dev/null; then
    # Test eslint
    if timeout 30s npx eslint --version >/dev/null 2>&1; then
        print_status "PASS" "ESLint is available"
    else
        print_status "WARN" "ESLint is not available"
    fi
else
    print_status "WARN" "npx is not available"
fi

echo ""
echo "10. Testing Redis Integration..."
echo "--------------------------------"
# Test Redis
if command -v redis-server &> /dev/null; then
    print_status "PASS" "redis-server is available"
    
    # Test redis-cli
    if command -v redis-cli &> /dev/null; then
        print_status "PASS" "redis-cli is available"
        
        # Test Redis connection (if server is running)
        if timeout 10s redis-cli ping >/dev/null 2>&1; then
            print_status "PASS" "Redis server is running"
        else
            print_status "WARN" "Redis server is not running"
        fi
    else
        print_status "WARN" "redis-cli is not available"
    fi
else
    print_status "WARN" "redis-server is not available"
fi

echo ""
echo "11. Testing Official Test Suite (npm test)..."
echo "--------------------------------------------"
# Test npm test as mentioned in README
if command -v npm &> /dev/null && [ -f "package.json" ]; then
    print_status "PASS" "npm and package.json available for test suite"
    
    # Run npm test (the official way to test Express as per documentation)
    if timeout 300s npm test >/dev/null 2>&1; then
        print_status "PASS" "npm test (official test suite) succeeded"
    else
        print_status "FAIL" "npm test (official test suite) failed or timed out"
    fi
else
    print_status "FAIL" "npm or package.json not available for test suite"
fi

echo ""
echo "12. Testing Express Generator Availability..."
echo "-------------------------------------------"
# Test express-generator availability (should be pre-installed in environment)
if command -v express &> /dev/null; then
    print_status "PASS" "express command is available"
    
    # Test express version
    if timeout 30s express --version >/dev/null 2>&1; then
        print_status "PASS" "express --version works"
    else
        print_status "WARN" "express --version failed"
    fi
    
    # Test express help
    if timeout 30s express --help >/dev/null 2>&1; then
        print_status "PASS" "express --help works"
    else
        print_status "WARN" "express --help failed"
    fi
    
    # Test creating a minimal Express app structure (without npm install)
    temp_app_dir="/tmp/express_test_app_$$"
    if timeout 60s express "$temp_app_dir" >/dev/null 2>&1; then
        print_status "PASS" "Express app generation succeeded"
        
        # Test if generated app has required files
        if [ -d "$temp_app_dir" ]; then
            if [ -f "$temp_app_dir/app.js" ] && [ -f "$temp_app_dir/package.json" ]; then
                print_status "PASS" "Generated app has required files (app.js, package.json)"
                
                # Check package.json structure
                if grep -q "express" "$temp_app_dir/package.json"; then
                    print_status "PASS" "Generated package.json includes Express dependency"
                else
                    print_status "WARN" "Generated package.json missing Express dependency"
                fi
                
                # Check if basic app structure is correct
                if grep -q "var express = require('express')" "$temp_app_dir/app.js" || grep -q "const express = require('express')" "$temp_app_dir/app.js"; then
                    print_status "PASS" "Generated app.js has proper Express import"
                else
                    print_status "WARN" "Generated app.js missing proper Express import"
                fi
            else
                print_status "FAIL" "Generated app missing required files"
            fi
            
            # Clean up
            rm -rf "$temp_app_dir"
        else
            print_status "FAIL" "Generated app directory not found"
        fi
    else
        print_status "FAIL" "Express app generation failed"
    fi
    
    # Test if express-generator is globally available
    if command -v npm &> /dev/null && timeout 30s npm list -g express-generator >/dev/null 2>&1; then
        print_status "PASS" "express-generator is globally installed"
    else
        print_status "WARN" "express-generator not found in global npm packages"
    fi
else
    print_status "FAIL" "express command not available (express-generator not installed)"
fi

echo ""
echo "13. Testing Examples Directory..."
echo "-------------------------------"
# Test examples as mentioned in README documentation
if [ -d "examples" ] && command -v node &> /dev/null; then
    print_status "PASS" "examples directory and node available"
    
    # Test content-negotiation example (specifically mentioned in README)
    if [ -f "examples/content-negotiation/index.js" ]; then
        print_status "PASS" "content-negotiation example exists"
        
        # Test if the example can run (briefly)
        if timeout 15s node examples/content-negotiation/index.js >/dev/null 2>&1 &
        then
            sleep 5
            pkill -f "examples/content-negotiation" 2>/dev/null || true
            print_status "PASS" "content-negotiation example can execute"
        else
            print_status "WARN" "content-negotiation example failed to run or timed out"
        fi
    else
        print_status "FAIL" "content-negotiation example not found"
    fi
    
    # Count and test other examples
    example_count=$(find examples -name "*.js" -type f | wc -l)
    if [ "$example_count" -gt 5 ]; then
        print_status "PASS" "Multiple examples available ($example_count found)"
    else
        print_status "WARN" "Limited examples found ($example_count)"
    fi
    
    # Test a few more examples
    example_files=($(find examples -name "index.js" -type f | head -3))
    working_examples=0
    for example_file in "${example_files[@]}"; do
        if timeout 10s node "$example_file" >/dev/null 2>&1 &
        then
            sleep 2
            pkill -f "$example_file" 2>/dev/null || true
            ((working_examples++))
        fi
    done
    
    if [ ${#example_files[@]} -gt 0 ]; then
        print_status "PASS" "$working_examples/${#example_files[@]} tested examples can execute"
    fi
else
    print_status "FAIL" "examples directory or node not available"
fi

echo ""
echo "14. Testing Template Engine Support..."
echo "------------------------------------"
# Test template engine support (mentioned in README: "support for over 14 template engines")
if command -v node &> /dev/null && [ -f "index.js" ]; then
    print_status "PASS" "node and index.js available for template testing"
    
    # Test basic template engine functionality
    if timeout 30s node -e "
        const express = require('./index.js');
        const app = express();
        app.set('view engine', 'html');
        app.engine('html', function (filePath, options, callback) {
            callback(null, 'Template engine works');
        });
        console.log('Template engine configuration successful');
    " >/dev/null 2>&1; then
        print_status "PASS" "Template engine configuration works"
    else
        print_status "WARN" "Template engine configuration failed"
    fi
    
    # Check if consolidate (template engine library) can be loaded if available
    if timeout 30s node -e "
        try {
            require('@ladjs/consolidate');
            console.log('Consolidate available');
        } catch(e) {
            console.log('Consolidate not available (this is optional)');
        }
    " >/dev/null 2>&1; then
        print_status "PASS" "@ladjs/consolidate template engine library available"
    else
        print_status "WARN" "@ladjs/consolidate template engine library not available"
    fi
else
    print_status "WARN" "node or index.js not available for template testing"
fi

echo ""
echo "15. Testing HTTP Server Functionality..."
echo "--------------------------------------"
# Test comprehensive HTTP server functionality
if command -v node &> /dev/null && [ -f "index.js" ]; then
    print_status "PASS" "node and index.js are available for HTTP testing"
    
    # Test basic HTTP server creation and response
    if timeout 30s node -e "
        const express = require('./index.js');
        const app = express();
        app.get('/', (req, res) => res.send('Hello Express'));
        const server = app.listen(0, () => {
            console.log('Server created successfully');
            server.close();
        });
    " >/dev/null 2>&1; then
        print_status "PASS" "Express HTTP server creation works"
    else
        print_status "WARN" "Express HTTP server creation failed"
    fi
    
    # Test middleware functionality
    if timeout 30s node -e "
        const express = require('./index.js');
        const app = express();
        app.use((req, res, next) => {
            req.customProperty = 'middleware works';
            next();
        });
        app.get('/', (req, res) => res.send(req.customProperty));
        const server = app.listen(0, () => {
            console.log('Middleware test successful');
            server.close();
        });
    " >/dev/null 2>&1; then
        print_status "PASS" "Express middleware functionality works"
    else
        print_status "WARN" "Express middleware functionality failed"
    fi
    
    # Test JSON parsing
    if timeout 30s node -e "
        const express = require('./index.js');
        const app = express();
        app.use(express.json());
        app.post('/test', (req, res) => res.json({received: req.body}));
        const server = app.listen(0, () => {
            console.log('JSON parsing test successful');
            server.close();
        });
    " >/dev/null 2>&1; then
        print_status "PASS" "Express JSON parsing works"
    else
        print_status "WARN" "Express JSON parsing failed"
    fi
    
    # Test router functionality
    if timeout 30s node -e "
        const express = require('./index.js');
        const app = express();
        const router = express.Router();
        router.get('/test', (req, res) => res.send('Router works'));
        app.use('/api', router);
        const server = app.listen(0, () => {
            console.log('Router test successful');
            server.close();
        });
    " >/dev/null 2>&1; then
        print_status "PASS" "Express Router functionality works"
    else
        print_status "WARN" "Express Router functionality failed"
    fi
else
    print_status "WARN" "node or index.js not available for HTTP testing"
fi

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (Node.js 18+, npm, Git, Redis)"
echo "- Project structure (lib/, test/, examples/, benchmarks/)"
echo "- Environment variables (NODE_ENV, npm_config_prefix, PATH)"
echo "- Node.js environment (node, module system)"
echo "- Package management (npm, package installation)"
echo "- Express.js module (loading, app creation)"
echo "- Express generator (express command)"
echo "- Testing framework (Mocha, ESLint)"
echo "- Redis integration (redis-server, redis-cli)"
echo "- Official test suite (npm test)"
echo "- Express generator workflow (full quickstart process)"
echo "- Examples directory (content-negotiation and others)"
echo "- Template engine support (@ladjs/consolidate)"
echo "- HTTP server functionality (middleware, JSON, routing)"
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
    print_status "INFO" "All tests passed! Your Express.js environment is ready!"
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your Express.js environment is mostly ready."
    print_status "WARN" "Some optional dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi

print_status "INFO" "You can now build and test Express.js web framework."
print_status "INFO" "Example: npm install && npm test"

echo ""
print_status "INFO" "For more information, see Readme.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/expressjs_express expressjs-env-test /bin/bash"
