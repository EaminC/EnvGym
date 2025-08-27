#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Repository list - same as in run_agent_list.sh
repos=(
# "RelTR"
# "Femu"
#"Lottory"
#"SEED-GNN"
# "TabPFN"
# "RSNN"
# "P4Ctl"
# "Fairify"
# "exli"
# "sixthsense"
# "probfuzz"
# "acto"
# "Baleen"
# "Silhouette"
# "ELECT"
# "Metis"
# "facebook_zstd"
# "catchorg_Catch2"
# "fmtlib_fmt"
# "nlohmann_json"
# "simdjson_simdjson"
# "cli_cli"
# "grpc_grpc-go"
# "zeromicro_go-zero"
# "alibaba_fastjson2"
# "elastic_logstash"
# "anuraghazra_github-readme-stats"
# "axios_axios"
# "expressjs_express"
# "iamkun_dayjs"
# "Kong_insomnia"
# "sveltejs_svelte"
# "BurntSushi_ripgrep"
# "clap-rs_clap"
# "nushell_nushell"
# "serde-rs_serde"
# "sharkdp_bat"
# "sharkdp_fd"
# "rayon-rs_rayon"
# "tokio-rs_bytes"
# "tokio-rs_tokio"
# "tokio-rs_tracing"
# "darkreader_darkreader"
# "mui_material-ui"
# "vuejs_core"
"SymMC"
"flex"
"mui_material-ui"
"anvil"
"mockito_mockito"
"rfuse"
"CrossPrefetch"
"jqlang_jq"
"ponylang_ponyc"
"yhirose_cpp-httplib"
"gluetest"
"vuejs_core"
)

echo "开始批量清除仓库中的envgym文件夹..."
echo "脚本路径: $SCRIPT_DIR"
echo "需要处理的仓库总数: ${#repos[@]}"
echo "=================================="

# 统计变量
total_repos=0
cleared_repos=0
skipped_repos=0

# 处理每个仓库
for repo_name in "${repos[@]}"; do
    echo "=================================="
    echo "处理仓库: $repo_name"
    echo "=================================="
    
    # 检查仓库目录是否存在
    if [ ! -d "$repo_name" ]; then
        echo "⚠️  警告: 目录 $repo_name 不存在，跳过..."
        ((skipped_repos++))
        continue
    fi
    
    ((total_repos++))
    
    # 进入仓库目录
    cd "$repo_name"
    
    # 检查是否成功进入目录
    if [ $? -ne 0 ]; then
        echo "错误: 无法进入目录 $repo_name"
        cd "$SCRIPT_DIR"
        ((skipped_repos++))
        continue
    fi
    
    # 检查是否存在envgym文件夹
    if [ -d "envgym" ]; then
        echo "发现envgym文件夹，正在删除..."
        
        # 删除envgym文件夹
        rm -rf envgym
        
        # 检查删除结果
        if [ $? -eq 0 ]; then
            echo "✓ $repo_name 中的envgym文件夹已成功删除"
            ((cleared_repos++))
        else
            echo "✗ $repo_name 中的envgym文件夹删除失败"
        fi
    else
        echo "ℹ️  $repo_name 中没有找到envgym文件夹"
    fi
    
    # 返回原始目录
    cd "$SCRIPT_DIR"
    
    echo ""
done

echo "=================================="
echo "批量清除完成！"
echo "=================================="
echo "统计信息:"
echo "- 总仓库数: ${#repos[@]}"
echo "- 处理的仓库数: $total_repos"
echo "- 成功清除的仓库数: $cleared_repos"
echo "- 跳过的仓库数: $skipped_repos"
echo "==================================" 