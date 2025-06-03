#!/bin/bash
set -euo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "The Mighty Boosh" \
  --description "The Mighty Boosh Radio Series" \
  --author "Noel Fielding &amp; Julian Barratt" \
  --delimiter ";"
