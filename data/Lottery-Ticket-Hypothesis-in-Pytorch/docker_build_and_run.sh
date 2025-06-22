#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="envgym/log.txt"
mkdir -p "$(dirname "$LOG_FILE")"
{
  echo "=== $(date '+%Y-%m-%d %H:%M:%S') Docker build ==="
  docker build -t lottery-ticket -f envgym/envgym.dockerfile .

  echo "=== $(date '+%Y-%m-%d %H:%M:%S') Docker run ==="
  docker run --rm -it lottery-ticket
} 2>&1 | tee -a "$LOG_FILE"