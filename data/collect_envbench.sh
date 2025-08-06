#!/bin/bash

# 收集脚本：从data目录收集envbench.sh文件到EnvBench/scripts目录
# 用法：./collect_envbench.sh

# 设置路径
DATA_DIR="$(pwd)"
ENVBENCH_SCRIPTS_DIR="$(dirname "$(pwd)")/EnvBench/scripts"

echo "开始收集envbench.sh文件..."
echo "数据目录: $DATA_DIR"
echo "目标目录: $ENVBENCH_SCRIPTS_DIR"

# 确保目标目录存在
mkdir -p "$ENVBENCH_SCRIPTS_DIR"

# 计数器
collected_count=0
skipped_count=0

# 遍历data目录下的所有子目录
for repo_dir in "$DATA_DIR"/*/; do
    if [ -d "$repo_dir" ]; then
        repo_name=$(basename "$repo_dir")
        
        # 检查是否存在envgym/envbench.sh
        envbench_path="$repo_dir/envgym/envbench.sh"
        
        if [ -f "$envbench_path" ]; then
            # 创建目标目录
            target_dir="$ENVBENCH_SCRIPTS_DIR/$repo_name"
            mkdir -p "$target_dir"
            
            # 复制文件
            target_file="$target_dir/envbench.sh"
            
            if [ ! -f "$target_file" ]; then
                cp "$envbench_path" "$target_file"
                echo "✓ 已收集: $repo_name/envgym/envbench.sh -> EnvBench/scripts/$repo_name/envbench.sh"
                ((collected_count++))
            else
                echo "⚠ 跳过: $repo_name (目标文件已存在)"
                ((skipped_count++))
            fi
        else
            echo "✗ 跳过: $repo_name (未找到envbench.sh)"
            ((skipped_count++))
        fi
    fi
done

echo ""
echo "收集完成！"
echo "成功收集: $collected_count 个文件"
echo "跳过: $skipped_count 个目录" 