#!/bin/bash

# Custom dataset runner for EnvGym Agent
# Usage:
#   bash run_agent_custom_dataset.sh
#   CLONE_ONLY=1 bash run_agent_custom_dataset.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_SCRIPT="$SCRIPT_DIR/../Agent/agent.py"
ENV_FILE="$SCRIPT_DIR/../.env"

# Set to 1 to clone/update only and skip running agent.py
CLONE_ONLY="${CLONE_ONLY:-0}"

if [ ! -f "$AGENT_SCRIPT" ]; then
    echo "Error: Cannot find $AGENT_SCRIPT"
    echo "Please ensure Agent/agent.py exists"
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is not installed or not in PATH"
    exit 1
fi

# Resolve model name from .env (fallback to unknown_model)
MODEL_NAME="unknown_model"
if [ -f "$ENV_FILE" ]; then
    model_line="$(grep -E '^MODEL=' "$ENV_FILE" | tail -n 1)"
    if [ -n "$model_line" ]; then
        MODEL_NAME="${model_line#MODEL=}"
        MODEL_NAME="${MODEL_NAME%\"}"
        MODEL_NAME="${MODEL_NAME#\"}"
    fi
fi

# Create run directory: timestamp + model name
RUN_TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
MODEL_SAFE="$(echo "$MODEL_NAME" | sed 's#[/ ]#_#g' | sed 's#[^A-Za-z0-9._-]#_#g')"
RUN_TAG="${RUN_TIMESTAMP}_${MODEL_SAFE}"
RUN_DIR="$SCRIPT_DIR/$RUN_TAG"
LOG_FILE="$RUN_DIR/run_agent_custom_dataset.log"

mkdir -p "$RUN_DIR"

# dataset format:
# local_dir|github_url|cpu|ram|gpu|disk
DATASET=(
    "tao_tutorials|https://github.com/NVIDIA/tao_tutorials|>=8 cores|>=16 GB|NVIDIA GPU >=16 GB VRAM (recommended)|>=100 GB SSD (recommended)"
    "NeMo_Gym|https://github.com/NVIDIA-NeMo/Gym|Modern x86_64 or ARM|>=8 GB (16 GB recommended)|Not required|>=5 GB"
    "ai-avatar|https://github.com/mariocandela/ai-avatar|Not specified|>=8 GB|NVIDIA GPU >=4 GB VRAM|>=40 GB"
    "Kilosort4|https://github.com/snel-repo/Kilosort4|Not specified|Not specified|NVIDIA GPU >=8 GB VRAM|Not specified"
    "CLM-GS|https://github.com/nyu-systems/CLM-GS|Not specified|~128 GB recommended for large scenes|GPU ~24 GB VRAM|Not specified"
    "CellViT-plus-plus|https://github.com/TIO-IKIM/CellViT-plus-plus|>=16 cores|>=32 GB|>=24 GB VRAM CUDA GPU|>=30 GB"
    "CellViT-Inference|https://github.com/TIO-IKIM/CellViT-Inference|>=16 cores|>=32 GB|>=24 GB VRAM CUDA GPU|>=30 GB"
    "plonky2-gpu|https://github.com/sideprotocol/plonky2-gpu|8 cores|16 GB|NVIDIA 2080 Ti (12 GB VRAM)|Not specified"
    "SVRTK_Docker_GPU|https://github.com/SVRTK/svrtk-docker-gpu|>=6 cores|16 GB|NVIDIA GPU >=12 GB VRAM|>=30 GB"
    "node0|https://github.com/PluralisResearch/node0|Not specified|>=32 GB|>=16 GB GPU memory|>=80 GB"
    "SciDOCX|https://github.com/EsmaeilNarimissa/SciDOCX|8 cores|16 GB|>=6 GB VRAM|>=5 GB"
    "U-Time|https://github.com/perslev/U-Time|>=4 cores|>=8 GB|CUDA GPU recommended|Dataset dependent (TB possible)"
    "nesa_bootstrap|https://github.com/nesaorg/bootstrap|>=4 cores|>=16 GB|NVIDIA GPU >=8 GB VRAM recommended|>=100 GB"
    "pdf-to-podcast|https://github.com/NVIDIA-AI-Blueprints/pdf-to-podcast|8 cores|64 GB|Optional|>=100 GB"
)

total_count=0
run_ok=0
run_fail=0
clone_ok=0
clone_fail=0
skipped_run=0

echo "==== EnvGym Custom Dataset Runner ====" | tee "$LOG_FILE"
echo "Script directory: $SCRIPT_DIR" | tee -a "$LOG_FILE"
echo "Run directory: $RUN_DIR" | tee -a "$LOG_FILE"
echo "Model: $MODEL_NAME" | tee -a "$LOG_FILE"
echo "Agent script: $AGENT_SCRIPT" | tee -a "$LOG_FILE"
echo "Total entries: ${#DATASET[@]}" | tee -a "$LOG_FILE"
echo "CLONE_ONLY: $CLONE_ONLY" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

for item in "${DATASET[@]}"; do
    total_count=$((total_count + 1))
    IFS='|' read -r repo_dir repo_url cpu_req ram_req gpu_req disk_req <<< "$item"

    echo "==================================" | tee -a "$LOG_FILE"
    echo "[$total_count/${#DATASET[@]}] Repo: $repo_dir" | tee -a "$LOG_FILE"
    echo "URL: $repo_url" | tee -a "$LOG_FILE"
    echo "HW Recommendation: CPU=$cpu_req, RAM=$ram_req, GPU=$gpu_req, Disk=$disk_req" | tee -a "$LOG_FILE"

    cd "$RUN_DIR" || exit 1

    if [ -d "$repo_dir/.git" ]; then
        echo "Repo exists. Pulling latest..." | tee -a "$LOG_FILE"
        if git -C "$repo_dir" pull --ff-only; then
            clone_ok=$((clone_ok + 1))
            echo "Pull success." | tee -a "$LOG_FILE"
        else
            clone_fail=$((clone_fail + 1))
            echo "Pull failed, continue with local copy." | tee -a "$LOG_FILE"
        fi
    elif [ -d "$repo_dir" ]; then
        echo "Directory exists but not a git repo, reusing as-is." | tee -a "$LOG_FILE"
    else
        echo "Cloning repository..." | tee -a "$LOG_FILE"
        if git clone "$repo_url" "$repo_dir"; then
            clone_ok=$((clone_ok + 1))
            echo "Clone success." | tee -a "$LOG_FILE"
        else
            clone_fail=$((clone_fail + 1))
            echo "Clone failed, skip run." | tee -a "$LOG_FILE"
            run_fail=$((run_fail + 1))
            continue
        fi
    fi

    if [ "$CLONE_ONLY" = "1" ]; then
        skipped_run=$((skipped_run + 1))
        echo "CLONE_ONLY=1, skip agent execution." | tee -a "$LOG_FILE"
        continue
    fi

    if [ ! -d "$repo_dir" ]; then
        run_fail=$((run_fail + 1))
        echo "Repo directory not found after clone/pull, skip." | tee -a "$LOG_FILE"
        continue
    fi

    cd "$repo_dir" || {
        run_fail=$((run_fail + 1))
        echo "Cannot enter $repo_dir, skip." | tee -a "$LOG_FILE"
        continue
    }

    echo "Running: python $AGENT_SCRIPT" | tee -a "$LOG_FILE"
    if python "$AGENT_SCRIPT"; then
        run_ok=$((run_ok + 1))
        echo "Agent run success for $repo_dir" | tee -a "$LOG_FILE"
    else
        run_fail=$((run_fail + 1))
        echo "Agent run failed for $repo_dir" | tee -a "$LOG_FILE"
    fi
done

echo "" | tee -a "$LOG_FILE"
echo "==== Summary ====" | tee -a "$LOG_FILE"
echo "Total repos: $total_count" | tee -a "$LOG_FILE"
echo "Clone/Pull success: $clone_ok" | tee -a "$LOG_FILE"
echo "Clone/Pull fail: $clone_fail" | tee -a "$LOG_FILE"
echo "Run success: $run_ok" | tee -a "$LOG_FILE"
echo "Run fail: $run_fail" | tee -a "$LOG_FILE"
echo "Run skipped (CLONE_ONLY): $skipped_run" | tee -a "$LOG_FILE"
echo "Log file: $LOG_FILE" | tee -a "$LOG_FILE"
echo "Run output directory: $RUN_DIR" | tee -a "$LOG_FILE"
