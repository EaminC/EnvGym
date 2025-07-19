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

# Detect OS and architecture
detect_system() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi
    
    ARCH=$(uname -m)
    if [[ "$ARCH" == "x86_64" ]]; then
        ARCH="x86_64"
    elif [[ "$ARCH" == "aarch64" ]] || [[ "$ARCH" == "arm64" ]]; then
        ARCH="aarch64"
    else
        log_error "Unsupported architecture: $ARCH"
        exit 1
    fi
}

# Install Miniconda
install_miniconda() {
    log_info "Installing Miniconda..."
    
    detect_system
    
    # Download URL for Miniconda
    if [[ "$OS" == "linux" ]]; then
        if [[ "$ARCH" == "x86_64" ]]; then
            MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
        else
            MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh"
        fi
    elif [[ "$OS" == "macos" ]]; then
        if [[ "$ARCH" == "x86_64" ]]; then
            MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
        else
            MINICONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
        fi
    fi
    
    # Download and install Miniconda
    log_info "Downloading Miniconda..."
    wget -O miniconda.sh "$MINICONDA_URL" || curl -o miniconda.sh "$MINICONDA_URL"
    
    log_info "Installing Miniconda..."
    bash miniconda.sh -b -p "$HOME/miniconda3"
    
    # Add conda to PATH
    export PATH="$HOME/miniconda3/bin:$PATH"
    
    # Initialize conda for bash
    "$HOME/miniconda3/bin/conda" init bash
    
    # Accept conda terms of service
    "$HOME/miniconda3/bin/conda" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
    "$HOME/miniconda3/bin/conda" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
    
    # Clean up
    rm miniconda.sh
    
    log_success "Miniconda installed successfully"
}

# Install Git
install_git() {
    log_info "Installing Git..."
    
    detect_system
    
    if [[ "$OS" == "linux" ]]; then
        # Detect package manager
        if command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y git
        elif command_exists yum; then
            sudo yum install -y git
        elif command_exists dnf; then
            sudo dnf install -y git
        elif command_exists pacman; then
            sudo pacman -S --noconfirm git
        else
            log_error "No supported package manager found. Please install Git manually."
            exit 1
        fi
    elif [[ "$OS" == "macos" ]]; then
        if command_exists brew; then
            brew install git
        else
            log_error "Homebrew not found. Please install Git manually or install Homebrew first."
            exit 1
        fi
    fi
    
    log_success "Git installed successfully"
}

# Install Python command
install_python_command() {
    log_info "Installing python command..."
    
    detect_system
    
    if [[ "$OS" == "linux" ]]; then
        # Detect package manager
        if command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y python-is-python3
        elif command_exists yum; then
            sudo yum install -y python3
            sudo ln -sf /usr/bin/python3 /usr/bin/python
        elif command_exists dnf; then
            sudo dnf install -y python3
            sudo ln -sf /usr/bin/python3 /usr/bin/python
        elif command_exists pacman; then
            sudo pacman -S --noconfirm python
        else
            log_error "No supported package manager found. Please install Python manually."
            exit 1
        fi
    elif [[ "$OS" == "macos" ]]; then
        if command_exists brew; then
            brew install python
        else
            log_error "Homebrew not found. Please install Python manually or install Homebrew first."
            exit 1
        fi
    fi
    
    log_success "Python command installed successfully"
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
        # Check if miniconda is already installed but not in PATH
        if [[ -d "$HOME/miniconda3" ]]; then
            log_info "Miniconda found but not in PATH. Adding to PATH..."
            export PATH="$HOME/miniconda3/bin:$PATH"
            eval "$(conda shell.bash hook)"
        else
            log_warning "Conda is not installed. Installing Miniconda automatically..."
            install_miniconda
            
            # Reload shell environment to make conda available
            export PATH="$HOME/miniconda3/bin:$PATH"
            eval "$(conda shell.bash hook)"
        fi
    fi
    
    # Check if git is installed
    if ! command_exists git; then
        log_warning "Git is not installed. Installing Git automatically..."
        install_git
    fi
    
    # Check if python command is available
    if ! command_exists python; then
        log_warning "Python command is not available. Installing python-is-python3..."
        install_python_command
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
    
    # Ensure conda is available in PATH
    if [[ -d "$HOME/miniconda3" ]]; then
        export PATH="$HOME/miniconda3/bin:$PATH"
        eval "$(conda shell.bash hook)"
    fi
    
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
    
    # Ensure conda is available in PATH
    if [[ -d "$HOME/miniconda3" ]]; then
        export PATH="$HOME/miniconda3/bin:$PATH"
    fi
    
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