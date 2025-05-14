#!/usr/bin/env bash
set -e

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <project_dir>"
  exit 1
fi

PROJECT_DIR="$1"
if [[ ! -f "$PROJECT_DIR/requirements.txt" ]]; then
  echo "Error: requirements.txt not found in $PROJECT_DIR"
  exit 1
fi

VENV_DIR="$PROJECT_DIR/venv"
echo "Creating Python virtual environment in $VENV_DIR..."
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
echo "Installing dependencies from requirements.txt..."
pip install -r "$PROJECT_DIR/requirements.txt"
echo "Setup complete. Activate environment with: source $VENV_DIR/bin/activate"