#!/bin/bash
set -Eeuo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "RSK XFM" \
  --description "The original and complete RSK audio archive." \
  --author "Ricky, Steve &amp; Karl" \
  --delimiter $'\x1F'
