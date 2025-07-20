#!/bin/bash

# Project list (format: project_name|GitHub_link)
repos=(
"exli|https://github.com/EngineeringSoftware/exli"
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