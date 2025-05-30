#!/bin/bash
set -euo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "The Russell Brand Show with Karl Pilkington" \
  --description "A few one-off shows of the Russell Brand Show with Karl Pilkington joining as co-host." \
  --delimiter $'\x1F'