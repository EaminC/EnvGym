#!/usr/bin/env bash
set -e

# bootstrap_project.sh: Bootstrap a project by running its scripts/setup-deps.sh,
# then building and installing it. This is intended for repositories following
# the convention of having a scripts/setup-deps.sh script and a Makefile.

usage() {
  echo "Usage: $0 -r <repo_dir> [-t <Debug|Release>] [-o <override>...]"
  exit 1
}

REPO_DIR=""
BUILD_TYPE="Debug"
OVERRIDES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--repo-dir)
      REPO_DIR="$2"; shift 2;;
    -r=*|--repo-dir=*)
      REPO_DIR="${1#*=}"; shift;;
    -t|--build-type)
      BUILD_TYPE="$2"; shift 2;;
    -t=*|--build-type=*)
      BUILD_TYPE="${1#*=}"; shift;;
    -o|--override)
      OVERRIDES+=("$2"); shift 2;;
    -o=*|--override=*)
      OVERRIDES+=("${1#*=}"); shift;;
    -h|--help)
      usage;;
    *)
      echo "Unknown option: $1"; usage;;
  esac
done

if [[ -z "$REPO_DIR" ]]; then
  echo "Error: repo_dir is required."
  usage
fi

# Run dependency bootstrap if present
if [[ -x "$REPO_DIR/scripts/setup-deps.sh" ]]; then
  echo "Running $REPO_DIR/scripts/setup-deps.sh..."
  pushd "$REPO_DIR/scripts" > /dev/null
  ./setup-deps.sh -b "$REPO_DIR" -t "$BUILD_TYPE" ${OVERRIDES[@]}
  popd > /dev/null
else
  echo "No setup-deps.sh found or not executable in $REPO_DIR/scripts, skipping dependency setup."
fi

# Build and install
if [[ -f "$REPO_DIR/Makefile" ]]; then
  echo "Building project in $REPO_DIR..."
  pushd "$REPO_DIR" > /dev/null
  make -j "$(nproc)"
  echo "Installing project..."
  sudo make install
  popd > /dev/null
else
  echo "No Makefile found in $REPO_DIR, skipping build."
fi