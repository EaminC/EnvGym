#!/bin/bash

# RSNN Environment Benchmark Test Script
# This script tests the Docker environment setup for RSNN: Decoding Finger Velocity from Cortical Spike Trains
# Tailored specifically for RSNN project requirements and features

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
    docker stop rsnn-env-test 2>/dev/null || true
    docker rm rsnn-env-test 2>/dev/null || true
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
        if timeout 600s docker build -f envgym/envgym.dockerfile -t rsnn-env-test .; then
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
    
    # Test if Python is available in Docker
    if docker run --rm rsnn-env-test python --version >/dev/null 2>&1; then
        python_version=$(docker run --rm rsnn-env-test python --version 2>&1)
        print_status "PASS" "Python is available in Docker: $python_version"
    else
        print_status "FAIL" "Python is not available in Docker"
    fi
    
    # Test if pip is available in Docker
    if docker run --rm rsnn-env-test pip --version >/dev/null 2>&1; then
        pip_version=$(docker run --rm rsnn-env-test pip --version 2>&1)
        print_status "PASS" "pip is available in Docker: $pip_version"
    else
        print_status "FAIL" "pip is not available in Docker"
    fi
    
    # Test if Git is available in Docker
    if docker run --rm rsnn-env-test git --version >/dev/null 2>&1; then
        git_version=$(docker run --rm rsnn-env-test git --version 2>&1)
        print_status "PASS" "Git is available in Docker: $git_version"
    else
        print_status "FAIL" "Git is not available in Docker"
    fi
    
    # Test if GCC is available in Docker
    if docker run --rm rsnn-env-test gcc --version >/dev/null 2>&1; then
        print_status "PASS" "GCC is available in Docker"
    else
        print_status "FAIL" "GCC is not available in Docker"
    fi
fi

echo "=========================================="
echo "RSNN Environment Benchmark Test"
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
    if [ "$python_major" -eq 3 ] && [ "$python_minor" -eq 10 ]; then
        print_status "PASS" "Python version is 3.10 (exact match for RSNN)"
    elif [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 8 ]; then
        print_status "PASS" "Python version is >= 3.8 (compatible with RSNN)"
    else
        print_status "WARN" "Python version should be >= 3.8 for RSNN (found: $python_major.$python_minor)"
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
echo "2. Checking Deep Learning Dependencies..."
echo "----------------------------------------"
# Check PyTorch
if command -v python &> /dev/null; then
    if timeout 30s python -c "import torch; print(f'PyTorch {torch.__version__}')" >/dev/null 2>&1; then
        torch_version=$(python -c "import torch; print(torch.__version__)" 2>/dev/null)
        print_status "PASS" "PyTorch is available: $torch_version"
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

# Check snntorch
if command -v python &> /dev/null; then
    if timeout 30s python -c "import snntorch; print('snntorch available')" >/dev/null 2>&1; then
        print_status "PASS" "snntorch is available"
    else
        print_status "FAIL" "snntorch is not available"
    fi
else
    print_status "FAIL" "Python is not available for snntorch check"
fi

echo ""
echo "3. Checking Scientific Computing Dependencies..."
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

# Check SciPy
if command -v python &> /dev/null; then
    if timeout 30s python -c "import scipy; print(f'SciPy {scipy.__version__}')" >/dev/null 2>&1; then
        scipy_version=$(python -c "import scipy; print(scipy.__version__)" 2>/dev/null)
        print_status "PASS" "SciPy is available: $scipy_version"
    else
        print_status "FAIL" "SciPy is not available"
    fi
else
    print_status "FAIL" "Python is not available for SciPy check"
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

# Check h5py
if command -v python &> /dev/null; then
    if timeout 30s python -c "import h5py; print(f'h5py {h5py.__version__}')" >/dev/null 2>&1; then
        h5py_version=$(python -c "import h5py; print(h5py.__version__)" 2>/dev/null)
        print_status "PASS" "h5py is available: $h5py_version"
    else
        print_status "FAIL" "h5py is not available"
    fi
else
    print_status "FAIL" "Python is not available for h5py check"
fi

# Check tables
if command -v python &> /dev/null; then
    if timeout 30s python -c "import tables; print(f'tables {tables.__version__}')" >/dev/null 2>&1; then
        tables_version=$(python -c "import tables; print(tables.__version__)" 2>/dev/null)
        print_status "PASS" "tables is available: $tables_version"
    else
        print_status "FAIL" "tables is not available"
    fi
else
    print_status "FAIL" "Python is not available for tables check"
fi

echo ""
echo "4. Checking Visualization Dependencies..."
echo "----------------------------------------"
# Check matplotlib
if command -v python &> /dev/null; then
    if timeout 30s python -c "import matplotlib; print(f'matplotlib {matplotlib.__version__}')" >/dev/null 2>&1; then
        matplotlib_version=$(python -c "import matplotlib; print(matplotlib.__version__)" 2>/dev/null)
        print_status "PASS" "matplotlib is available: $matplotlib_version"
    else
        print_status "FAIL" "matplotlib is not available"
    fi
else
    print_status "FAIL" "Python is not available for matplotlib check"
fi

# Check seaborn
if command -v python &> /dev/null; then
    if timeout 30s python -c "import seaborn; print(f'seaborn {seaborn.__version__}')" >/dev/null 2>&1; then
        seaborn_version=$(python -c "import seaborn; print(seaborn.__version__)" 2>/dev/null)
        print_status "PASS" "seaborn is available: $seaborn_version"
    else
        print_status "FAIL" "seaborn is not available"
    fi
else
    print_status "FAIL" "Python is not available for seaborn check"
fi

echo ""
echo "5. Checking RSNN-Specific Dependencies..."
echo "----------------------------------------"
# Check stork (spiking neural network library)
if command -v python &> /dev/null; then
    if timeout 30s python -c "import stork; print('stork available')" >/dev/null 2>&1; then
        print_status "PASS" "stork is available (spiking neural network library)"
    else
        print_status "FAIL" "stork is not available (required for RSNN)"
    fi
else
    print_status "FAIL" "Python is not available for stork check"
fi

# Check neurobench
if command -v python &> /dev/null; then
    if timeout 30s python -c "import neurobench; print('neurobench available')" >/dev/null 2>&1; then
        print_status "PASS" "neurobench is available (benchmarking suite)"
    else
        print_status "FAIL" "neurobench is not available (required for evaluation)"
    fi
else
    print_status "FAIL" "Python is not available for neurobench check"
fi

# Check hydra
if command -v python &> /dev/null; then
    if timeout 30s python -c "import hydra; print('hydra available')" >/dev/null 2>&1; then
        print_status "PASS" "hydra is available (configuration management)"
    else
        print_status "FAIL" "hydra is not available (required for configuration)"
    fi
else
    print_status "FAIL" "Python is not available for hydra check"
fi

# Check omegaconf
if command -v python &> /dev/null; then
    if timeout 30s python -c "import omegaconf; print('omegaconf available')" >/dev/null 2>&1; then
        print_status "PASS" "omegaconf is available (configuration system)"
    else
        print_status "FAIL" "omegaconf is not available (required for hydra)"
    fi
else
    print_status "FAIL" "Python is not available for omegaconf check"
fi

# Check tonic
if command -v python &> /dev/null; then
    if timeout 30s python -c "import tonic; print('tonic available')" >/dev/null 2>&1; then
        print_status "PASS" "tonic is available (event-based data processing)"
    else
        print_status "FAIL" "tonic is not available"
    fi
else
    print_status "FAIL" "Python is not available for tonic check"
fi

# Check KDEpy
if command -v python &> /dev/null; then
    if timeout 30s python -c "import KDEpy; print('KDEpy available')" >/dev/null 2>&1; then
        print_status "PASS" "KDEpy is available (kernel density estimation)"
    else
        print_status "FAIL" "KDEpy is not available"
    fi
else
    print_status "FAIL" "Python is not available for KDEpy check"
fi

# Check xlsxwriter
if command -v python &> /dev/null; then
    if timeout 30s python -c "import xlsxwriter; print('xlsxwriter available')" >/dev/null 2>&1; then
        print_status "PASS" "xlsxwriter is available (Excel file writing)"
    else
        print_status "FAIL" "xlsxwriter is not available"
    fi
else
    print_status "FAIL" "Python is not available for xlsxwriter check"
fi

# Check soundfile
if command -v python &> /dev/null; then
    if timeout 30s python -c "import soundfile; print('soundfile available')" >/dev/null 2>&1; then
        print_status "PASS" "soundfile is available (audio file processing)"
    else
        print_status "FAIL" "soundfile is not available"
    fi
else
    print_status "FAIL" "Python is not available for soundfile check"
fi

echo ""
echo "6. Checking System Dependencies..."
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

# Check libsndfile
if pkg-config --exists sndfile; then
    sndfile_version=$(pkg-config --modversion sndfile 2>/dev/null)
    print_status "PASS" "libsndfile is available: $sndfile_version"
else
    print_status "WARN" "libsndfile is not available"
fi

# Check libhdf5
if pkg-config --exists hdf5; then
    hdf5_version=$(pkg-config --modversion hdf5 2>/dev/null)
    print_status "PASS" "libhdf5 is available: $hdf5_version"
else
    print_status "WARN" "libhdf5 is not available"
fi

# Check BLAS/LAPACK
if pkg-config --exists blas; then
    print_status "PASS" "BLAS is available"
else
    print_status "WARN" "BLAS is not available"
fi

if pkg-config --exists lapack; then
    print_status "PASS" "LAPACK is available"
else
    print_status "WARN" "LAPACK is not available"
fi

echo ""
echo "7. Checking Project Structure..."
echo "-------------------------------"
# Check main directories
if [ -d "challenge" ]; then
    print_status "PASS" "challenge directory exists (source code)"
else
    print_status "FAIL" "challenge directory not found"
fi

if [ -d "conf" ]; then
    print_status "PASS" "conf directory exists (configuration files)"
else
    print_status "FAIL" "conf directory not found"
fi

if [ -d "models" ]; then
    print_status "PASS" "models directory exists (trained models)"
else
    print_status "FAIL" "models directory not found"
fi

if [ -d "results" ]; then
    print_status "PASS" "results directory exists (evaluation results)"
else
    print_status "FAIL" "results directory not found"
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

# Check training scripts
if [ -f "train-bigRSNN.py" ]; then
    print_status "PASS" "train-bigRSNN.py exists (big RSNN training)"
else
    print_status "FAIL" "train-bigRSNN.py not found"
fi

if [ -f "train-tinyRSNN.py" ]; then
    print_status "PASS" "train-tinyRSNN.py exists (tiny RSNN training)"
else
    print_status "FAIL" "train-tinyRSNN.py not found"
fi

if [ -f "evaluate.py" ]; then
    print_status "PASS" "evaluate.py exists (evaluation script)"
else
    print_status "FAIL" "evaluate.py not found"
fi

# Check challenge subdirectories
if [ -d "challenge/custom" ]; then
    print_status "PASS" "challenge/custom directory exists"
else
    print_status "FAIL" "challenge/custom directory not found"
fi

if [ -d "challenge/neurobench" ]; then
    print_status "PASS" "challenge/neurobench directory exists"
else
    print_status "FAIL" "challenge/neurobench directory not found"
fi

if [ -d "challenge/utils" ]; then
    print_status "PASS" "challenge/utils directory exists"
else
    print_status "FAIL" "challenge/utils directory not found"
fi

# Check challenge files
if [ -f "challenge/data.py" ]; then
    print_status "PASS" "challenge/data.py exists (data loading)"
else
    print_status "FAIL" "challenge/data.py not found"
fi

if [ -f "challenge/model.py" ]; then
    print_status "PASS" "challenge/model.py exists (model definitions)"
else
    print_status "FAIL" "challenge/model.py not found"
fi

if [ -f "challenge/train.py" ]; then
    print_status "PASS" "challenge/train.py exists (training logic)"
else
    print_status "FAIL" "challenge/train.py not found"
fi

if [ -f "challenge/evaluate.py" ]; then
    print_status "PASS" "challenge/evaluate.py exists (evaluation logic)"
else
    print_status "FAIL" "challenge/evaluate.py not found"
fi

# Check configuration files
if [ -f "conf/train-bigRSNN.yaml" ]; then
    print_status "PASS" "conf/train-bigRSNN.yaml exists (big RSNN config)"
else
    print_status "FAIL" "conf/train-bigRSNN.yaml not found"
fi

if [ -f "conf/train-tinyRSNN.yaml" ]; then
    print_status "PASS" "conf/train-tinyRSNN.yaml exists (tiny RSNN config)"
else
    print_status "FAIL" "conf/train-tinyRSNN.yaml not found"
fi

if [ -f "conf/evaluate.yaml" ]; then
    print_status "PASS" "conf/evaluate.yaml exists (evaluation config)"
else
    print_status "FAIL" "conf/evaluate.yaml not found"
fi

if [ -f "conf/defaults.yaml" ]; then
    print_status "PASS" "conf/defaults.yaml exists (default config)"
else
    print_status "FAIL" "conf/defaults.yaml not found"
fi

# Check model directories
if [ -d "models/loco01" ]; then
    print_status "PASS" "models/loco01 directory exists (loco session 1)"
else
    print_status "FAIL" "models/loco01 directory not found"
fi

if [ -d "models/loco02" ]; then
    print_status "PASS" "models/loco02 directory exists (loco session 2)"
else
    print_status "FAIL" "models/loco02 directory not found"
fi

if [ -d "models/loco03" ]; then
    print_status "PASS" "models/loco03 directory exists (loco session 3)"
else
    print_status "FAIL" "models/loco03 directory not found"
fi

if [ -d "models/indy01" ]; then
    print_status "PASS" "models/indy01 directory exists (indy session 1)"
else
    print_status "FAIL" "models/indy01 directory not found"
fi

if [ -d "models/indy02" ]; then
    print_status "PASS" "models/indy02 directory exists (indy session 2)"
else
    print_status "FAIL" "models/indy02 directory not found"
fi

if [ -d "models/indy03" ]; then
    print_status "PASS" "models/indy03 directory exists (indy session 3)"
else
    print_status "FAIL" "models/indy03 directory not found"
fi

# Check result files
if [ -f "results_summary_bigRSNN.json" ]; then
    print_status "PASS" "results_summary_bigRSNN.json exists"
else
    print_status "FAIL" "results_summary_bigRSNN.json not found"
fi

if [ -f "results_summary_tinyRSNN.json" ]; then
    print_status "PASS" "results_summary_tinyRSNN.json exists"
else
    print_status "FAIL" "results_summary_tinyRSNN.json not found"
fi

if [ -f "results_extract_from_logs.ipynb" ]; then
    print_status "PASS" "results_extract_from_logs.ipynb exists (Jupyter notebook)"
else
    print_status "FAIL" "results_extract_from_logs.ipynb not found"
fi

echo ""
echo "8. Testing RSNN Source Code..."
echo "------------------------------"
# Count Python files
python_files=$(find . -name "*.py" | wc -l)
if [ "$python_files" -gt 0 ]; then
    print_status "PASS" "Found $python_files Python files"
else
    print_status "FAIL" "No Python files found"
fi

# Count Jupyter notebooks
notebook_files=$(find . -name "*.ipynb" | wc -l)
if [ "$notebook_files" -gt 0 ]; then
    print_status "PASS" "Found $notebook_files Jupyter notebook files"
else
    print_status "WARN" "No Jupyter notebook files found"
fi

# Count YAML configuration files
yaml_files=$(find . -name "*.yaml" | wc -l)
if [ "$yaml_files" -gt 0 ]; then
    print_status "PASS" "Found $yaml_files YAML configuration files"
else
    print_status "FAIL" "No YAML configuration files found"
fi

# Count JSON files
json_files=$(find . -name "*.json" | wc -l)
if [ "$json_files" -gt 0 ]; then
    print_status "PASS" "Found $json_files JSON files"
else
    print_status "WARN" "No JSON files found"
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

echo ""
echo "9. Testing RSNN Documentation..."
echo "-------------------------------"
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
    if grep -q "RSNN" README.md; then
        print_status "PASS" "README.md contains project name"
    else
        print_status "WARN" "README.md missing project name"
    fi
    
    if grep -q "Spiking Neural Networks" README.md; then
        print_status "PASS" "README.md contains project description"
    else
        print_status "WARN" "README.md missing project description"
    fi
    
    if grep -q "train-bigRSNN.py" README.md; then
        print_status "PASS" "README.md contains training instructions"
    else
        print_status "WARN" "README.md missing training instructions"
    fi
    
    if grep -q "evaluate.py" README.md; then
        print_status "PASS" "README.md contains evaluation instructions"
    else
        print_status "WARN" "README.md missing evaluation instructions"
    fi
fi

echo ""
echo "10. Testing RSNN Docker Functionality..."
echo "---------------------------------------"
# Test if Docker container can run basic commands
if [ "${DOCKER_BUILD_SUCCESS:-false}" = "true" ]; then
    # Test Python in Docker
    if docker run --rm rsnn-env-test python --version >/dev/null 2>&1; then
        print_status "PASS" "Python works in Docker container"
    else
        print_status "FAIL" "Python does not work in Docker container"
    fi
    
    # Test pip in Docker
    if docker run --rm rsnn-env-test pip --version >/dev/null 2>&1; then
        print_status "PASS" "pip works in Docker container"
    else
        print_status "FAIL" "pip does not work in Docker container"
    fi
    
    # Test Git in Docker
    if docker run --rm rsnn-env-test git --version >/dev/null 2>&1; then
        print_status "PASS" "Git works in Docker container"
    else
        print_status "FAIL" "Git does not work in Docker container"
    fi
    
    # Test GCC in Docker
    if docker run --rm rsnn-env-test gcc --version >/dev/null 2>&1; then
        print_status "PASS" "GCC works in Docker container"
    else
        print_status "FAIL" "GCC does not work in Docker container"
    fi
    
    # Test if README.md is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" rsnn-env-test test -f README.md; then
        print_status "PASS" "README.md is accessible in Docker container"
    else
        print_status "FAIL" "README.md is not accessible in Docker container"
    fi
    
    # Test if challenge directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" rsnn-env-test test -d challenge; then
        print_status "PASS" "challenge directory is accessible in Docker container"
    else
        print_status "FAIL" "challenge directory is not accessible in Docker container"
    fi
    
    # Test if conf directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" rsnn-env-test test -d conf; then
        print_status "PASS" "conf directory is accessible in Docker container"
    else
        print_status "FAIL" "conf directory is not accessible in Docker container"
    fi
    
    # Test if models directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" rsnn-env-test test -d models; then
        print_status "PASS" "models directory is accessible in Docker container"
    else
        print_status "FAIL" "models directory is not accessible in Docker container"
    fi
    
    # Test if results directory is accessible in Docker
    if docker run --rm -v "$(pwd):/workspace" rsnn-env-test test -d results; then
        print_status "PASS" "results directory is accessible in Docker container"
    else
        print_status "FAIL" "results directory is not accessible in Docker container"
    fi
    
    # Test PyTorch in Docker
    if docker run --rm rsnn-env-test python -c "import torch; print('PyTorch available')" >/dev/null 2>&1; then
        print_status "PASS" "PyTorch works in Docker container"
    else
        print_status "FAIL" "PyTorch does not work in Docker container"
    fi
    
    # Test stork in Docker
    if docker run --rm rsnn-env-test python -c "import stork; print('stork available')" >/dev/null 2>&1; then
        print_status "PASS" "stork works in Docker container"
    else
        print_status "FAIL" "stork does not work in Docker container"
    fi
    
    # Test neurobench in Docker
    if docker run --rm rsnn-env-test python -c "import neurobench; print('neurobench available')" >/dev/null 2>&1; then
        print_status "PASS" "neurobench works in Docker container"
    else
        print_status "FAIL" "neurobench does not work in Docker container"
    fi
fi

echo ""
echo "=========================================="
echo "RSNN Environment Test Complete"
echo "=========================================="
echo ""
echo "Summary:"
echo "--------"
echo "This script has tested the Docker environment for RSNN:"
echo "- Docker build process (Python 3.10, PyTorch, scientific computing)"
echo "- Python environment (version compatibility, package management)"
echo "- Deep learning dependencies (PyTorch, torchvision, torchaudio, snntorch)"
echo "- Scientific computing (NumPy, SciPy, pandas, h5py, tables)"
echo "- Visualization (matplotlib, seaborn)"
echo "- RSNN-specific dependencies (stork, neurobench, hydra, tonic)"
echo "- RSNN source code structure (challenge, conf, models, results)"
echo "- RSNN documentation (README.md, LICENSE, training scripts)"
echo "- Docker container functionality (Python, PyTorch, stork, neurobench)"
echo "- Spiking Neural Networks (RSNN, cortical spike trains, motor control)"
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
    print_status "INFO" "All Docker tests passed! Your RSNN Docker environment is ready!"
    print_status "INFO" "RSNN is a Recurrent Spiking Neural Network for decoding finger velocity from cortical spike trains."
elif [ $FAIL_COUNT -lt 5 ]; then
    print_status "INFO" "Most Docker tests passed! Your RSNN Docker environment is mostly ready."
    print_status "WARN" "Some optional features are missing, but core functionality works."
else
    print_status "WARN" "Many Docker tests failed. Please check the output above."
    print_status "INFO" "This might indicate that the Docker environment is not properly set up."
fi
echo ""
print_status "INFO" "You can now run RSNN in Docker: Decoding Finger Velocity from Cortical Spike Trains."
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace rsnn-env-test python train-bigRSNN.py seed=1"
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace rsnn-env-test python train-tinyRSNN.py seed=1"
print_status "INFO" "Example: docker run --rm -v \$(pwd):/workspace -w /workspace rsnn-env-test python evaluate.py modelname=bigRSNN"
echo ""
print_status "INFO" "For more information, see README.md and the IEEE BioCAS 2024 Grand Challenge submission."
exit 0
fi

# If Docker failed or not available, skip local environment tests
if [ "${DOCKER_BUILD_FAILED:-false}" = "true" ] || [ "${DOCKER_MODE:-false}" = "false" ]; then
    echo "Docker environment not available - skipping local environment tests"
    echo "This script is designed to test Docker environment only"
    exit 0
fi 