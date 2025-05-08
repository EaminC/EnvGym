#!/usr/bin/env bash
set -e
# Create Python virtual environment and install common packages
if [ -z "$1" ]; then
    echo "Usage: $0 <venv_dir>"
    exit 1
fi
python3 -m venv "$1"
source "$1/bin/activate"
echo "Upgrading pip and installing numpy, scipy, matplotlib"
pip install --upgrade pip
pip install numpy scipy matplotlib
