#!/bin/bash
set -euo pipefail

# Get absolute paths
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$script_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$script_dir"/feed.csv \
  --title "RSK XFM" \
  --description "The original and complete RSK audio archive." \
  --delimiter $'\x1F'
