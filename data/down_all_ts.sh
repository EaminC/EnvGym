#!/bin/bash

# Dataset list generated from Excel file
repos=(
"RelTR|https://github.com/yrcong/RelTR"
"Lottory|https://github.com/rahulvigneswaran/Lottery-Ticket-Hypothesis-in-Pytorch"
"SEED-GNN|https://github.com/henryzhongsc/gnn_editing"
"TabPFN|https://github.com/PriorLabs/TabPFN"
"RSNN|https://github.com/fmi-basel/neural-decoding-RSNN"
"P4Ctl|https://github.com/peng-gao-lab/p4control"
"CrossPrefetch|https://github.com/RutgersCSSystems/crossprefetch-asplos24-artifacts"
"SymMC|https://github.com/wenxiwang/SymMC-Tool"
"Fairify|https://github.com/sumonbis/Fairify"
"exli|https://github.com/EngineeringSoftware/exli"
"sixthsense|https://github.com/uiuc-arc/sixthsense"
"probfuzz|https://github.com/uiuc-arc/probfuzz"
"gluetest|https://github.com/seal-research/gluetest"
"flex|https://github.com/uiuc-arc/flex"
"acto|https://github.com/xlab-uiuc/acto"
"Baleen|https://github.com/wonglkd/Baleen-FAST24"
"Silhouette|https://github.com/iaoing/Silhouette"
"anvil|https://github.com/anvil-verifier/anvil"
"ELECT|https://github.com/tinoryj/ELECT"
"rfuse|https://github.com/snu-csl/rfuse"
"Metis|https://github.com/sbu-fsl/Metis"
"facebook_zstd|https://github.com/facebook/zstd"
"jqlang_jq|https://github.com/jqlang/jq"
"ponylang_ponyc|https://github.com/ponylang/ponyc"
"catchorg_Catch2|https://github.com/catchorg/Catch2"
"fmtlib_fmt|https://github.com/fmtlib/fmt"
"nlohmann_json|https://github.com/nlohmann/json"
"simdjson_simdjson|https://github.com/simdjson/simdjson"
"yhirose_cpp-httplib|https://github.com/yhirose/cpp-httplib"
"cli_cli|https://github.com/cli/cli"
"grpc_grpc-go|https://github.com/grpc/grpc-go"
"zeromicro_go-zero|https://github.com/zeromicro/go-zero"
"alibaba_fastjson2|https://github.com/alibaba/fastjson2"
"elastic_logstash|https://github.com/elastic/logstash"
"mockito_mockito|https://github.com/mockito/mockito"
"anuraghazra_github-readme-stats|https://github.com/anuraghazra/github-readme-stats"
"axios_axios|https://github.com/axios/axios"
"expressjs_express|https://github.com/expressjs/express"
"iamkun_dayjs|https://github.com/iamkun/dayjs"
"Kong_insomnia|https://github.com/Kong/insomnia"
"sveltejs_svelte|https://github.com/sveltejs/svelte"
"BurntSushi_ripgrep|https://github.com/BurntSushi/ripgrep"
"clap-rs_clap|https://github.com/clap-rs/clap"
"nushell_nushell|https://github.com/nushell/nushell"
"serde-rs_serde|https://github.com/serde-rs/serde"
"sharkdp_bat|https://github.com/sharkdp/bat"
"sharkdp_fd|https://github.com/sharkdp/fd"
"rayon-rs_rayon|https://github.com/rayon-rs/rayon"
"tokio-rs_bytes|https://github.com/tokio-rs/bytes"
"tokio-rs_tokio|https://github.com/tokio-rs/tokio"
"tokio-rs_tracing|https://github.com/tokio-rs/tracing"
"darkreader_darkreader|https://github.com/darkreader/darkreader"
"mui_material-ui|https://github.com/mui/material-ui"
"vuejs_core|https://github.com/vuejs/core"
)

# Clone function
for entry in "${repos[@]}"; do
  name=$(echo "$entry" | cut -d '|' -f 1)
  url=$(echo "$entry" | cut -d '|' -f 2)

  if [ -d "$name" ]; then
    echo "[SKIP] $name already exists"
  else
    echo "[CLONE] $name ..."
    git clone "$url" "$name"
  fi
done

echo "All datasets downloaded successfully!"
