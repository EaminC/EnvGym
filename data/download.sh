#!/bin/bash

# Specify the path to the text file containing repo URLs
TXT_FILE="repolist.txt"

# Check if the text file exists
if [ ! -f "$TXT_FILE" ]; then
  echo "Error: File '$TXT_FILE' not found!"
  exit 1
fi

# Read each line from the text file (repo URL) and clone the repo
while IFS= read -r repo; do
  # Skip empty lines or lines starting with a hash (comments)
  if [ -z "$repo" ] || [[ "$repo" =~ ^# ]]; then
    continue
  fi

  # Clone the repository
  echo "Cloning repo: $repo"
  git clone "$repo"
done < "$TXT_FILE"