#!/bin/bash
set -euo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "Stavvy's World" \
  --description "A podcast where you can hang out with your pal Stav. Every week Stavros Halkias and his friends will help you solve all your problems. Wanna be a part of the show? Call 904-800-STAV, leave a voicemail and get some advice!" \
  --author "Stavros Halkias" \
  --delimiter $'\x1F'