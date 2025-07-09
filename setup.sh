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

    # Only proceed if .env does not exist
    if [ ! -f ".env" ]; then
        if [ ! -f ".env.example" ]; then
            log_error ".env.example not found. Cannot continue."
            exit 1
        fi

        cp .env.example .env
        log_success ".env file created from .env.example"

        # Prompt user for API key (loop until provided)
        while [ -z "$api_key" ]; do
            read -p "Enter your Forge API Key (required): " api_key
        done

        # Escape sed-sensitive characters
        escaped_api_key=$(printf '%s\n' "$api_key" | sed -e 's/[\/&]/\\&/g')

        # Replace placeholder in .env (assumes double quotes)
        sed -i.bak "s|FORGE_API_KEY=\"your-forge-api-key-here\"|FORGE_API_KEY=\"$escaped_api_key\"|" .env
        rm .env.bak 2>/dev/null || true

        log_success "Forge API key saved in .env"
        log_info "✅ Environment setup complete. You can now use EnvGym!"
    else
        log_info ".env file already exists. Skipping creation."
    fi
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