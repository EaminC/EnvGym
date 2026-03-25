#!/usr/bin/env bash

# plonky2-gpu Environment Benchmark Test
# - Validates software stack and hardware visibility
# - Checks whether a complete runnable environment is available
# - Writes summary JSON to envgym/envbench.json

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../plonky2-gpu" && pwd)"
cd "$ROOT_DIR" || exit 1

OUT_DIR="$ROOT_DIR/envgym"
OUT_JSON="$OUT_DIR/envbench.json"
HW_TXT="$OUT_DIR/hardware.txt"
REPORT_TXT="$OUT_DIR/report.txt"

mkdir -p "$OUT_DIR"

print_status() {
    local status="$1"
    local message="$2"
    case "$status" in
        PASS)
            echo -e "${GREEN}[PASS]${NC} $message"
            PASS_COUNT=$((PASS_COUNT + 1))
            ;;
        FAIL)
            echo -e "${RED}[FAIL]${NC} $message"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            ;;
        WARN)
            echo -e "${YELLOW}[WARN]${NC} $message"
            WARN_COUNT=$((WARN_COUNT + 1))
            ;;
        INFO)
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        *)
            echo "[$status] $message"
            ;;
    esac
}

check_command() {
    local cmd="$1"
    local name="$2"
    if command -v "$cmd" >/dev/null 2>&1; then
        print_status PASS "$name is installed"
        return 0
    fi
    print_status FAIL "$name is not installed"
    return 1
}

check_command_warn() {
    local cmd="$1"
    local name="$2"
    if command -v "$cmd" >/dev/null 2>&1; then
        print_status PASS "$name is installed"
        return 0
    fi
    print_status WARN "$name is not installed (optional)"
    return 1
}

write_results_json() {
    cat > "$OUT_JSON" <<EOF
{
  "PASS": $PASS_COUNT,
  "FAIL": $FAIL_COUNT,
  "WARN": $WARN_COUNT
}
EOF
    print_status INFO "Results written to $OUT_JSON"
}

collect_hardware_info() {
    {
        echo "===== plonky2-gpu Hardware Snapshot ====="
        echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        echo
        echo "[CPU]"
        if command -v lscpu >/dev/null 2>&1; then
            lscpu
        elif command -v sysctl >/dev/null 2>&1; then
            sysctl -a 2>/dev/null | rg "machdep.cpu|hw.ncpu|hw.memsize"
        else
            echo "No CPU detail tool found"
        fi
        echo
        echo "[Memory]"
        if command -v free >/dev/null 2>&1; then
            free -h
        elif command -v vm_stat >/dev/null 2>&1; then
            vm_stat
        else
            echo "No memory tool found"
        fi
        echo
        echo "[Disk]"
        df -h .
        echo
        echo "[GPU - NVIDIA]"
        if command -v nvidia-smi >/dev/null 2>&1; then
            nvidia-smi
        else
            echo "nvidia-smi not found"
        fi
        echo
        echo "[GPU - ROCm]"
        if command -v rocm-smi >/dev/null 2>&1; then
            rocm-smi
        else
            echo "rocm-smi not found"
        fi
        echo
        echo "[GPU - OpenCL]"
        if command -v clinfo >/dev/null 2>&1; then
            clinfo
        else
            echo "clinfo not found"
        fi
        echo
        echo "[OS]"
        uname -a
    } > "$HW_TXT" 2>&1

    print_status INFO "Hardware snapshot written to $HW_TXT"
}

echo "=========================================="
echo "plonky2-gpu Environment Benchmark Test"
echo "=========================================="
echo ""

echo "1) Checking required software..."
echo "--------------------------------"
check_command bash "Bash"
check_command git "Git"
check_command curl "curl"
check_command rustc "Rust compiler"
check_command cargo "Cargo"
check_command python3 "Python 3"
check_command pkg-config "pkg-config"
check_command_warn cmake "CMake"
check_command_warn ninja "Ninja"
check_command_warn jq "jq"
echo ""

echo "2) Checking Rust toolchain..."
echo "-----------------------------"
if command -v rustc >/dev/null 2>&1; then
    RUST_V="$(rustc --version 2>&1)"
    print_status INFO "rustc version: $RUST_V"
    RUST_MAJOR="$(echo "$RUST_V" | awk '{print $2}' | cut -d. -f1)"
    RUST_MINOR="$(echo "$RUST_V" | awk '{print $2}' | cut -d. -f2)"
    if [ "${RUST_MAJOR:-0}" -ge 1 ] && [ "${RUST_MINOR:-0}" -ge 70 ]; then
        print_status PASS "Rust version is acceptable (>= 1.70)"
    else
        print_status WARN "Rust version seems old; build may fail on newer crates"
    fi
fi

if command -v cargo >/dev/null 2>&1; then
    print_status INFO "cargo version: $(cargo --version 2>&1)"
fi
echo ""

echo "3) Checking hardware/GPU visibility..."
echo "--------------------------------------"
if command -v nvidia-smi >/dev/null 2>&1; then
    if nvidia-smi >/dev/null 2>&1; then
        print_status PASS "NVIDIA GPU detected and nvidia-smi works"
    else
        print_status FAIL "nvidia-smi exists but cannot query GPU"
    fi
else
    print_status WARN "NVIDIA GPU tool not found"
fi

if command -v nvcc >/dev/null 2>&1; then
    print_status PASS "CUDA compiler (nvcc) is installed"
else
    print_status WARN "CUDA compiler (nvcc) is not installed"
fi

if command -v rocm-smi >/dev/null 2>&1; then
    print_status PASS "ROCm tool (rocm-smi) is installed"
else
    print_status WARN "ROCm tool (rocm-smi) is not installed"
fi

if [ "$(uname -s)" = "Darwin" ]; then
    if system_profiler SPDisplaysDataType >/dev/null 2>&1; then
        print_status PASS "macOS graphics info is queryable (Metal-capable check possible)"
    else
        print_status WARN "Cannot query macOS graphics details"
    fi
fi
echo ""

echo "4) Checking project structure..."
echo "-------------------------------"
if [ -f Cargo.toml ]; then
    print_status PASS "Workspace Cargo.toml found"
else
    print_status FAIL "Workspace Cargo.toml missing"
fi

for d in plonky2 starky field util u32 waksman; do
    if [ -d "$d" ]; then
        print_status PASS "Directory '$d' exists"
    else
        print_status FAIL "Directory '$d' missing"
    fi
done

for f in plonky2/Cargo.toml starky/Cargo.toml field/Cargo.toml; do
    if [ -f "$f" ]; then
        print_status PASS "File '$f' exists"
    else
        print_status FAIL "File '$f' missing"
    fi
done
echo ""

echo "5) Checking runnable build environment..."
echo "-----------------------------------------"
if command -v cargo >/dev/null 2>&1; then
    if cargo metadata --format-version=1 >/dev/null 2>&1; then
        print_status PASS "cargo metadata works"
    else
        print_status FAIL "cargo metadata failed (workspace/deps issue)"
    fi

    if CARGO_NET_OFFLINE=true cargo check -p plonky2 --quiet >/dev/null 2>&1; then
        print_status PASS "cargo check -p plonky2 passed (offline mode)"
    else
        print_status WARN "cargo check -p plonky2 failed in offline mode"
        if cargo check -p plonky2 --quiet >/dev/null 2>&1; then
            print_status PASS "cargo check -p plonky2 passed (online mode)"
        else
            print_status FAIL "cargo check -p plonky2 failed"
        fi
    fi
else
    print_status FAIL "Skipping build checks because cargo is unavailable"
fi
echo ""

echo "6) Collecting hardware report..."
echo "--------------------------------"
collect_hardware_info
echo ""

FINAL_PASS_COUNT="$PASS_COUNT"
FINAL_FAIL_COUNT="$FAIL_COUNT"
FINAL_WARN_COUNT="$WARN_COUNT"

{
    echo "===== plonky2-gpu Environment Benchmark Report ====="
    echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "PASS=$FINAL_PASS_COUNT"
    echo "FAIL=$FINAL_FAIL_COUNT"
    echo "WARN=$FINAL_WARN_COUNT"
} > "$REPORT_TXT"

echo "=========================================="
echo "Test Results Summary"
echo "=========================================="
echo -e "${GREEN}PASS: $FINAL_PASS_COUNT${NC}"
echo -e "${RED}FAIL: $FINAL_FAIL_COUNT${NC}"
echo -e "${YELLOW}WARN: $FINAL_WARN_COUNT${NC}"

write_results_json
print_status INFO "Text report written to $REPORT_TXT"

if [ "$FINAL_FAIL_COUNT" -eq 0 ]; then
    print_status INFO "Environment looks complete for plonky2-gpu."
    exit 0
fi

print_status WARN "Environment is not fully complete; see failures above."
exit 1
