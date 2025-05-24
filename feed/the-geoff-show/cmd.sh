#!/bin/bash
set -euo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "The Geoff Show" \
  --description "The Geoff Show was a humorous radio program, broadcast on Absolute Radio (formerly Virgin Radio) from 3 January 2006 to 25 September 2008. The show ran for three hours, between 10 pm and 1 am, Monday to Thursday." \
  --delimiter ";"