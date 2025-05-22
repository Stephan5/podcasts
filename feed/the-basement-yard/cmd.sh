#!/bin/bash
set -euo pipefail

# Get absolute paths
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$script_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$script_dir"/feed.csv \
  --title "The Basement Yard" \
  --description "A podcast hosted by lifelong friends Joe Santagato &amp; Frank Alvarez." \
  --delimiter $'\x1F'