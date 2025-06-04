#!/bin/bash
set -Eeuo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "Cum Town" \
  --description "A podcast about having sex with your dad." \
  --author "Nick, Stav &amp; Adam" \
  --delimiter $'\x1F'
