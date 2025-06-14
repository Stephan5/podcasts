#!/bin/bash
set -Eeuo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "Simon, Nick &amp; Karl" \
  --description "Simon Pegg, Nick Frost and Karl Pilkington on XFM." \
  --author "XFM" \
  --delimiter $'\x1F'
