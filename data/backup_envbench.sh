#!/bin/bash

# 备份脚本：从EnvBench/scripts目录备份envbench.sh文件到data目录
# 用法：./backup_envbench.sh

# 设置路径
DATA_DIR="$(pwd)"
ENVBENCH_SCRIPTS_DIR="$(dirname "$(pwd)")/EnvBench/scripts"

echo "开始备份envbench.sh文件..."
echo "数据目录: $DATA_DIR"
echo "源目录: $ENVBENCH_SCRIPTS_DIR"

# 检查源目录是否存在
if [ ! -d "$ENVBENCH_SCRIPTS_DIR" ]; then
    echo "错误: 源目录不存在: $ENVBENCH_SCRIPTS_DIR"
    exit 1
fi

# 计数器
backed_up_count=0
skipped_count=0

# 遍历EnvBench/scripts目录下的所有子目录
for script_dir in "$ENVBENCH_SCRIPTS_DIR"/*/; do
    if [ -d "$script_dir" ]; then
        repo_name=$(basename "$script_dir")
        
        # 检查是否存在envbench.sh
        script_file="$script_dir/envbench.sh"
        
        if [ -f "$script_file" ]; then
            # 检查目标repo目录是否存在
            target_repo_dir="$DATA_DIR/$repo_name"
            
            if [ -d "$target_repo_dir" ]; then
                # 创建envgym目录
                target_envgym_dir="$target_repo_dir/envgym"
                mkdir -p "$target_envgym_dir"
                
                # 复制文件
                target_file="$target_envgym_dir/envbench.sh"
                
                if [ ! -f "$target_file" ]; then
                    cp "$script_file" "$target_file"
                    echo "✓ 已备份: EnvBench/scripts/$repo_name/envbench.sh -> $repo_name/envgym/envbench.sh"
                    ((backed_up_count++))
                else
                    echo "⚠ 跳过: $repo_name (目标文件已存在)"
                    ((skipped_count++))
                fi
            else
                echo "✗ 跳过: $repo_name (目标repo目录不存在)"
                ((skipped_count++))
            fi
        else
            echo "✗ 跳过: $repo_name (未找到envbench.sh)"
            ((skipped_count++))
        fi
    fi
done

echo ""
echo "备份完成！"
echo "成功备份: $backed_up_count 个文件"
echo "跳过: $skipped_count 个目录" 