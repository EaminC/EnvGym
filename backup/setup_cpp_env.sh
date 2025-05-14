#!/usr/bin/env bash
set -euo pipefail

# Script to install common C++ build environment dependencies

# Detect package manager
if command -v apt-get &>/dev/null; then
    PM=apt-get
elif command -v dnf &>/dev/null; then
    PM=dnf
elif command -v yum &>/dev/null; then
    PM=yum
elif command -v pacman &>/dev/null; then
    PM=pacman
elif command -v brew &>/dev/null; then
    PM=brew
else
    echo "Unsupported package manager. Install dependencies manually."
    exit 1
fi

case "$PM" in
    apt-get)
        sudo apt-get update
        sudo apt-get install -y \
            build-essential cmake python3 python3-pip git curl \
            libssl-dev zlib1g-dev libbrotli-dev libzstd-dev libcurl4-openssl-dev
        ;;
    dnf)
        sudo dnf install -y \
            gcc gcc-c++ make cmake python3 python3-pip git curl \
            openssl-devel zlib-devel brotli-devel zstd-devel libcurl-devel
        ;;
    yum)
        sudo yum install -y \
            gcc gcc-c++ make cmake python3 python3-pip git curl \
            openssl-devel zlib-devel brotli-devel zstd-devel libcurl-devel
        ;;
    pacman)
        sudo pacman -Sy --noconfirm \
            base-devel cmake python python-pip git curl openssl zlib brotli zstd curl
        ;;
    brew)
        brew update
        brew install cmake python openssl zlib brotli zstd curl
        ;;
    *)
        echo "No installation commands for package manager: $PM"
        exit 1
        ;;
esac

echo "C++ build environment setup complete."