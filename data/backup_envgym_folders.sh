#!/usr/bin/env bash

# ============================================================================
# 备份脚本：backup_envgym_folders.sh
# 功能：
#   1. 遍历 EnvGym/data 下的所有仓库目录；
#   2. 找到每个仓库中的 envgym 目录；
#   3. 将这些 envgym 目录复制到 EnvGym/tests/backup_YYYYMMDD 目录下，
#      并以仓库名作为子目录名进行归档；
# ----------------------------------------------------------------------------
# 使用方法：
#   1. 进入 EnvGym/data 目录；
#      cd /path/to/EnvGym/data
#   2. 执行脚本（建议先赋予执行权限）：
#      chmod +x backup_envgym_folders.sh
#      ./backup_envgym_folders.sh
# ============================================================================

set -euo pipefail

# 获取脚本所在的绝对路径
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DATA_DIR="$SCRIPT_DIR"
ROOT_DIR="$(dirname "$DATA_DIR")"   # EnvGym 根目录
TESTS_DIR="$ROOT_DIR/tests"

# 生成日期字符串
DATE_STR="$(date +%Y%m%d)"
BACKUP_DIR="$TESTS_DIR/backup_${DATE_STR}"

# 创建备份目录（若已存在则继续）
mkdir -p "$BACKUP_DIR"

echo "[INFO] 备份目录：$BACKUP_DIR"

echo "[INFO] 开始遍历 $DATA_DIR 下的仓库……"

# 遍历 data 目录下的所有一级子目录
for repo_dir in "$DATA_DIR"/*; do
    # 只处理目录
    if [ ! -d "$repo_dir" ]; then
        continue
    fi

    repo_name="$(basename "$repo_dir")"

    ENVGYM_SUBDIR="$repo_dir/envgym"

    if [ -d "$ENVGYM_SUBDIR" ]; then
        # 目标路径：tests/backup_日期/仓库名
        dest_dir="$BACKUP_DIR/$repo_name"
        mkdir -p "$dest_dir"

        echo "[INFO] 复制 $repo_name/envgym -> $dest_dir/"
        # 使用 -a 保留文件属性，尾随斜杠避免多一层目录
        cp -a "$ENVGYM_SUBDIR" "$dest_dir/"
    else
        echo "[WARN] 跳过 $repo_name：未找到 envgym 目录"
    fi

done

echo "[INFO] 备份完成！" 