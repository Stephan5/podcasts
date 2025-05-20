#!/bin/bash
set -euo pipefail

# Get absolute paths
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$script_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$script_dir"/feed.csv \
  --title "SNK XFM" \
  --description "Simon Pegg, Nick Frost and Karl Pilkington on XFM." \
  --delimiter ";"
