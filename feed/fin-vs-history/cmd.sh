#!/bin/bash
set -Eeuo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "Fin vs History" \
  --description "For people who like listening to history but don't care what actually happened" \
  --author "Fin Taylor &amp; Horatio Gould" \
  --delimiter $'\x1F'