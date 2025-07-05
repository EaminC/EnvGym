#!/bin/bash

# 脚本：激活envgym环境，遍历所有仓库目录并运行 agent.py
# 工作目录：/Users/eamin/Desktop/data/学习资料/科研/kexin/0620/kjhkjh/data

# 不要在错误时立即退出，这样可以继续处理其他仓库
# set -e  

# 定义路径
BASE_DIR="/Users/eamin/Desktop/data/学习资料/科研/kexin/0620/kjhkjh/data"
AGENT_SCRIPT="/Users/eamin/Desktop/data/学习资料/科研/kexin/0620/kjhkjh/Agent0613/agent.py"
CONDA_ENV="envgym"

# 日志文件
LOG_FILE="$BASE_DIR/execution_log_$(date +%Y%m%d_%H%M%S).log"

echo "========================================" | tee -a "$LOG_FILE"
echo "开始执行脚本：$(date)" | tee -a "$LOG_FILE"
echo "基础目录：$BASE_DIR" | tee -a "$LOG_FILE"
echo "Agent 脚本：$AGENT_SCRIPT" | tee -a "$LOG_FILE"
echo "Conda环境：$CONDA_ENV" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

# 检查 agent.py 是否存在
if [ ! -f "$AGENT_SCRIPT" ]; then
    echo "❌ 错误：Agent 脚本不存在：$AGENT_SCRIPT" | tee -a "$LOG_FILE"
    exit 1
fi

echo "✅ Agent脚本检查通过" | tee -a "$LOG_FILE"

# 检查conda环境是否存在
if ! conda info --envs | grep -q "$CONDA_ENV"; then
    echo "❌ 错误：Conda环境不存在：$CONDA_ENV" | tee -a "$LOG_FILE"
    exit 1
fi

echo "✅ Conda环境检查通过" | tee -a "$LOG_FILE"

# 进入基础目录
cd "$BASE_DIR"
echo "📂 当前工作目录：$(pwd)" | tee -a "$LOG_FILE"

# 计数器
success_count=0
fail_count=0
total_count=0

echo "" | tee -a "$LOG_FILE"
echo "🚀 开始处理仓库..." | tee -a "$LOG_FILE"

# 遍历所有子目录
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
    
    total_count=$((total_count + 1))
    
    echo "" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo "📦 处理仓库 [$total_count]: $repo_name" | tee -a "$LOG_FILE"
    echo "🕐 时间：$(date)" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    
    # 进入仓库目录
    cd "$BASE_DIR/$repo_name"
    echo "📂 当前目录：$(pwd)" | tee -a "$LOG_FILE"
    
    # 使用conda run在指定环境中执行脚本（这样更可靠）
    echo "⚡ 在conda环境($CONDA_ENV)中执行 agent.py..." | tee -a "$LOG_FILE"
    
    # 在conda环境中执行脚本
    if conda run -n "$CONDA_ENV" python "$AGENT_SCRIPT" 2>&1 | tee -a "$LOG_FILE"; then
        echo "✅ 仓库 $repo_name 执行成功" | tee -a "$LOG_FILE"
        success_count=$((success_count + 1))
    else
        exit_code=$?
        echo "❌ 仓库 $repo_name 执行失败（退出码：$exit_code）" | tee -a "$LOG_FILE"
        fail_count=$((fail_count + 1))
    fi
    
    # 确保回到基础目录
    cd "$BASE_DIR"
    
    echo "✅ 完成仓库：$repo_name" | tee -a "$LOG_FILE"
done

echo "" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"
echo "🏁 执行完成：$(date)" | tee -a "$LOG_FILE"
echo "📊 总计：$total_count 个仓库" | tee -a "$LOG_FILE"
echo "✅ 成功：$success_count 个" | tee -a "$LOG_FILE"
echo "❌ 失败：$fail_count 个" | tee -a "$LOG_FILE"
echo "========================================" | tee -a "$LOG_FILE"

if [ $fail_count -eq 0 ]; then
    echo "🎉 所有仓库都执行成功！" | tee -a "$LOG_FILE"
else
    echo "⚠️  有 $fail_count 个仓库执行失败，详细信息请查看日志：$LOG_FILE" | tee -a "$LOG_FILE"
fi

echo "📋 日志文件：$LOG_FILE" 