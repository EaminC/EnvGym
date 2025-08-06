#!/bin/bash

# SEED-GNN Environment Benchmark Test Script
# This script tests the Docker environment setup for SEED-GNN: A graph neural network framework
# Tailored specifically for SEED-GNN project requirements and features

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
    docker stop seed-gnn-env-test 2>/dev/null || true
    docker rm seed-gnn-env-test 2>/dev/null || true
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
        echo "ERROR: envgym.dockerfile not found. Please run this script from the SEED-GNN project root directory."
        # Write 0 0 0 to JSON
        PASS_COUNT=0
        FAIL_COUNT=0
        WARN_COUNT=0
        write_results_to_json
        exit 1
    fi
    
    # Build Docker image
    echo "Building Docker image..."
    if ! docker build -f envgym/envgym.dockerfile -t seed-gnn-env-test .; then
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
    docker run --rm -v "$(pwd):/home/cc/EnvGym/data/SEED-GNN" seed-gnn-env-test bash -c "
        # Set up signal handling in container
        trap 'echo -e \"\n\033[0;31m[ERROR] Container interrupted\033[0m\"; exit 1' INT TERM
        ./envgym/envbench.sh
    "
    exit 0
fi

echo "=========================================="
echo "SEED-GNN Environment Benchmark Test"
echo "=========================================="

echo "1. Checking Python Environment..."
echo "--------------------------------"
# Check Python version
if command -v python &> /dev/null; then
    python_version=$(python --version 2>&1)
    print_status "PASS" "Python is available: $python_version"
    
    # Check Python version compatibility
    python_major=$(python --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1)
    python_minor=$(python --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f2)
    if [ "$python_major" -eq 3 ] && [ "$python_minor" -eq 9 ]; then
        print_status "PASS" "Python version is 3.9 (exact match for SEED-GNN)"
    elif [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 8 ]; then
        print_status "PASS" "Python version is >= 3.8 (compatible with SEED-GNN)"
    else
        print_status "WARN" "Python version should be >= 3.8 for SEED-GNN (found: $python_major.$python_minor)"
    fi
else
    print_status "FAIL" "Python is not available"
fi

# Check pip
if command -v pip &> /dev/null; then
    pip_version=$(pip --version 2>&1)
    print_status "PASS" "pip is available: $pip_version"
else
    print_status "FAIL" "pip is not available"
fi

# Check Python execution
if command -v python &> /dev/null; then
    if timeout 30s python --version >/dev/null 2>&1; then
        print_status "PASS" "Python execution works"
    else
        print_status "WARN" "Python execution failed"
    fi
    
    # Test Python import
    if timeout 30s python -c "import sys; print('Python import test passed')" >/dev/null 2>&1; then
        print_status "PASS" "Python import works"
    else
        print_status "WARN" "Python import failed"
    fi
else
    print_status "FAIL" "Python is not available for testing"
fi

echo ""
echo "2. Checking PyTorch Ecosystem..."
echo "-------------------------------"
# Check PyTorch
if command -v python &> /dev/null; then
    if timeout 30s python -c "import torch; print(f'PyTorch {torch.__version__}')" >/dev/null 2>&1; then
        torch_version=$(python -c "import torch; print(torch.__version__)" 2>/dev/null)
        print_status "PASS" "PyTorch is available: $torch_version"
        
        # Check PyTorch version compatibility
        if echo "$torch_version" | grep -q "2.0.0"; then
            print_status "PASS" "PyTorch version is 2.0.0 (exact match for SEED-GNN)"
        elif echo "$torch_version" | grep -q "2.0"; then
            print_status "PASS" "PyTorch version is 2.0.x (compatible with SEED-GNN)"
        else
            print_status "WARN" "PyTorch version should be 2.0.0 for SEED-GNN (found: $torch_version)"
        fi
    else
        print_status "FAIL" "PyTorch is not available"
    fi
else
    print_status "FAIL" "Python is not available for PyTorch check"
fi

# Check torchvision
if command -v python &> /dev/null; then
    if timeout 30s python -c "import torchvision; print(f'torchvision {torchvision.__version__}')" >/dev/null 2>&1; then
        torchvision_version=$(python -c "import torchvision; print(torchvision.__version__)" 2>/dev/null)
        print_status "PASS" "torchvision is available: $torchvision_version"
    else
        print_status "FAIL" "torchvision is not available"
    fi
else
    print_status "FAIL" "Python is not available for torchvision check"
fi

# Check torchaudio
if command -v python &> /dev/null; then
    if timeout 30s python -c "import torchaudio; print(f'torchaudio {torchaudio.__version__}')" >/dev/null 2>&1; then
        torchaudio_version=$(python -c "import torchaudio; print(torchaudio.__version__)" 2>/dev/null)
        print_status "PASS" "torchaudio is available: $torchaudio_version"
    else
        print_status "FAIL" "torchaudio is not available"
    fi
else
    print_status "FAIL" "Python is not available for torchaudio check"
fi

echo ""
echo "3. Checking PyTorch Geometric (PyG) Dependencies..."
echo "--------------------------------------------------"
# Check torch-geometric
if command -v python &> /dev/null; then
    if timeout 30s python -c "import torch_geometric; print(f'torch-geometric {torch_geometric.__version__}')" >/dev/null 2>&1; then
        pyg_version=$(python -c "import torch_geometric; print(torch_geometric.__version__)" 2>/dev/null)
        print_status "PASS" "torch-geometric is available: $pyg_version"
    else
        print_status "FAIL" "torch-geometric is not available (required for GNN)"
    fi
else
    print_status "FAIL" "Python is not available for torch-geometric check"
fi

# Check torch-scatter
if command -v python &> /dev/null; then
    if timeout 30s python -c "import torch_scatter; print('torch-scatter available')" >/dev/null 2>&1; then
        print_status "PASS" "torch-scatter is available"
    else
        print_status "FAIL" "torch-scatter is not available (required for PyG)"
    fi
else
    print_status "FAIL" "Python is not available for torch-scatter check"
fi

# Check torch-cluster
if command -v python &> /dev/null; then
    if timeout 30s python -c "import torch_cluster; print('torch-cluster available')" >/dev/null 2>&1; then
        print_status "PASS" "torch-cluster is available"
    else
        print_status "FAIL" "torch-cluster is not available (required for PyG)"
    fi
else
    print_status "FAIL" "Python is not available for torch-cluster check"
fi

# Check torch-spline-conv
if command -v python &> /dev/null; then
    if timeout 30s python -c "import torch_spline_conv; print('torch-spline-conv available')" >/dev/null 2>&1; then
        print_status "PASS" "torch-spline-conv is available"
    else
        print_status "FAIL" "torch-spline-conv is not available (required for PyG)"
    fi
else
    print_status "FAIL" "Python is not available for torch-spline-conv check"
fi

# Check torch-sparse
if command -v python &> /dev/null; then
    if timeout 30s python -c "import torch_sparse; print('torch-sparse available')" >/dev/null 2>&1; then
        print_status "PASS" "torch-sparse is available"
    else
        print_status "FAIL" "torch-sparse is not available (required for PyG)"
    fi
else
    print_status "FAIL" "Python is not available for torch-sparse check"
fi

echo ""
echo "4. Checking Scientific Computing Dependencies..."
echo "-----------------------------------------------"
# Check NumPy
if command -v python &> /dev/null; then
    if timeout 30s python -c "import numpy; print(f'NumPy {numpy.__version__}')" >/dev/null 2>&1; then
        numpy_version=$(python -c "import numpy; print(numpy.__version__)" 2>/dev/null)
        print_status "PASS" "NumPy is available: $numpy_version"
    else
        print_status "FAIL" "NumPy is not available"
    fi
else
    print_status "FAIL" "Python is not available for NumPy check"
fi

# Check pandas
if command -v python &> /dev/null; then
    if timeout 30s python -c "import pandas; print(f'pandas {pandas.__version__}')" >/dev/null 2>&1; then
        pandas_version=$(python -c "import pandas; print(pandas.__version__)" 2>/dev/null)
        print_status "PASS" "pandas is available: $pandas_version"
    else
        print_status "FAIL" "pandas is not available"
    fi
else
    print_status "FAIL" "Python is not available for pandas check"
fi

# Check OGB (Open Graph Benchmark)
if command -v python &> /dev/null; then
    if timeout 30s python -c "import ogb; print(f'OGB {ogb.__version__}')" >/dev/null 2>&1; then
        ogb_version=$(python -c "import ogb; print(ogb.__version__)" 2>/dev/null)
        print_status "PASS" "OGB is available: $ogb_version"
    else
        print_status "FAIL" "OGB is not available (required for graph datasets)"
    fi
else
    print_status "FAIL" "Python is not available for OGB check"
fi

echo ""
echo "5. Checking System Dependencies..."
echo "---------------------------------"
# Check Git
if command -v git &> /dev/null; then
    git_version=$(git --version 2>&1)
    print_status "PASS" "Git is available: $git_version"
else
    print_status "FAIL" "Git is not available"
fi

# Check GCC
if command -v gcc &> /dev/null; then
    gcc_version=$(gcc --version 2>&1 | head -n 1)
    print_status "PASS" "GCC is available: $gcc_version"
else
    print_status "FAIL" "GCC is not available"
fi

# Check build-essential
if command -v make &> /dev/null; then
    make_version=$(make --version 2>&1 | head -n 1)
    print_status "PASS" "make is available: $make_version"
else
    print_status "FAIL" "make is not available"
fi

# Check wget
if command -v wget &> /dev/null; then
    wget_version=$(wget --version 2>&1 | head -n 1)
    print_status "PASS" "wget is available: $wget_version"
else
    print_status "FAIL" "wget is not available"
fi

echo ""
echo "6. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "models" ]; then
    print_status "PASS" "models directory exists (GNN model implementations)"
else
    print_status "FAIL" "models directory not found"
fi

if [ -d "pipelines" ]; then
    print_status "PASS" "pipelines directory exists (training and editing pipelines)"
else
    print_status "FAIL" "pipelines directory not found"
fi

if [ -d "scripts" ]; then
    print_status "PASS" "scripts directory exists (experiment scripts)"
else
    print_status "FAIL" "scripts directory not found"
fi

if [ -d "config" ]; then
    print_status "PASS" "config directory exists (configuration files)"
else
    print_status "FAIL" "config directory not found"
fi

if [ -d "edit_gnn" ]; then
    print_status "PASS" "edit_gnn directory exists (GNN editing implementations)"
else
    print_status "FAIL" "edit_gnn directory not found"
fi

if [ -d "visualization" ]; then
    print_status "PASS" "visualization directory exists (visualization tools)"
else
    print_status "FAIL" "visualization directory not found"
fi

# Check key files
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

if [ -f "requirements.txt" ]; then
    print_status "PASS" "requirements.txt exists"
else
    print_status "FAIL" "requirements.txt not found"
fi

if [ -f "main.py" ]; then
    print_status "PASS" "main.py exists (main entry point)"
else
    print_status "FAIL" "main.py not found"
fi

if [ -f "main_utils.py" ]; then
    print_status "PASS" "main_utils.py exists (utility functions)"
else
    print_status "FAIL" "main_utils.py not found"
fi

if [ -f "data.py" ]; then
    print_status "PASS" "data.py exists (data loading)"
else
    print_status "FAIL" "data.py not found"
fi

if [ -f "constants.py" ]; then
    print_status "PASS" "constants.py exists (project constants)"
else
    print_status "FAIL" "constants.py not found"
fi

# Check models subdirectories
if [ -f "models/__init__.py" ]; then
    print_status "PASS" "models/__init__.py exists"
else
    print_status "FAIL" "models/__init__.py not found"
fi

if [ -f "models/base.py" ]; then
    print_status "PASS" "models/base.py exists (base model class)"
else
    print_status "FAIL" "models/base.py not found"
fi

if [ -f "models/gcn.py" ]; then
    print_status "PASS" "models/gcn.py exists (GCN model)"
else
    print_status "FAIL" "models/gcn.py not found"
fi

if [ -f "models/gat.py" ]; then
    print_status "PASS" "models/gat.py exists (GAT model)"
else
    print_status "FAIL" "models/gat.py not found"
fi

if [ -f "models/gin.py" ]; then
    print_status "PASS" "models/gin.py exists (GIN model)"
else
    print_status "FAIL" "models/gin.py not found"
fi

if [ -f "models/sage.py" ]; then
    print_status "PASS" "models/sage.py exists (GraphSAGE model)"
else
    print_status "FAIL" "models/sage.py not found"
fi

if [ -f "models/mlp.py" ]; then
    print_status "PASS" "models/mlp.py exists (MLP model)"
else
    print_status "FAIL" "models/mlp.py not found"
fi

# Check scripts subdirectories
if [ -d "scripts/pretrain" ]; then
    print_status "PASS" "scripts/pretrain directory exists (pretraining scripts)"
else
    print_status "FAIL" "scripts/pretrain directory not found"
fi

if [ -d "scripts/edit" ]; then
    print_status "PASS" "scripts/edit directory exists (editing scripts)"
else
    print_status "FAIL" "scripts/edit directory not found"
fi

# Check config subdirectories
if [ -d "config/pipeline_config" ]; then
    print_status "PASS" "config/pipeline_config directory exists (pipeline configurations)"
else
    print_status "FAIL" "config/pipeline_config directory not found"
fi

if [ -d "config/eval_config" ]; then
    print_status "PASS" "config/eval_config directory exists (evaluation configurations)"
else
    print_status "FAIL" "config/eval_config directory not found"
fi

echo ""
echo "7. Testing SEED-GNN Source Code..."
echo "----------------------------------"
# Count Python files
python_files=$(find . -name "*.py" | wc -l)
if [ "$python_files" -gt 0 ]; then
    print_status "PASS" "Found $python_files Python files"
else
    print_status "FAIL" "No Python files found"
fi

# Count JSON configuration files
json_files=$(find . -name "*.json" | wc -l)
if [ "$json_files" -gt 0 ]; then
    print_status "PASS" "Found $json_files JSON configuration files"
else
    print_status "WARN" "No JSON configuration files found"
fi

# Count shell scripts
sh_files=$(find . -name "*.sh" | wc -l)
if [ "$sh_files" -gt 0 ]; then
    print_status "PASS" "Found $sh_files shell script files"
else
    print_status "WARN" "No shell script files found"
fi

# Test Python syntax
if command -v python &> /dev/null; then
    print_status "INFO" "Testing Python syntax..."
    syntax_errors=0
    for py_file in $(find . -name "*.py"); do
        if ! timeout 30s python -m py_compile "$py_file" >/dev/null 2>&1; then
            ((syntax_errors++))
        fi
    done
    
    if [ "$syntax_errors" -eq 0 ]; then
        print_status "PASS" "All Python files have valid syntax"
    else
        print_status "WARN" "Found $syntax_errors Python files with syntax errors"
    fi
else
    print_status "FAIL" "Python is not available for syntax checking"
fi

# Test GNN model imports
if command -v python &> /dev/null; then
    print_status "INFO" "Testing GNN model imports..."
    
    # Test base model import
    if timeout 30s python -c "from models.base import BaseModel; print('BaseModel import successful')" >/dev/null 2>&1; then
        print_status "PASS" "BaseModel import works"
    else
        print_status "WARN" "BaseModel import failed"
    fi
    
    # Test GCN model import
    if timeout 30s python -c "from models.gcn import GCN; print('GCN import successful')" >/dev/null 2>&1; then
        print_status "PASS" "GCN import works"
    else
        print_status "WARN" "GCN import failed"
    fi
    
    # Test GAT model import
    if timeout 30s python -c "from models.gat import GAT; print('GAT import successful')" >/dev/null 2>&1; then
        print_status "PASS" "GAT import works"
    else
        print_status "WARN" "GAT import failed"
    fi
    
    # Test GIN model import
    if timeout 30s python -c "from models.gin import GIN; print('GIN import successful')" >/dev/null 2>&1; then
        print_status "PASS" "GIN import works"
    else
        print_status "WARN" "GIN import failed"
    fi
    
    # Test GraphSAGE model import
    if timeout 30s python -c "from models.sage import GraphSAGE; print('GraphSAGE import successful')" >/dev/null 2>&1; then
        print_status "PASS" "GraphSAGE import works"
    else
        print_status "WARN" "GraphSAGE import failed"
    fi
else
    print_status "FAIL" "Python is not available for model import testing"
fi

echo ""
echo "8. Testing SEED-GNN Documentation..."
echo "-----------------------------------"
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

# Check README content
if [ -r "README.md" ]; then
    if grep -q "SEED-GNN" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "GNN" README.md; then
        print_status "PASS" "README.md contains GNN description"
    else
        print_status "WARN" "README.md missing GNN description"
    fi
    
    if grep -q "model editing" README.md; then
        print_status "PASS" "README.md contains model editing description"
    else
        print_status "WARN" "README.md missing model editing description"
    fi
    
    if grep -q "main.py" README.md; then
        print_status "PASS" "README.md contains usage instructions"
    else
        print_status "WARN" "README.md missing usage instructions"
    fi
    
    if grep -q "ICML" README.md; then
        print_status "PASS" "README.md contains ICML 2024 reference"
    else
        print_status "WARN" "README.md missing ICML 2024 reference"
    fi
fi

echo ""
echo "9. Testing SEED-GNN Docker Functionality..."
echo "-------------------------------------------"
# Test if Docker container can run basic commands
if [ -f /.dockerenv ] || grep -q docker /proc/1/cgroup 2>/dev/null; then
    # Test Python in Docker
    if docker run --rm seed-gnn-env-test python --version >/dev/null 2>&1; then
        print_status "PASS" "Python works in Docker container"
    else
        print_status "FAIL" "Python does not work in Docker container"
    fi
    
    # Test pip in Docker
    if docker run --rm seed-gnn-env-test pip --version >/dev/null 2>&1; then
        print_status "PASS" "pip works in Docker container"
    else
        print_status "FAIL" "pip does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm seed-gnn-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test GCC in Docker
    if docker run --rm seed-gnn-env-test gcc --version >/dev/null 2>&1; then
        print_status "PASS" "GCC works in Docker container"
    else
        print_status "FAIL" "GCC does not work in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" seed-gnn-env-test test -f README.md; then
        print_status "PASS" "README.md is accessible in Docker container"
    else
        print_status "FAIL" "README.md is not accessible in Docker container"
    fi
    
    # Test if models directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" seed-gnn-env-test test -d models; then
        print_status "PASS" "models directory is accessible in Docker container"
    else
        print_status "FAIL" "models directory is not accessible in Docker container"
    fi
    
    # Test if scripts directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" seed-gnn-env-test test -d scripts; then
        print_status "PASS" "scripts directory is accessible in Docker container"
    else
        print_status "FAIL" "scripts directory is not accessible in Docker container"
    fi
    
    # Test if config directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" seed-gnn-env-test test -d config; then
        print_status "PASS" "config directory is accessible in Docker container"
    else
        print_status "FAIL" "config directory is not accessible in Docker container"
    fi
    
    # Test PyTorch in Docker
    if docker run --rm seed-gnn-env-test python -c "import torch; print('PyTorch available')" >/dev/null 2>&1; then
        print_status "PASS" "PyTorch works in Docker container"
    else
        print_status "FAIL" "PyTorch does not work in Docker container"
    fi
    
    # Test torch-geometric in Docker
    if docker run --rm seed-gnn-env-test python -c "import torch_geometric; print('torch-geometric available')" >/dev/null 2>&1; then
        print_status "PASS" "torch-geometric works in Docker container"
    else
        print_status "FAIL" "torch-geometric does not work in Docker container"
    fi
    
    # Test torch-scatter in Docker
    if docker run --rm seed-gnn-env-test python -c "import torch_scatter; print('torch-scatter available')" >/dev/null 2>&1; then
        print_status "PASS" "torch-scatter works in Docker container"
    else
        print_status "FAIL" "torch-scatter does not work in Docker container"
    fi
    
    # Test OGB in Docker
    if docker run --rm seed-gnn-env-test python -c "import ogb; print('OGB available')" >/dev/null 2>&1; then
        print_status "PASS" "OGB works in Docker container"
    else
        print_status "FAIL" "OGB does not work in Docker container"
    fi
fi

echo ""
echo "=========================================="
echo "Docker Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for SEED-GNN:"
echo "- Docker build process (Ubuntu 22.04, Python, PyTorch)"
echo "- Python environment (version compatibility, module loading)"
echo "- PyTorch environment (deep learning, graph neural networks)"
echo "- SEED-GNN build system (Python scripts, models)"
echo "- SEED-GNN source code (main.py, data.py, main_utils.py)"
echo "- SEED-GNN documentation (README.md, usage instructions)"
echo "- SEED-GNN configuration (requirements.txt, config, models)"
echo "- Docker container functionality (Python, PyTorch, ML tools)"
echo "- Graph Neural Networks capabilities"

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
    print_status "INFO" "All Docker tests passed! Your SEED-GNN Docker environment is ready!"
    print_status "INFO" "SEED-GNN is a graph neural network framework."
elif [ $FINAL_FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your SEED-GNN Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi

print_status "INFO" "You can now run SEED-GNN in Docker: A graph neural network framework."
print_status "INFO" "Example: docker run --rm seed-gnn-env-test python main.py"

echo ""
print_status "INFO" "For more information, see README.md"

print_status "INFO" "To start interactive container: docker run -it --rm -v \$(pwd):/home/cc/EnvGym/data/SEED-GNN seed-gnn-env-test /bin/bash" 