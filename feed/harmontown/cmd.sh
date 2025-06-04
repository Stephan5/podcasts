#!/bin/bash
set -Eeuo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "Harmontown" \
  --description "Self destructive writer Dan Harmon claims he will one day found a colony of like-minded misfits. He’s appointed suit-clad gadabout Jeff Davis as his Comptroller and bearded dreamboat Spencer Crittenden as his Dungeon Master. It’s like a neurotic town hall meeting, often with alcohol and famous people." \
  --author "Dan Harmon" \
  --delimiter $'\x1F'