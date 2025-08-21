#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Statistics counters
total_directories=0
dockerfiles_found=0
dockerfiles_backed_up=0
directories_without_dockerfile=0

echo -e "${BLUE}Starting backup of generated dockerfiles...${NC}"
echo ""

# Loop through all directories in tests/groundtruth/
for dir in tests/groundtruth/*/; do
    # Skip if not a directory
    if [ ! -d "$dir" ]; then
        continue
    fi
    
    # Extract directory name (remove path and trailing slash)
    dir_name=$(basename "$dir")
    
    # Skip the script itself
    if [ "$dir_name" = "backup_generated_dockerfiles.sh" ]; then
        continue
    fi
    
    total_directories=$((total_directories + 1))
    
    # Check if envgym subdirectory exists
    envgym_dir="${dir}envgym"
    if [ ! -d "$envgym_dir" ]; then
        echo -e "${YELLOW}[SKIP]${NC} $dir_name - no envgym directory"
        directories_without_dockerfile=$((directories_without_dockerfile + 1))
        continue
    fi
    
    # Check if envgym.dockerfile exists
    dockerfile_path="${envgym_dir}/envgym.dockerfile"
    if [ -f "$dockerfile_path" ]; then
        dockerfiles_found=$((dockerfiles_found + 1))
        
        # Check if backup already exists
        backup_path="${envgym_dir}/envgym.dockerfile.backup"
        if [ -f "$backup_path" ]; then
            echo -e "${YELLOW}[SKIP]${NC} $dir_name - backup already exists"
            continue
        fi
        
        # Rename to backup
        if mv "$dockerfile_path" "$backup_path"; then
            echo -e "${GREEN}[SUCCESS]${NC} $dir_name - dockerfile backed up"
            dockerfiles_backed_up=$((dockerfiles_backed_up + 1))
        else
            echo -e "${RED}[FAIL]${NC} $dir_name - failed to backup dockerfile"
        fi
    else
        echo -e "${RED}[FAIL]${NC} $dir_name - no dockerfile found"
        directories_without_dockerfile=$((directories_without_dockerfile + 1))
    fi
done

echo ""
echo -e "${BLUE}=== BACKUP STATISTICS ===${NC}"
echo -e "${BLUE}Total directories processed:${NC} $total_directories"
echo -e "${GREEN}Dockerfiles found:${NC} $dockerfiles_found"
echo -e "${GREEN}Dockerfiles backed up:${NC} $dockerfiles_backed_up"
echo -e "${RED}Directories without dockerfile:${NC} $directories_without_dockerfile"

# Calculate success rate
if [ $dockerfiles_found -gt 0 ]; then
    success_rate=$((dockerfiles_backed_up * 100 / dockerfiles_found))
    echo -e "${YELLOW}Success rate:${NC} ${success_rate}%"
fi

echo ""
if [ $dockerfiles_backed_up -gt 0 ]; then
    echo -e "${GREEN}Backup operation completed successfully!${NC}"
else
    echo -e "${YELLOW}No dockerfiles were backed up.${NC}"
fi
