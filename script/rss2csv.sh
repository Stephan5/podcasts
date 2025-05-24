#!/bin/bash
source "$(dirname "$0")/common.sh"
set -euo pipefail
trap 'echo "Error on line $LINENO: Command exited with status $?" >&2' ERR

# Input Defaults
input_file=""
repo_dir=""
csv_delimiter=","

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-dir) repo_dir="$2"; shift 2 ;;
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

# Validate required args
if [[ -z "$input_file" || -z "$repo_dir" ]]; then
  echo "Usage: $0 input_file --repo-dir DIR [--delimiter DELIMITER]" >&2
  echo "Error: Missing required argument(s)" >&2
  exit 1
fi

# Define base directory
base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../feed" && pwd)"

# set up base paths
input_file_abs="$(cd "$(dirname "$input_file")" && pwd)/$(basename "$input_file")"
if [[ ! -f "$input_file_abs" ]]; then
    echo "Error: Input file '$input_file_abs' not found" >&2
    exit 1
fi

feed_repo_path="$base_dir"/"$repo_dir"

echo "Base Directory: \"$base_dir\""
echo "Feed Repo Path: \"$feed_repo_path\""

xml_filename=$(basename "$input_file")
xml_file="$feed_repo_path"/"$xml_filename"

# Create repo dir and Copy input file to it
mkdir -p "$feed_repo_path"
if [[ "$(realpath "$input_file")" != "$(realpath "$xml_file")" ]]; then
  cp "$input_file" "$xml_file"
fi

tmp_xml_file=$(mktemp)
tmp_output_file=$(mktemp)
output_file="${output_file:-${xml_file%%.xml}.csv}"
csv_filename=$(basename "$output_file")

echo "Input File: \"$input_file\""
echo "Repo Directory: \"$repo_dir\""
echo "CSV Delimiter: \"$csv_delimiter\""
echo "XML File: \"$xml_file\""
echo "Temporary XML File: \"$tmp_xml_file\""
echo "Temporary Output File: \"$tmp_output_file\""
echo "Output File: \"$output_file\""
echo "CSV Filename: \"$csv_filename\""
echo

# copy input to temporary file
cp "$input_file" "$tmp_xml_file"

# reformat xml file
xmllint --format "$tmp_xml_file" -o "$tmp_xml_file"

# extract and echo top-level metadata
feed_title=$(xmlstarlet sel -t -v "normalize-space(//channel/title)" "$tmp_xml_file")
feed_description=$(xmlstarlet sel -t -v "normalize-space(//channel/description)" "$tmp_xml_file")
feed_website=$(xmlstarlet sel -t -v "normalize-space(//channel/link)" "$tmp_xml_file")
image_url=$(xmlstarlet sel -t -v "normalize-space(//channel/image/url)" "$tmp_xml_file")
self_feed_url=$(xmlstarlet sel -N atom="http://www.w3.org/2005/Atom" -t -v "//atom:link[@rel='self']/@href" "$tmp_xml_file")

# write CSV headers
echo "title${csv_delimiter}description${csv_delimiter}date${csv_delimiter}url${csv_delimiter}length" > "$tmp_output_file"

# temp file for unsorted items
tmp_raw_items=$(mktemp)
tmp_items=$(mktemp)

# append extracted values from the XML
xmlstarlet sel -t -m "//item" \
  -v "normalize-space(title)" -o "$csv_delimiter" \
  -v "normalize-space(description)" -o "$csv_delimiter" \
  -v "pubDate" -o "$csv_delimiter" \
  -v "enclosure/@url" -o "$csv_delimiter" \
  -v "enclosure/@length" -n \
  "$tmp_xml_file" >> "$tmp_raw_items"

# process and validate each line
while IFS="$csv_delimiter" read -r title description pubdate url length; do
  echo "Title: \"$title\""
  echo "PubDate: \"$pubdate\""
  echo "URL: \"$url\""
  echo "Content Length: \"$length\""

  if ! validate_rfc2822_date "$pubdate"; then
    echo "Item failed date validation $title $pubdate"
    exit 1
  fi

  sortable_date=$(parse_rfc2822_date "$pubdate")

  decoded_url=$(html_decode "$url")

  echo "Decoded Link: \"$decoded_url\""
  echo

  echo "$title$csv_delimiter$description$csv_delimiter$pubdate$csv_delimiter$decoded_url$csv_delimiter$length$csv_delimiter$sortable_date" >> "$tmp_items"
done < "$tmp_raw_items"

# sort by date (6th field = sortable_date)
LC_ALL=C sort -t "$csv_delimiter" -k5 "$tmp_items" | \
# remove the sortable_date (6th field), keep 1st,2nd,3rd,4th and 5th fields
awk -F"$csv_delimiter" -v OFS="$csv_delimiter" '{ print $1, $2, $3, $4, $5 }' >> "$tmp_output_file"

# replace output file with our new one
mv "$tmp_output_file" "$output_file"

# remove temporary files
rm "$tmp_xml_file"
rm "$tmp_raw_items"
rm "$tmp_items"

echo "Feed Title: \"$feed_title\""
echo "Feed Description: \"$feed_description\""
echo "Feed Link: \"$feed_website\""
echo "Image URL: \"$image_url\""
echo "Feed URL: \"$self_feed_url\""
echo

echo "Created CSV from podcast XML feed: $(realpath "$output_file")"
