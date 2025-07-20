#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_SCRIPT="$SCRIPT_DIR/../../Agent/agent.py"

# Check if agent.py exists
if [ ! -f "$AGENT_SCRIPT" ]; then
    echo "Error: Cannot find $AGENT_SCRIPT"
    echo "Please ensure Agent/agent.py file exists"
    exit 1
fi

# Repository list - same as in down_all_ts.sh
repos=(
"RelTR"
"Femu"
"Lottory"
"SEED-GNN"
"TabPFN"
"RSNN"
"P4Ctl"
"CrossPrefetch"
"SymMC"
"Fairify"
"exli"
"sixthsense"
"probfuzz"
"gluetest"
"flex"
"acto"
"Baleen"
"Silhouette"
"anvil"
"ELECT"
"rfuse"
"Metis"
"facebook_zstd"
"jqlang_jq"
"ponylang_ponyc"
"catchorg_Catch2"
"fmtlib_fmt"
"nlohmann_json"
"simdjson_simdjson"
"yhirose_cpp-httplib"
"cli_cli"
"grpc_grpc-go"
"zeromicro_go-zero"
"alibaba_fastjson2"
"elastic_logstash"
"mockito_mockito"
"anuraghazra_github-readme-stats"
"axios_axios"
"expressjs_express"
"iamkun_dayjs"
"Kong_insomnia"
"sveltejs_svelte"
"BurntSushi_ripgrep"
"clap-rs_clap"
"nushell_nushell"
"serde-rs_serde"
"sharkdp_bat"
"sharkdp_fd"
"rayon-rs_rayon"
"tokio-rs_bytes"
"tokio-rs_tokio"
"tokio-rs_tracing"
"darkreader_darkreader"
"mui_material-ui"
"vuejs_core"
)

echo "Starting to process repositories from list and execute agent.py..."
echo "Agent script path: $AGENT_SCRIPT"
echo "Total repositories to process: ${#repos[@]}"
echo "=================================="

# Process each repository from the list
for repo_name in "${repos[@]}"; do
    echo "=================================="
    echo "Processing repository: $repo_name"
    echo "=================================="
    
    # Check if repository directory exists
    if [ ! -d "$repo_name" ]; then
        echo "⚠️  Warning: Directory $repo_name does not exist, skipping..."
        continue
    fi
    
    # Enter repository directory
    cd "$repo_name"
    
    # Check if successfully entered directory
    if [ $? -ne 0 ]; then
        echo "Error: Cannot enter directory $repo_name"
        cd "$SCRIPT_DIR"
        continue
    fi
    
    # Execute agent.py script
    echo "Executing: python $AGENT_SCRIPT"
    python "$AGENT_SCRIPT"
    
    # Check execution result
    if [ $? -eq 0 ]; then
        echo "✓ $repo_name executed successfully"
    else
        echo "✗ $repo_name execution failed"
    fi
    
    # Return to original directory
    cd "$SCRIPT_DIR"
    
    echo ""
done

echo "=================================="
echo "All repositories from list processed!"
echo "==================================" 