#!/usr/bin/env bash
# Installs system dependencies required to build Pony compiler from source.
set -euo pipefail

echo "Updating package lists..."
sudo apt-get update

echo "Installing dependencies..."
sudo apt-get install -y git clang cmake make python3 python3-pip build-essential pkg-config libatomic1 libssl-dev

echo "Initializing submodules..."
git submodule update --init --recursive

echo "Dependency installation complete."
echo "Versions:" 
clang --version
cmake --version
make --version
python3 --version