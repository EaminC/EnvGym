#!/bin/bash

# 简化版脚本：遍历所有仓库目录并运行 agent.py
# 使用 conda activate envgym 来激活虚拟环境

set -e  # 遇到错误时退出

# 定义路径
BASE_DIR="/Users/eamin/Desktop/data/学习资料/科研/kexin/0620/kjhkjh/data"
AGENT_SCRIPT="/Users/eamin/Desktop/data/学习资料/科研/kexin/0620/kjhkjh/Agent0613/agent.py"

# 日志文件
LOG_FILE="$BASE_DIR/execution_log_$(date +%Y%m%d_%H%M%S).log"

echo "开始执行脚本：$(date)" | tee -a "$LOG_FILE"
echo "基础目录：$BASE_DIR" | tee -a "$LOG_FILE"
echo "Agent 脚本：$AGENT_SCRIPT" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# 检查 agent.py 是否存在
if [ ! -f "$AGENT_SCRIPT" ]; then
    echo "错误：Agent 脚本不存在：$AGENT_SCRIPT" | tee -a "$LOG_FILE"
    exit 1
fi

# 进入基础目录
cd "$BASE_DIR"

# 计数器
success_count=0
fail_count=0
total_count=0

# 收集所有有效的仓库目录
echo "收集仓库目录..." | tee -a "$LOG_FILE"
repo_dirs=()
for dir in */; do
    # 跳过非目录项
    if [ ! -d "$dir" ]; then
        continue
    fi
    
    # 去掉末尾的斜杠
    repo_name="${dir%/}"
    
    # 跳过隐藏目录和一些特殊目录
    if [[ "$repo_name" == .* ]] || [[ "$repo_name" == "node_modules" ]] || [[ "$repo_name" == "__pycache__" ]]; then
        continue
    fi
    
    repo_dirs+=("$repo_name")
done

# 随机打乱目录顺序
# 使用当前时间作为随机种子
random_seed=$(date +%s)
echo "随机化执行顺序（种子: $random_seed）..." | tee -a "$LOG_FILE"
RANDOM=$random_seed

# 兼容性更好的随机排序方法
shuffled_dirs=()
temp_dirs=("${repo_dirs[@]}")
total_repos=${#temp_dirs[@]}

# 使用Fisher-Yates算法进行随机排序
for ((i=total_repos-1; i>0; i--)); do
    j=$((RANDOM % (i+1)))
    # 交换元素
    temp="${temp_dirs[i]}"
    temp_dirs[i]="${temp_dirs[j]}"
    temp_dirs[j]="$temp"
done

shuffled_dirs=("${temp_dirs[@]}")

echo "找到 ${#shuffled_dirs[@]} 个仓库，将按随机顺序执行" | tee -a "$LOG_FILE"

# 遍历随机化后的目录列表
for repo_name in "${shuffled_dirs[@]}"; do
    total_count=$((total_count + 1))
    
    echo "" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo "处理仓库 [$total_count]: $repo_name" | tee -a "$LOG_FILE"
    echo "时间：$(date)" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    
    # 进入仓库目录
    cd "$BASE_DIR/$repo_name"
    echo "当前目录：$(pwd)" | tee -a "$LOG_FILE"
    
    # 激活虚拟环境并执行脚本
    echo "激活 envgym 环境并执行 agent.py..." | tee -a "$LOG_FILE"
    
    # 尝试不同的环境激活方式
    if eval "$(conda shell.bash hook)" && conda activate envgym && python "$AGENT_SCRIPT"; then
        echo "✅ 仓库 $repo_name 执行成功" | tee -a "$LOG_FILE"
        success_count=$((success_count + 1))
        conda deactivate
    else
        echo "❌ 仓库 $repo_name 执行失败" | tee -a "$LOG_FILE"
        fail_count=$((fail_count + 1))
        # 尝试停用环境（如果有的话）
        conda deactivate 2>/dev/null || true
    fi
    
    # 确保回到基础目录
    cd "$BASE_DIR"
    
    echo "完成仓库：$repo_name" | tee -a "$LOG_FILE"
done

echo "" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "执行完成：$(date)" | tee -a "$LOG_FILE"
echo "总计：$total_count 个仓库" | tee -a "$LOG_FILE"
echo "成功：$success_count 个" | tee -a "$LOG_FILE"
echo "失败：$fail_count 个" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

if [ $fail_count -eq 0 ]; then
    echo "🎉 所有仓库都执行成功！"
else
    echo "⚠️  有 $fail_count 个仓库执行失败，请检查日志：$LOG_FILE"
fi 