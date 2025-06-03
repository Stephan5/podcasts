#!/bin/bash
set -euo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "Absolutely Mental" \
  --description "Gervais and Harris contemplate the wonders of science and the chaos of modern life while having many good laughs." \
  --author "Ricky Gervais &amp; Sam Harris" \
  --delimiter $'\x1F'
