#!/bin/bash
set -Eeuo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "Bad Friends" \
  --description "Andrew Santino and Bobby Lee present BAD FRIENDS" \
  --author "Andrew Santino &amp; Bobby Lee" \
  --delimiter $'\x1F'