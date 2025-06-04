#!/bin/bash
set -Eeuo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "Top Flight Time Machine" \
  --description "Andy Dawson &amp; Sam Delaney - used to be football, all over the place now. Coins, ghosts, digging, dis, dat..." \
  --author "Andy Dawson &amp; Sam Delaney" \
  --delimiter $'\x1F'
