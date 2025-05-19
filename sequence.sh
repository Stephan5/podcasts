#!/bin/bash
set -euo pipefail
trap 'echo "Error on line $LINENO: Command exited with status $?" >&2' ERR

input_file=""
csv_delimiter=","

while [[ $# -gt 0 ]]; do
  case "$1" in
    --delimiter) csv_delimiter="$2"; shift 2 ;;
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

item_number=1

while IFS= read -r line; do
  IFS="$csv_delimiter" read -r _ item_title item_description item_date item_link <<< "$line"

  echo "$item_number$csv_delimiter$item_title$csv_delimiter$item_description$csv_delimiter$item_date$csv_delimiter$item_link" >> "$tmp_file"

  ((item_number++))  # increment counter

done < <(tail -n +2 "$input_file")

# backup output file if exists
mv "$output_file" "$output_file".old;

# replace output file with our new one
mv "$tmp_file" "$output_file"
