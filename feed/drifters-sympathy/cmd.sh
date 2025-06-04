#!/bin/bash
set -Eeuo pipefail

# Get absolute paths
csv_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$csv_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$csv_dir"/feed.csv \
  --title "Drifter's Sympathy" \
  --description "Emil Amos charts the birth and development of the classic archetype 'The Outsider', telling disturbing and often humiliating stories about growing up in a small town in the 90’s. Every other episode digs into the archaeology of lesser-known music to illuminate the same themes from a more objective, historical perspective." \
  --author "Emil Amos" \
  --delimiter $'\x1F'