#!/bin/bash
set -euo pipefail

input_file=$1
output_file="${output_file:-${input_file%%.csv}.out.csv}"


IFS= read -r header < "$input_file"

echo "$header" >> "$output_file"

while IFS= read -r line; do
  IFS=';' read -r item_number item_title item_description item_date item_link <<< "$line"

  # reformat Date
  item_date=${item_date//"."/""}
  item_date=${item_date//","/""}
  item_date=$(date -jf '%b %d %Y' "$item_date" '+%a, %d %b %Y 03:00:00 GMT')

  echo "$item_number;$item_title;$item_description;$item_date;$item_link" >> "$output_file"

done < <(tail -n +2 "$input_file")