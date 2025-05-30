#!/bin/bash
set -euo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "Adam and Joe" \
  --description "The Adam Buxton and Joe Cornish archive of shows across XFM and 6Music." \
  --author "XFM &amp; 6Music" \
  --delimiter $'\x1F'
