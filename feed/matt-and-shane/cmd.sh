#!/bin/bash
set -euo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "Matt and Shane's Secret Podcast" \
  --description "Grab onto this fast moving train and witness two comedians rise to victory and splendor." \
  --author "Matt McCusker &amp; Shane Gillis" \
  --delimiter $'\x1F'
