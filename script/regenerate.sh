#!/bin/bash
set -Eeuo pipefail
trap 'echo "Error on line $LINENO: Command exited with status $?" >&2' ERR

# Handle exclude argument
EXCLUDED_DIRS=""
if [[ $# -gt 0 ]]; then
    if [[ "$1" == "--exclude" ]]; then
        if [[ $# -lt 2 ]]; then
            echo "Error: --exclude requires a value" >&2
            echo "Usage: $0 [--exclude \"dir1,dir2,...\"]" >&2
            exit 1
        fi
        EXCLUDED_DIRS="$2"
        echo "Excluding directories: $EXCLUDED_DIRS"
    else
        echo "Usage: $0 [--exclude \"dir1,dir2,...\"]" >&2
        exit 1
    fi
fi

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

    # Skip excluded directories
    if [[ -n "$EXCLUDED_DIRS" ]]; then
        if [[ ",$EXCLUDED_DIRS," == *",$dir,"* ]]; then
            echo "Skipping excluded directory: $dir"
            continue
        fi
    fi

    cmd_file="$dir_path/cmd.sh"

    if [[ -f "$cmd_file" ]]; then
        echo "---------------------------------------------------"
        echo "---------------------------------------------------"
        echo "--- Starting regeneration for: $dir ---"
        echo "---------------------------------------------------"
        echo "---------------------------------------------------"

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

        echo "---------------------------------------------------"
        echo "---------------------------------------------------"
        echo "--- Regeneration complete for: $dir ---"
        echo "---------------------------------------------------"
        echo "---------------------------------------------------"
        echo
        echo
    else
        echo "Skipping $dir — no cmd.sh found."
    fi
done < <(find "$BASE_DIR" -mindepth 1 -maxdepth 1 -type d | sort)

echo "Regeneration complete!"
