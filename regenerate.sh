#!/bin/bash
set -euo pipefail

dirs=("geoff" "mssp")

for dir in "${dirs[@]}"; do
  cmd_file="$dir/cmd.txt"

  if [[ -f "$cmd_file" ]]; then
    echo "Running command for: $dir"

    # Read the command from cmd.txt
    cmd=$(<"$cmd_file")

    echo "-> $cmd"

    # Run the command
    eval "$cmd"

    echo

  else
    echo "Skipping $dir — no cmd.txt found."
  fi
done

echo "Regeneration complete!"