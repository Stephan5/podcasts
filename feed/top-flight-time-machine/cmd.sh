#!/bin/bash
set -euo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "Top Flight Time Machine" \
  --description "Andy Dawson &amp; Sam Delaney - used to be football, all over the place now. Coins, ghosts, digging, dis, dat..." \
  --delimiter $'\x1F'
