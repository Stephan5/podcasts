#!/bin/bash
set -euo pipefail

# Get absolute paths
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$script_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$script_dir"/feed.csv \
  --repo-dir "mssp" \
  --title "Matt and Shane's Secret Podcast" \
  --description "Grab onto this fast moving train and witness two comedians rise to victory and splendor." \
  --delimiter ";"
