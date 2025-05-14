#!/usr/bin/env bash
set -e

# Installs common development dependencies (git, python3, pip) across various systems (apt, yum, brew).
if command -v apt-get >/dev/null; then
  sudo apt-get update
  sudo apt-get install -y git python3 python3-pip
elif command -v yum >/dev/null; then
  sudo yum install -y git python3 python3-pip
elif command -v brew >/dev/null; then
  brew update
  brew install python3
else
  echo "Unsupported package manager. Please install dependencies manually."
  exit 1
fi

echo "Common development dependencies installed."
