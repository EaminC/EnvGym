#!/usr/bin/env bash
set -e

# Installs dependencies for building autotools-based projects (autoconf, automake, libtool, build-essential) on various systems (apt, yum, brew).
if command -v apt-get >/dev/null; then
    sudo apt-get update
    sudo apt-get install -y build-essential autoconf automake libtool
elif command -v yum >/dev/null; then
    sudo yum install -y gcc gcc-c++ make autoconf automake libtool
elif command -v brew >/dev/null; then
    brew update
    brew install autoconf automake libtool
else
    echo "Unsupported package manager. Please install dependencies manually."
    exit 1
fi

echo "Autotools build dependencies installed."
