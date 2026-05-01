#!/usr/bin/env bash

# Backup envgym outputs from a run/data directory.
# Default mode backs up the full envgym folder.
# Optional mode backs up only envgym.dockerfile.
#
# Usage:
#   bash keep_only_envgym_dockerfiles.sh
#   bash keep_only_envgym_dockerfiles.sh /home/cc/EnvGym/data/<run_dir>
#   MODE=full_envgym bash keep_only_envgym_dockerfiles.sh <run_dir>      # default
#   MODE=dockerfile_only bash keep_only_envgym_dockerfiles.sh <run_dir>

set -euo pipefail

# Same path resolution style as backup_envgym_folders.sh
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TESTS_DIR="$ROOT_DIR/tests"
ENV_FILE="$ROOT_DIR/.env"

SOURCE_DIR="${1:-$SCRIPT_DIR}"
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: source directory not found: $SOURCE_DIR"
    exit 1
fi

MODEL_NAME="unknown_model"
if [ -f "$ENV_FILE" ]; then
    model_line="$(grep -E '^MODEL=' "$ENV_FILE" | tail -n 1)"
    if [ -n "$model_line" ]; then
        MODEL_NAME="${model_line#MODEL=}"
        MODEL_NAME="${MODEL_NAME%\"}"
        MODEL_NAME="${MODEL_NAME#\"}"
    fi
fi

RUN_TS="$(date +%Y%m%d_%H%M%S)"
MODEL_SAFE="$(echo "$MODEL_NAME" | sed 's#[/ ]#_#g' | sed 's#[^A-Za-z0-9._-]#_#g')"
MODE="${MODE:-full_envgym}"
if [ "$MODE" != "full_envgym" ] && [ "$MODE" != "dockerfile_only" ]; then
    echo "Error: MODE must be full_envgym or dockerfile_only"
    exit 1
fi

if [ "$MODE" = "full_envgym" ]; then
    BACKUP_DIR="$TESTS_DIR/backup_${RUN_TS}_${MODEL_SAFE}_envgym"
else
    BACKUP_DIR="$TESTS_DIR/backup_${RUN_TS}_${MODEL_SAFE}_dockerfiles"
fi
mkdir -p "$BACKUP_DIR"

echo "[INFO] Source directory: $SOURCE_DIR"
echo "[INFO] Backup directory: $BACKUP_DIR"
echo "[INFO] Model: $MODEL_NAME"
echo "[INFO] Mode: $MODE"
echo "[INFO] Start backup..."

processed=0
copied=0
skipped=0

for repo_dir in "$SOURCE_DIR"/*; do
    if [ ! -d "$repo_dir" ]; then
        continue
    fi

    repo_name="$(basename "$repo_dir")"
    envgym_dir="$repo_dir/envgym"
    processed=$((processed + 1))

    if [ "$MODE" = "full_envgym" ]; then
        if [ ! -d "$envgym_dir" ]; then
            echo "[WARN] Skip $repo_name: envgym directory not found"
            skipped=$((skipped + 1))
            continue
        fi
        dest_dir="$BACKUP_DIR/$repo_name"
        mkdir -p "$dest_dir"
        cp -a "$envgym_dir" "$dest_dir/"
        echo "[INFO] Copied $repo_name/envgym (full folder)"
        copied=$((copied + 1))
    else
        dockerfile="$envgym_dir/envgym.dockerfile"
        if [ ! -f "$dockerfile" ]; then
            echo "[WARN] Skip $repo_name: envgym.dockerfile not found"
            skipped=$((skipped + 1))
            continue
        fi
        dest_dir="$BACKUP_DIR/$repo_name/envgym"
        mkdir -p "$dest_dir"
        cp -a "$dockerfile" "$dest_dir/"
        echo "[INFO] Copied $repo_name/envgym/envgym.dockerfile"
        copied=$((copied + 1))
    fi
done

echo "[INFO] Done."
echo "[INFO] Processed repos: $processed"
echo "[INFO] Copied repos: $copied"
echo "[INFO] Skipped repos: $skipped"
