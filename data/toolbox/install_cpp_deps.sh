#!/usr/bin/env bash
set -e

if command -v apt-get >/dev/null; then
    sudo apt-get update
    sudo apt-get install -y build-essential cmake libssl-dev zlib1g-dev libbrotli-dev libcurl4-openssl-dev pkg-config libzstd-dev
elif command -v yum >/dev/null; then
    sudo yum install -y gcc gcc-c++ make cmake openssl-devel zlib-devel brotli-devel libcurl-devel pkgconfig zstd-devel
elif command -v brew >/dev/null; then
    brew update
    brew install cmake openssl zlib brotli curl pkg-config zstd
else
    echo "Unsupported package manager. Please install dependencies manually."
    exit 1
fi

 echo "Dependencies installed."
