#!/bin/bash
set -euo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "Athletico Mince" \
  --description "Bob Mortimer and Andy Dawson's podcast - brass hands, blue drink and more. It's not really about football, d'you know what I mean?" \
  --author "Bob Mortimer &amp; Andy Dawson" \
  --delimiter $'\x1F'
