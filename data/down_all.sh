#!/bin/bash

# Project list (format: project_name|GitHub_link)
repos=(
"RelTR|https://github.com/yrcong/RelTR"
"Femu|https://github.com/MoatLab/FEMU"
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