#!/bin/bash
source "$(dirname "$0")/common.sh"
set -euo pipefail
trap 'echo "Error on line $LINENO: Command exited with status $?" >&2' ERR

# Example:
# ./pubdate.sh ./mssp/feed.csv --input-format "%b %d, %Y" --delimiter ";"

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

tmp_file=$(mktemp)
output_file="${output_file:-${input_file}}"

IFS= read -r header < "$input_file"

echo "$header" > "$tmp_file"

while IFS= read -r line; do
  IFS="$csv_delimiter" read -r item_title item_description item_date item_link <<< "$line"

  # normalize the date by removing any period after the abbreviated month name
  item_date=${item_date//./}

  # reformat date
  item_date=$(format_date "$item_date" "$input_format" '+%a, %d %b %Y 03:00:00 GMT')

  echo "$item_title$csv_delimiter$item_description$csv_delimiter$item_date$csv_delimiter$item_link" >> "$tmp_file"

done < <(tail -n +2 "$input_file")

# backup output file if exists
mv "$output_file" "$output_file".old;

# replace output file with our new one
mv "$tmp_file" "$output_file"
