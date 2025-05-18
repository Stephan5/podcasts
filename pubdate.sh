#!/bin/bash
set -euo pipefail

input_file=""
input_format="%Y %m %d"
csv_delimiter=","

while [[ $# -gt 0 ]]; do
  case "$1" in
    --delimiter) csv_delimiter="$2"; shift 2 ;;
    --input-format) input_format="$2"; shift 2 ;;
    --) shift; break ;;
    --*) echo "Unknown option: $1" >&2; exit 1 ;;
    *)
      if [[ -z "$input_file" ]]; then
        input_file="$1"
      else
        echo "Unexpected extra argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

output_file="${output_file:-${input_file%%.csv}.out.csv}"

IFS= read -r header < "$input_file"

echo "$header" > "$output_file"

while IFS= read -r line; do
  IFS="$csv_delimiter" read -r item_number item_title item_description item_date item_link <<< "$line"

  # reformat Date
  # item_date=${item_date//","/""}
  item_date=$(date -jf "$input_format" "$item_date" '+%a, %d %b %Y 03:00:00 GMT')

  echo "$item_number$csv_delimiter$item_title$csv_delimiter$item_description$csv_delimiter$item_date$csv_delimiter$item_link" >> "$output_file"

done < <(tail -n +2 "$input_file")