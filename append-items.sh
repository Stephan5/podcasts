#!/bin/bash
set -euo pipefail

base_xml="$1"
items_xml="$2"
output_xml="$3"

tmp_file=$(mktemp)

sed '/<\/channel>/,/<\/rss>/d' "$base_xml" > "$tmp_file"

 {
  cat "$items_xml";
  echo;
  echo "</channel>";
  echo "</rss>"
} >> "$tmp_file"

mv "$tmp_file" "$output_xml"