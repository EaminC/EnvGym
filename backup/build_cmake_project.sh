#!/usr/bin/env bash
set -euo pipefail

# Script to configure, build, and optionally test a CMake-based C++ project

usage() {
  echo "Usage: $0 -r <repo_dir> [-b <build_dir>] [-t <build_type>] [-j <jobs>] [--cmake-args <args>] [--test]"
  exit 1
}

REPO_DIR=""
BUILD_DIR=""
BUILD_TYPE="Release"
JOBS="$(nproc)"
CMARGS=""
RUN_TESTS=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--repo-dir) REPO_DIR="$2"; shift 2;;
    -r=*|--repo-dir=*) REPO_DIR="${1#*=}"; shift;;
    -b|--build-dir) BUILD_DIR="$2"; shift 2;;
    -b=*|--build-dir=*) BUILD_DIR="${1#*=}"; shift;;
    -t|--build-type) BUILD_TYPE="$2"; shift 2;;
    -t=*|--build-type=*) BUILD_TYPE="${1#*=}"; shift;;
    -j|--jobs) JOBS="$2"; shift 2;;
    -j=*|--jobs=*) JOBS="${1#*=}"; shift;;
    --cmake-args) CMARGS="$2"; shift 2;;
    --cmake-args=*) CMARGS="${1#*=}"; shift;;
    --test) RUN_TESTS=true; shift;;
    -h|--help) usage;;
    *) echo "Unknown option: $1"; usage;;
  esac
done

# Ensure project directory is provided and resolve its absolute path
if [[ -z "$REPO_DIR" ]]; then
  echo "Error: repo_dir is required."
  usage
fi
# Resolve REPO_DIR to an absolute path for CMake
REPO_DIR="$(cd "$REPO_DIR" && pwd)"

# Default build directory if not provided
if [[ -z "$BUILD_DIR" ]]; then
  BUILD_DIR="$REPO_DIR/build"
fi

echo "Configuring project in $REPO_DIR..."
mkdir -p "$BUILD_DIR"
pushd "$BUILD_DIR" > /dev/null
cmake -DCMAKE_BUILD_TYPE="$BUILD_TYPE" $CMARGS "$REPO_DIR"
echo "Building project..."
cmake --build . -- -j"$JOBS"
if [[ "$RUN_TESTS" == "true" ]]; then
  echo "Running tests..."
  cmake --build . --target test
fi
popd > /dev/null

echo "Build completed."