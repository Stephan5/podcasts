#!/bin/bash
set -euo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "Alan Partridge" \
  --description "A collection of audiobooks and podcasts from Alan Partridge." \
  --author "Steve Coogan" \
  --delimiter $'\x1F'
