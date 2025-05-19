#!/bin/bash
set -euo pipefail
trap 'echo "Error on line $LINENO: Command exited with status $?" >&2' ERR

dirs=("geoff" "mssp")

for dir in "${dirs[@]}"; do
  cmd_file="$dir/cmd.sh"

  if [[ -f "$cmd_file" ]]; then
    echo "Running script for: $dir"

    # Make sure it's executable
    chmod +x "$cmd_file"

    # Run the script
    "$cmd_file"

  else
    echo "Skipping $dir — no cmd.sh found."
  fi
done

echo "Regeneration complete!"
