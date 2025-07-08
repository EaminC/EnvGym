#!/bin/bash

# EnvGym One-Click Setup Script
# This script automates the setup process for EnvGym environment

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✅]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠️]${NC} $1"
}

log_error() {
    echo -e "${RED}[❌]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main setup function
main() {
    log_info "Starting EnvGym setup..."
    
    # Check prerequisites
    check_prerequisites
    
    # Create conda environment
    setup_conda_environment
    
    # Install Python dependencies
    install_python_dependencies
    
    # Setup environment variables
    setup_environment_variables
    
    # Setup Codex CLI
    setup_codex_cli
    
    # Download data repositories
    download_data_repositories
    
    log_success "EnvGym setup completed successfully!"
    log_info "To activate the environment, run: conda activate envgym"
    log_info "To test the setup, run: cd data/exli && python ../../Agent/agent.py"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if conda is installed
    if ! command_exists conda; then
        log_error "Conda is not installed. Please install Miniconda or Anaconda first."
        log_info "Download from: https://docs.conda.io/en/latest/miniconda.html"
        exit 1
    fi
    
    # Check if git is installed
    if ! command_exists git; then
        log_error "Git is not installed. Please install Git first."
        exit 1
    fi
    
    # Check if we're in the right directory
    if [ ! -f "requirements.txt" ] || [ ! -d "Agent" ]; then
        log_error "This script must be run from the EnvGym root directory."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

setup_conda_environment() {
    log_info "Setting up conda environment..."
    
    # Check if environment already exists
    if conda env list | grep -q "envgym"; then
        log_warning "Environment 'envgym' already exists. Skipping creation."
    else
        log_info "Creating conda environment 'envgym' with Python 3.10..."
        conda create -n envgym python=3.10 -y
        log_success "Conda environment created"
    fi
}

install_python_dependencies() {
    log_info "Installing Python dependencies..."
    
    # Activate conda environment and install dependencies
    eval "$(conda shell.bash hook)"
    conda activate envgym
    
    if [ -f "requirements.txt" ]; then
        pip install -r requirements.txt
        log_success "Python dependencies installed"
    else
        log_warning "requirements.txt not found, skipping Python dependencies"
    fi
}

setup_environment_variables() {
    log_info "Setting up environment variables..."
    
    # Create .env file if it doesn't exist
    if [ ! -f ".env" ]; then
        log_info "Creating .env file..."
        cat > .env << 'EOF'
# OpenAI API Configuration
OPENAI_API_KEY=your-openai-api-key-here

# FORGE API Configuration  
FORGE_API_KEY=your-forge-api-key-here

EOF
        
        log_success ".env file created"
        log_warning "Please edit .env file and add your API keys"
        
        # Prompt for OpenAI API key
        read -p "Enter your OpenAI API Key (or press Enter to skip): " api_key
        if [ -n "$api_key" ]; then
            sed -i.bak "s/your-openai-api-key-here/$api_key/" .env
            rm .env.bak 2>/dev/null || true
            log_success "OpenAI API key saved"
        fi
    else
        log_info ".env file already exists, skipping"
    fi
}

setup_codex_cli() {
    log_info "Setting up Codex CLI..."
    
    cd Agent/tool/codex/codex-cli
    
    # Enable corepack for pnpm
    if command_exists corepack; then
        corepack enable
        log_success "Corepack enabled"
    else
        log_warning "Corepack not found, make sure you have Node.js 16+ installed"
    fi
    
    # Install dependencies
    if command_exists pnpm; then
        log_info "Installing Node.js dependencies..."
        pnpm install
        log_info "Building Codex CLI..."
        pnpm build
        log_success "Codex CLI built successfully"
    else
        log_warning "pnpm not found, please install it manually: npm install -g pnpm"
    fi
    
    # Install native dependencies if script exists
    if [ -f "scripts/install_native_deps.sh" ]; then
        log_info "Installing native dependencies..."
        chmod +x scripts/install_native_deps.sh
        ./scripts/install_native_deps.sh
        log_success "Native dependencies installed"
    fi
    
    # Return to root directory
    cd ../../../../
}

download_data_repositories() {
    log_info "Downloading data repositories..."
    
    cd data
    
    if [ -f "down_one.sh" ]; then
        chmod +x down_one.sh
        bash down_one.sh
        log_success "Data repositories downloaded"
    else
        log_warning "down_one.sh not found, skipping data download"
    fi
    
    # Return to root directory
    cd ..
}

# Run the main function
main "$@" 