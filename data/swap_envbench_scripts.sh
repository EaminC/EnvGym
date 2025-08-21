#!/bin/bash

# Copy EnvBench Scripts - Implementation Script
# This script copies envbench.sh files from EnvBench/scripts/xxx/ to tests/backup_20250806/xxx/envgym/
# Only copies if the target has envgym.dockerfile and handles file comparison for overwrites

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Initialize counters
SUCCESS_COUNT=0  # c - has dockerfile and substituted with different envbench
FAIL_COUNT=0     # a - does NOT have backup_20250806.../envgym.dockerfile  
NO_EFFECT_COUNT=0 # b - has dockerfile but identical envbench.sh
TOTAL_REPOS=0

echo "=========================================="
echo "Swap EnvBench Scripts Tool"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -d "EnvBench/scripts" ]; then
    echo -e "${RED}ERROR: EnvBench/scripts directory not found. Please run from EnvGym root directory.${NC}"
    exit 1
fi

if [ ! -d "tests/backup_20250806" ]; then
    echo -e "${RED}ERROR: tests/backup_20250806 directory not found.${NC}"
    exit 1
fi

echo "Scanning repositories in EnvBench/scripts/..."
echo ""

# Process each repository directory
for repo_dir in EnvBench/scripts/*/; do
    # Skip if not a directory
    [ ! -d "$repo_dir" ] && continue
    
    repo_name=$(basename "$repo_dir")
    source_envbench="$repo_dir/envbench.sh"
    target_dockerfile="tests/groundtruth/$repo_name/envgym/envgym.dockerfile"
    target_envbench="tests/groundtruth/$repo_name/envgym/envbench.sh"
    
    TOTAL_REPOS=$((TOTAL_REPOS + 1))
    
    # Check if source envbench.sh exists
    if [ ! -f "$source_envbench" ]; then
        echo -e "${YELLOW}[$repo_name]${NC} No envbench.sh in source - skipping"
        continue
    fi
    
    # Check if target dockerfile exists
    if [ ! -f "$target_dockerfile" ]; then
        echo -e "${RED}[$repo_name]${NC} FAIL - No envgym.dockerfile found"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        continue
    fi
    
    # Dockerfile exists, now check if we need to copy envbench.sh
    if [ -f "$target_envbench" ]; then
        # Target envbench.sh exists, compare files
        if cmp -s "$source_envbench" "$target_envbench"; then
            # Files are identical
            echo -e "${YELLOW}[$repo_name]${NC} NO-EFFECT - envbench.sh files are identical"
            NO_EFFECT_COUNT=$((NO_EFFECT_COUNT + 1))
        else
            # Files are different, copy the new one
            cp "$source_envbench" "$target_envbench"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}[$repo_name]${NC} SUCCESS - Replaced different envbench.sh"
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            else
                echo -e "${RED}[$repo_name]${NC} ERROR - Failed to copy envbench.sh"
                FAIL_COUNT=$((FAIL_COUNT + 1))
            fi
        fi
    else
        # Target envbench.sh doesn't exist, create directory and copy
        mkdir -p "$(dirname "$target_envbench")"
        cp "$source_envbench" "$target_envbench"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[$repo_name]${NC} SUCCESS - Created new envbench.sh"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo -e "${RED}[$repo_name]${NC} ERROR - Failed to swap envbench.sh"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    fi
done

echo ""
echo "=========================================="
echo "Final Statistics"
echo "=========================================="
echo -e "Total repositories scanned: ${BLUE}$TOTAL_REPOS${NC}"
echo ""
echo -e "${GREEN}SUCCESS: $SUCCESS_COUNT${NC} (Dockerfile detected and substituted with different envbench.sh)"
echo -e "${RED}FAIL: $FAIL_COUNT${NC} (No envgym.dockerfile in tests/groundtruth/<repo_name>/envgym/)"
echo -e "${YELLOW}NO-EFFECT: $NO_EFFECT_COUNT${NC} (Identical envbench.sh, no need to swap)"
echo ""

# Calculate percentages
if [ $TOTAL_REPOS -gt 0 ]; then
    success_pct=$(echo "scale=1; $SUCCESS_COUNT * 100 / $TOTAL_REPOS" | bc -l 2>/dev/null || echo "0")
    fail_pct=$(echo "scale=1; $FAIL_COUNT * 100 / $TOTAL_REPOS" | bc -l 2>/dev/null || echo "0")
    no_effect_pct=$(echo "scale=1; $NO_EFFECT_COUNT * 100 / $TOTAL_REPOS" | bc -l 2>/dev/null || echo "0")
    
    echo "Percentages:"
    echo -e "${GREEN}SUCCESS: ${success_pct}%${NC}"
    echo -e "${RED}FAIL: ${fail_pct}%${NC}"
    echo -e "${YELLOW}NO-EFFECT: ${no_effect_pct}%${NC}"
fi

echo ""
echo "Copy operation complete!"
