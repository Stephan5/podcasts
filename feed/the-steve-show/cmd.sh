#!/bin/bash
set -Eeuo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "The Steve Show" \
  --description "Stephen Merchant's Sunday afternoon show on BBC 6Music." \
  --author "BBC 6Music" \
  --delimiter $'\x1F'