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
    
    # Source bashrc to make conda available immediately
    source ~/.bashrc
    
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

# Install Docker
install_docker() {
    log_info "Installing Docker..."
    
    detect_system
    
    if [[ "$OS" == "linux" ]]; then
        # Detect package manager
        if command_exists apt-get; then
            # Update package index
            sudo apt-get update
            
            # Install prerequisites
            sudo apt-get install -y ca-certificates curl gnupg lsb-release
            
            # Add Docker's official GPG key
            sudo mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            # Set up the repository
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Update package index again
            sudo apt-get update
            
            # Install Docker Engine
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            
            # Add user to docker group
            sudo usermod -aG docker $USER
            
        elif command_exists yum; then
            # Install Docker on CentOS/RHEL
            sudo yum install -y yum-utils
            sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            
        elif command_exists dnf; then
            # Install Docker on Fedora
            sudo dnf -y install dnf-plugins-core
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            sudo systemctl start docker
            sudo systemctl enable docker
            sudo usermod -aG docker $USER
            
        else
            log_error "No supported package manager found. Please install Docker manually."
            exit 1
        fi
        
        log_success "Docker installed successfully"
        
        # Apply Docker group permissions immediately
        if groups $USER | grep -q docker; then
            log_info "User already in docker group"
        else
            log_info "Adding user to docker group..."
            sudo usermod -aG docker $USER
            log_info "Docker group permissions will be applied in the next shell session"
        fi
        
    elif [[ "$OS" == "macos" ]]; then
        log_info "For macOS, please install Docker Desktop manually from: https://www.docker.com/products/docker-desktop"
        log_warning "Docker Desktop installation requires manual intervention."
        return 0
    fi
}

# Main setup function
main() {
    log_info "🚀 Starting EnvGym setup..."
    log_info ""
    
    # Get Forge API key first
    get_forge_api_key
    
    # Check prerequisites
    check_prerequisites
    
    # Create conda environment
    setup_conda_environment
    
    # Install Python dependencies
    install_python_dependencies
    
    # Setup environment variables
    
    # Download data repositories
    download_data_repositories
    
    log_success "✅ EnvGym setup completed successfully!"
    
    # Auto-execute the next steps by default
    auto_execute_next_steps
}

# Auto-execute next steps function
auto_execute_next_steps() {
    log_info "🔧 Setting up environment..."
    
    # Source bashrc to reload environment
    source ~/.bashrc
    
    # Apply Docker permissions if needed
    if command_exists docker && ! docker info >/dev/null 2>&1; then
        if groups $USER | grep -q docker; then
            newgrp docker <<< "echo 'Docker permissions applied'" >/dev/null 2>&1
        fi
    fi
    
    # Activate conda environment
    export PATH="$HOME/miniconda3/bin:$PATH"
    eval "$(conda shell.bash hook)"
    conda activate envgym >/dev/null 2>&1
    
    # Ask user if they want to test the repo
    log_info ""
    read -p "Do you want to test the repository now? (y/n): " test_repo
    
    if [[ "$test_repo" =~ ^[Yy]$ ]]; then
        log_info "Testing repository..."
        
        # Run the test
        cd data/exli
        python ../../Agent/agent.py
        cd ../..
        
        log_success "Repository test completed!"
        log_success "Setup completed successfully!"
    else
        log_info "Skipping repository test."
        log_success "🎉 EnvGym installation completed successfully!"
        log_info ""
        log_info "┌─────────────────────────────────────────────────────────────┐"
        log_info "│                    Next Steps                              │"
        log_info "└─────────────────────────────────────────────────────────────┘"
        log_info ""
        log_info "To activate the envgym environment:"
        log_info ""
        log_info "  source ~/.bashrc"
        log_info "  conda activate envgym"
        log_info ""
        log_info "Then test the environment:"
        log_info "  cd data/exli && python ../../Agent/agent.py"
        log_info ""
    fi
}

check_prerequisites() {
    log_info "🔍 Checking prerequisites..."
    
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
    
    # Check if Docker is available
    if ! command_exists docker; then
        log_warning "Docker is not installed. Installing Docker automatically..."
        install_docker
    else
        # Test if Docker daemon is running
        if ! docker info >/dev/null 2>&1; then
            log_warning "Docker is installed but daemon is not running. Starting Docker..."
            if command_exists systemctl; then
                sudo systemctl start docker
                sudo systemctl enable docker
            fi
        fi
    fi
    
    # Check if we're in the right directory
    if [ ! -f "requirements.txt" ] || [ ! -d "Agent" ]; then
        log_error "This script must be run from the EnvGym root directory."
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

setup_conda_environment() {
    log_info "🐍 Setting up conda environment..."
    
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
    log_info "📦 Installing Python dependencies..."
    
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

# Get Forge API key from user
get_forge_api_key() {
    log_info "🔑 Setting up Forge API key..."
    
    # Check if .env already exists and has a valid API key
    if [ -f ".env" ]; then
        if grep -q 'FORGE_API_KEY="[^"]*"' .env && ! grep -q 'FORGE_API_KEY="your-forge-api-key-here"' .env; then
            log_info ".env file already exists with API key. Skipping API key setup."
            return 0
        fi
    fi
    
    # Create .env from .env.example if it doesn't exist
    if [ ! -f ".env" ]; then
        if [ ! -f ".env.example" ]; then
            log_error ".env.example not found. Cannot continue."
            exit 1
        fi
        cp .env.example .env
        log_success ".env file created from .env.example"
    fi
    
    # Prompt user for API key
    log_info "Please enter your Forge API key (required for EnvGym to work):"
    while [ -z "$api_key" ]; do
        read -p "Forge API Key: " api_key
        if [ -z "$api_key" ]; then
            log_warning "API key cannot be empty. Please try again."
        fi
    done
    
    # Escape sed-sensitive characters
    escaped_api_key=$(printf '%s\n' "$api_key" | sed -e 's/[\/&]/\\&/g')
    
    # Replace placeholder in .env
    sed -i.bak "s|FORGE_API_KEY=\"your-forge-api-key-here\"|FORGE_API_KEY=\"$escaped_api_key\"|" .env
    rm .env.bak 2>/dev/null || true
    
    log_success "✅ Forge API key saved successfully!"
}

setup_environment_variables() {
    log_info "⚙️  Setting up environment variables..."
    
    # API key is already handled in get_forge_api_key function
    log_success "Environment variables setup completed"
}

download_data_repositories() {
    log_info "📥 Downloading data repositories..."
    
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