#!/bin/bash
set -Eeuo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "The Basement Yard" \
  --description "A podcast hosted by lifelong friends Joe Santagato &amp; Frank Alvarez." \
  --author "Joe Santagato &amp; Frank Alvarez" \
  --delimiter $'\x1F'