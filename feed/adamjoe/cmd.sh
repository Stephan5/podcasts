#!/bin/bash
set -euo pipefail

# Get absolute paths
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "$script_dir/../.." && pwd)"

"$base_dir"/script/csv2rss.sh "$script_dir"/feed.csv \
  --repo-dir "adamjoe" \
  --title "Adam and Joe XFM" \
  --description "Adam Buxton and Joe Cornish first appeared on the London-only radio station XFM in 2003, leading to a series of popular podcasts. They remained at the station for three years, with their final show broadcast on Christmas Eve 2006." \
  --delimiter $'\x1F'
