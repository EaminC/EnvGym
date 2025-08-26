#!/bin/bash

# Acto Environment Benchmark Test Script
# Tests if the Dockerfile successfully sets up the environment for the Acto repository

# Don't exit on error - continue testing even if some tests fail
# set -e  # Exit on any error
trap 'echo -e "\n\033[0;31m[ERROR] Script interrupted by user\033[0m"; exit 1' INT TERM

# Function to ensure clean exit
cleanup() {
    echo -e "\n\033[0;34m[INFO] Cleaning up...\033[0m"
    # Kill any background processes
    jobs -p | xargs -r kill
    # Stop and remove any test clusters
    kind delete cluster --name acto-test-cluster 2>/dev/null || true
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


# Function to print proportional status with scoring
print_proportional_status() {
    local actual=$1
    local total=$2
    local max_points=$3
    local message=$4
    
    # Pure bash arithmetic approach - more reliable across environments
    # Calculate score using integer arithmetic
    if [ "$total" -ne "0" ]; then
        # Use bc for floating point if available
        if command -v bc &>/dev/null; then
            # Calculate with bc but ensure we get a value (or default to 0)
            local raw_score=$(echo "scale=6; ($actual * $max_points) / $total" | bc 2>/dev/null || echo "0")
            # Round to nearest integer by adding 0.5 and truncating
            local rounded_score=$(echo "$raw_score + 0.5" | bc | cut -d. -f1)
        else
            # Fallback to bash arithmetic (less precise)
            local pct=$(( actual * 100 / total ))
            local rounded_score=$(( pct * max_points / 100 ))
        fi
    else
        local rounded_score=0
    fi
    
    # Ensure score is within bounds
    if [ "$rounded_score" -gt "$max_points" ]; then
        rounded_score=$max_points
    elif [ "$rounded_score" -lt "0" ]; then
        rounded_score=0
    fi
    
    # Add to PASS_COUNT (treating as positive achievement)
    PASS_COUNT=$((PASS_COUNT + rounded_score))
    
    # Add remaining points to FAIL_COUNT
    local fail_points=$((max_points - rounded_score))
    FAIL_COUNT=$((FAIL_COUNT + fail_points))
    
    # Print with color based on performance
    if [ "$actual" -eq "$total" ]; then
        echo -e "${GREEN}[PASS]${NC} $message (Score: $rounded_score/$max_points)"
    elif [ "$actual" -gt "$((total / 2))" ]; then
        echo -e "${YELLOW}[PARTIAL]${NC} $message (Score: $rounded_score/$max_points)"  
    else
        echo -e "${RED}[LOW]${NC} $message (Score: $rounded_score/$max_points)"
    fi
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

# Function to check if a Python package is installed
check_python_package() {
    local package=$1
    if python -c "import $package" 2>/dev/null; then
        print_status "PASS" "Python package '$package' is installed"
        return 0
    else
        # Try to get more information about why import failed
        python -c "import $package" 2>&1 | head -1 | grep -q "ModuleNotFoundError" && {
            print_status "FAIL" "Python package '$package' is not installed"
        } || {
            print_status "FAIL" "Python package '$package' import failed (other error)"
        }
        return 1
    fi
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

# Check if we're running inside Docker container
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    echo "Running inside Docker container - proceeding with environment test..."
else
    echo "Not running in Docker container - building and running Docker test..."
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        echo "ERROR: Docker is not installed or not in PATH"
        write_results_to_json
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "envgym/envgym.dockerfile" ]; then
        echo "ERROR: envgym.dockerfile not found. Please run this script from the acto project root directory."
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t acto-env-test .; then
        echo -e "${RED}[CRITICAL ERROR]${NC} Docker build failed"
        echo -e "${RED}[RESULT]${NC} Benchmark score: 0 (Docker build failed)"
        write_results_to_json
        exit 1
    fi
    
    # Run this script inside Docker container
    echo "Running environment test in Docker container..."
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/acto" acto-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "Acto Environment Benchmark Test"
echo "=========================================="

echo ""
echo "1. Checking System Dependencies..."
echo "--------------------------------"

# Store results of command checks in variables for later scoring
system_deps_total=0
system_deps_success=0

# Check system commands (based on Acto prerequisites)
if check_command "python" "Python"; then
    ((system_deps_success++))
fi
((system_deps_total++))

if check_command "pip" "pip"; then
    ((system_deps_success++))
fi
((system_deps_total++))

if check_command "go" "Go"; then
    ((system_deps_success++))
fi
((system_deps_total++))

if check_command "kubectl" "kubectl"; then
    ((system_deps_success++))
fi
((system_deps_total++))

if check_command "kind" "Kind"; then
    ((system_deps_success++))
fi
((system_deps_total++))

if check_command "helm" "Helm"; then
    ((system_deps_success++))
fi
((system_deps_total++))

if check_command "git" "Git"; then
    ((system_deps_success++))
fi
((system_deps_total++))

if check_command "make" "Make"; then
    ((system_deps_success++))
fi
((system_deps_total++))

# Print proportional score for system dependencies
print_proportional_status $system_deps_success $system_deps_total 5 "System dependencies check"

echo ""
echo "2. Checking Python and Go Versions..."
echo "-----------------------------------"

# Check Python version
python_version=$(python --version 2>&1)
print_status "INFO" "Python version: $python_version"

# Check if Python version is >= 3.12
python_major=$(python -c "import sys; print(sys.version_info.major)" 2>/dev/null)
python_minor=$(python -c "import sys; print(sys.version_info.minor)" 2>/dev/null)
if [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 12 ]; then
    print_status "PASS" "Python version >= 3.12"
else
    print_status "FAIL" "Python version < 3.12 (found $python_major.$python_minor)"
fi

# Check Go version
if command -v go &> /dev/null; then
    go_version=$(go version 2>&1)
    print_status "INFO" "Go version: $go_version"
    
    # Check if Go version is >= 1.22
    go_major=$(go version | grep -o 'go1\.[0-9]*' | sed 's/go1\.//' | head -1)
    if [ -n "$go_major" ] && [ "$go_major" -ge 22 ]; then
        print_status "PASS" "Go version >= 1.22"
    else
        print_status "FAIL" "Go version < 1.22 (found 1.$go_major)"
    fi
else
    print_status "FAIL" "Go is not installed"
fi

echo ""
echo "3. Checking Essential Python Packages..."
echo "-------------------------------------"

# Store results for scoring
python_pkg_total=0
python_pkg_success=0

# Essential packages for Acto core functionality
print_status "INFO" "Checking core Python dependencies..."

essential_packages=(
    "kubernetes"     # Kubernetes client
    "deepdiff"       # State comparison
    "exrex"          # Regular expression generation
    "jsonschema"     # Schema validation
    "jsonpatch"      # JSON patch operations
    "pandas"         # Data analysis
    "yaml"           # YAML processing
    "ruamel.yaml"    # Advanced YAML processing
    "requests"       # HTTP requests
    "pydantic"       # Data validation
    "pytest"         # Testing framework
)

for pkg in "${essential_packages[@]}"; do
    if python -c "import $pkg" 2>/dev/null; then
        print_status "PASS" "Python package '$pkg' is installed"
        ((python_pkg_success++))
    else
        print_status "FAIL" "Python package '$pkg' is not installed"
    fi
    ((python_pkg_total++))
done

# Print proportional score for Python packages
print_proportional_status $python_pkg_success $python_pkg_total 5 "Essential Python packages"

echo ""
echo "4. Testing Acto Module Import and Structure..."
echo "-------------------------------------------"

# Store results for scoring
acto_module_total=0
acto_module_success=0

# Test importing the main acto module
if python -c "import acto; print('Acto module imported successfully')" 2>/dev/null; then
    print_status "PASS" "Acto module can be imported"
    ((acto_module_success++))
else
    print_status "FAIL" "Acto module cannot be imported"
fi
((acto_module_total++))

# Test importing key submodules (only if main module works)
if python -c "import acto" 2>/dev/null; then
    acto_submodules=(
        "acto.engine"           # Core testing engine
        "acto.input"            # Input generation
        "acto.schema"           # Schema processing
        "acto.utils"            # Utility functions
        "acto.system_state"     # System state management
        "acto.kubernetes_engine" # Kubernetes cluster management
        "acto.k8s_util"         # Kubernetes utilities
        "acto.cli"              # Command line tools
    )
    
    for submodule in "${acto_submodules[@]}"; do
        if python -c "import $submodule" 2>/dev/null; then
            print_status "PASS" "$submodule can be imported"
            ((acto_module_success++))
        else
            print_status "FAIL" "$submodule cannot be imported"
        fi
        ((acto_module_total++))
    done
else
    print_status "FAIL" "Acto main module cannot be imported, skipping submodule checks"
fi

# Print proportional score for Acto module structure
print_proportional_status $acto_module_success $acto_module_total 5 "Acto module structure"

echo ""
echo "5. Testing Build System..."
echo "------------------------"

# Test make build
print_status "INFO" "Testing make build..."
make_output=$(timeout 60s make lib 2>&1)
make_result=$?

if [ $make_result -eq 0 ]; then
    print_status "PASS" "Make build completed successfully"
elif [ $make_result -eq 124 ]; then
    print_status "FAIL" "Make build timed out (60 seconds)"
else
    print_status "FAIL" "Make build failed with exit code $make_result"
fi

echo ""
echo "6. Testing CLI Tools..."
echo "----------------------"

# Store results for scoring
cli_tools_total=0
cli_tools_success=0

# Test acto CLI help
acto_cli_output=$(timeout 30s python -m acto --help 2>&1)
acto_cli_result=$?

if [ $acto_cli_result -eq 0 ]; then
    print_status "PASS" "Acto CLI help works"
    ((cli_tools_success++))
elif [ $acto_cli_result -eq 124 ]; then
    print_status "FAIL" "Acto CLI help timed out"
else
    print_status "FAIL" "Acto CLI help failed with exit code $acto_cli_result"
fi
((cli_tools_total++))

# Test reproduce CLI
reproduce_cli_output=$(timeout 30s python -m acto.reproduce --help 2>&1)
reproduce_cli_result=$?

if [ $reproduce_cli_result -eq 0 ]; then
    print_status "PASS" "Acto reproduce CLI help works"
    ((cli_tools_success++))
elif [ $reproduce_cli_result -eq 124 ]; then
    print_status "FAIL" "Acto reproduce CLI help timed out"
else
    print_status "FAIL" "Acto reproduce CLI help failed with exit code $reproduce_cli_result"
fi
((cli_tools_total++))

# Test schema matching CLI
schema_match_output=$(timeout 30s python -m acto.cli.schema_match --help 2>&1)
schema_match_result=$?

if [ $schema_match_result -eq 0 ]; then
    print_status "PASS" "Schema matching CLI help works"
    ((cli_tools_success++))
elif [ $schema_match_result -eq 124 ]; then
    print_status "FAIL" "Schema matching CLI help timed out"
else
    print_status "FAIL" "Schema matching CLI help failed with exit code $schema_match_result"
fi
((cli_tools_total++))

# Test system state collection CLI
collect_state_output=$(timeout 30s python -m acto.cli.collect_system_state --help 2>&1)
collect_state_result=$?

if [ $collect_state_result -eq 0 ]; then
    print_status "PASS" "System state collection CLI help works"
    ((cli_tools_success++))
elif [ $collect_state_result -eq 124 ]; then
    print_status "FAIL" "System state collection CLI help timed out"
else
    print_status "FAIL" "System state collection CLI help failed with exit code $collect_state_result"
fi
((cli_tools_total++))

# Print proportional score for CLI tools
print_proportional_status $cli_tools_success $cli_tools_total 4 "CLI tools functionality"

echo ""
echo "7. Testing Basic Python Code Execution..."
echo "----------------------------------------"

# Test basic Python code execution with Acto module
acto_version_output=$(timeout 30s python -c "
import acto
print('Acto imported successfully')
try:
    from acto import __version__
    print(f'Acto version: {__version__}')
except (ImportError, AttributeError):
    print('Acto version not defined')
try:
    from acto import DEFAULT_KUBERNETES_VERSION
    print(f'Default Kubernetes version: {DEFAULT_KUBERNETES_VERSION}')
except (ImportError, AttributeError):
    print('DEFAULT_KUBERNETES_VERSION not defined')
" 2>&1)

acto_version_result=$?

if [ $acto_version_result -eq 0 ]; then
    print_status "PASS" "Acto basic code execution works"
elif [ $acto_version_result -eq 124 ]; then
    print_status "FAIL" "Acto basic code execution timed out"
else
    print_status "FAIL" "Acto basic code execution failed with exit code $acto_version_result"
fi

echo ""
echo "8. Testing Kubernetes Cluster Creation..."
echo "--------------------------------------"

if command -v kind &> /dev/null && command -v kubectl &> /dev/null; then
    print_status "INFO" "Testing Kind cluster creation (this may take a minute)..."
    
    # Clean up any existing test cluster first
    kind delete cluster --name acto-test-cluster &>/dev/null || true
    
    # Create a simple Kind cluster
    kind_output=$(timeout 180s kind create cluster --name acto-test-cluster 2>&1)
    kind_result=$?
    
    if [ $kind_result -eq 0 ]; then
        print_status "PASS" "Kind cluster creation works"
        
        # Test kubectl connection to the cluster
        kubectl_output=$(timeout 30s kubectl get nodes 2>&1)
        kubectl_result=$?
        
        if [ $kubectl_result -eq 0 ]; then
            print_status "PASS" "kubectl can connect to Kind cluster"
            
            # Count how many nodes are ready
            ready_nodes=$(echo "$kubectl_output" | grep -c "Ready")
            total_nodes=$(echo "$kubectl_output" | grep -c -v "NAME")
            
            print_proportional_status $ready_nodes $total_nodes 3 "Kubernetes nodes ready"
        else
            print_status "FAIL" "kubectl cannot connect to Kind cluster"
        fi
        
        # Clean up the test cluster
        kind delete cluster --name acto-test-cluster &>/dev/null || true
    elif [ $kind_result -eq 124 ]; then
        print_status "FAIL" "Kind cluster creation timed out (3 minutes)"
    else
        print_status "FAIL" "Kind cluster creation failed"
    fi
else
    print_status "FAIL" "kind or kubectl not available to test Kubernetes cluster creation"
fi

echo ""
echo "9. Testing YAML/JSON Processing..."
echo "--------------------------------"

# Test YAML/JSON processing capabilities
yaml_json_output=$(timeout 30s python -c "
import yaml
import json
import jsonpatch
import ruamel.yaml

# Test YAML parsing
yaml_str = '''
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: test-container
    image: nginx
'''

# Parse with standard yaml
yaml_obj = yaml.safe_load(yaml_str)
print(f'YAML parsing: {yaml_obj[\"apiVersion\"]}')

# Parse with ruamel.yaml
ryaml = ruamel.yaml.YAML()
yaml_obj2 = ryaml.load(yaml_str)
print(f'ruamel.yaml parsing: {yaml_obj2[\"apiVersion\"]}')

# Test JSON patch
json_obj = {'foo': 'bar'}
patch = jsonpatch.JsonPatch([{'op': 'add', 'path': '/baz', 'value': 'qux'}])
result = patch.apply(json_obj)
print(f'JSON patch result: {result}')

print('YAML/JSON processing works')
" 2>&1)

yaml_json_result=$?

if [ $yaml_json_result -eq 0 ]; then
    print_status "PASS" "YAML/JSON processing works"
elif [ $yaml_json_result -eq 124 ]; then
    print_status "FAIL" "YAML/JSON processing timed out"
else
    print_status "FAIL" "YAML/JSON processing failed with exit code $yaml_json_result"
fi

echo ""
echo "10. Testing Sample Operator Analysis..."
echo "-------------------------------------"

# Check for sample operator config or test data
if [ -d "test/e2e_tests/test_data" ] || [ -d "test" ] || [ -d "data" ]; then
    print_status "PASS" "Test data directory exists"
    
    # Try to run a simple acto command that doesn't require actual cluster
    # but tests the operator analysis capability
    print_status "INFO" "Running a simple acto analysis test..."
    
    acto_test_output=$(timeout 60s python -c "
import os
import sys

# Add error handling to help debug any issues
try:
    import acto
    print('Acto imported successfully')
    
    # Try to import some key modules needed for analysis
    from acto import schema
    from acto.input import crd, range_inference
    print('Analysis modules imported successfully')
    
    # Look for test data in common locations
    test_locations = [
        'test/e2e_tests/test_data',
        'test',
        'data'
    ]
    
    found = False
    for loc in test_locations:
        if os.path.exists(loc):
            print(f'Found test directory: {loc}')
            subdirs = [os.path.join(loc, d) for d in os.listdir(loc) if os.path.isdir(os.path.join(loc, d))]
            if subdirs:
                print(f'Found {len(subdirs)} potential test cases')
                found = True
            break
    
    if not found:
        print('No test data found')
        sys.exit(1)
        
    print('Sample operator analysis test complete')
except Exception as e:
    print(f'Error during test: {str(e)}')
    sys.exit(1)
" 2>&1)

    acto_test_result=$?
    
    if [ $acto_test_result -eq 0 ]; then
        print_status "PASS" "Sample operator analysis test completed"
    elif [ $acto_test_result -eq 124 ]; then
        print_status "FAIL" "Sample operator analysis test timed out"
    else
        print_status "FAIL" "Sample operator analysis test failed with exit code $acto_test_result"
    fi
else
    print_status "WARN" "No test data directory found, skipping operator analysis test"
fi

echo ""
echo "11. Testing Environment Variables..."
echo "----------------------------------"

# Check if environment variables are set correctly
env_var_total=0
env_var_success=0

if [ -n "${ACTO_HOME}" ]; then
    print_status "PASS" "ACTO_HOME is set: $ACTO_HOME"
    ((env_var_success++))
else
    print_status "WARN" "ACTO_HOME is not set"
fi
((env_var_total++))

if [ -n "${PYTHONPATH}" ]; then
    print_status "PASS" "PYTHONPATH is set: $PYTHONPATH"
    ((env_var_success++))
else
    print_status "WARN" "PYTHONPATH is not set"
fi
((env_var_total++))

if [ -n "${KUBECONFIG}" ]; then
    print_status "PASS" "KUBECONFIG is set: $KUBECONFIG"
    ((env_var_success++))
else
    print_status "WARN" "KUBECONFIG is not set"
fi
((env_var_total++))

# Print proportional score for environment variables
print_proportional_status $env_var_success $env_var_total 3 "Environment variables"

echo ""
echo "12. End-to-End Workflow Test..."
echo "-----------------------------"

print_status "INFO" "This is a complex test that would run an actual bug reproduction..."
print_status "INFO" "In a real environment, this would test: python -m acto.reproduce --reproduce-dir <test_dir> --config <config_file>"
print_status "INFO" "Skipping actual execution as it requires a full Kubernetes cluster and real operator workloads"
print_status "INFO" "In a production environment, this should be run with a timeout of at least 10 minutes"

echo ""
echo "=========================================="
echo "Environment Benchmark Test Complete"
echo "=========================================="

# Summary
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested:"
echo "- System dependencies (Python, Go, kubectl, kind, helm, git, make)"
echo "- Python and Go version compatibility"
echo "- Essential Python packages for Acto"
echo "- Acto module structure and imports"
echo "- Build system functionality"
echo "- CLI tools functionality"
echo "- Basic code execution with Acto"
echo "- Kubernetes cluster creation and management"
echo "- YAML/JSON processing capabilities"
echo "- Sample operator analysis"
echo "- Environment variables"
echo "- End-to-end workflow (information only)"

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
    print_status "INFO" "All tests passed! Your Docker environment is ready for Acto!"
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most tests passed! Your Docker environment is mostly ready for Acto."
    print_status "WARN" "Some dependencies are missing, but core functionality should work."
else
    print_status "WARN" "Many tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the environment is not properly set up."
fi

print_status "INFO" "You can now run Acto tests and reproduce bugs."
print_status "INFO" "Example: python -m acto.reproduce --reproduce-dir test/e2e_tests/test_data/cassop-330/trial-demo --config data/cass-operator/v1-10-3/config.json"
echo ""
print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/acto acto-env-test /bin/bash"
