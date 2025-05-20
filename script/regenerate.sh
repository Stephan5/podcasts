#!/bin/bash
set -euo pipefail
trap 'echo "Error on line $LINENO: Command exited with status $?" >&2' ERR

# Define base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../feed" && pwd)"

# Verify base directory exists
if [[ ! -d "$BASE_DIR" ]]; then
    echo "Error: Base directory '$BASE_DIR' not found!" >&2
    exit 1
fi

# Find all directories directly under BASE_DIR
while IFS= read -r dir_path; do
    dir=$(basename "$dir_path")
    cmd_file="$dir_path/cmd.sh"



    if [[ -f "$cmd_file" ]]; then
        echo "Running script for: $dir"

        # Verify file ownership and permissions
        if [[ ! -O "$cmd_file" ]]; then
            echo "Error: '$cmd_file' is not owned by current user!" >&2
            exit 1
        fi

        # Make sure it's executable
        chmod +x "$cmd_file"

        # Run the script
        if ! "$cmd_file"; then
            echo "Error: Script '$cmd_file' failed!" >&2
            exit 1
        fi
    else
        echo "Skipping $dir — no cmd.sh found."
    fi
done < <(find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d)

echo "Regeneration complete!"
