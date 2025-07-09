#!/bin/bash

# 项目列表（格式：项目名|GitHub链接）
repos=(
"exli|https://github.com/EngineeringSoftware/exli"
)

# 克隆函数
for entry in "${repos[@]}"; do
  name=$(echo "$entry" | cut -d '|' -f 1)
  url=$(echo "$entry" | cut -d '|' -f 2)

  if [ -d "$name" ]; then
    echo "[跳过] $name 已存在"
  else
    echo "[克隆] $name ..."
    git clone "$url" "$name"
  fi
done