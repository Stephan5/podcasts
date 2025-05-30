#!/bin/bash
set -euo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "The Steve Show - BBC 6Music" \
  --description "Stephen Merchant's Sunday afternoon show on BBC 6Music that ran from 2007 to 2009" \
  --delimiter $'\x1F'