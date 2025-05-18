#!/bin/bash
set -euo pipefail

# This script takes a CSV file of podcast episodes along with other podcast details and outputs an XML feed file
# The CSV must be of the form: ordinal,title,description,date,link
# Where ordinal and description are optional.

# Example invocation:
#   ./csv2rss.sh ./feed.csv \
#     --repo-dir "mssp" \
#     --title "Matt and Shane's Secret Podcast" \
#     --description "Grab onto this fast moving train and witness two comedians rise to victory and splendor." \
#     --image-link "https://is5-ssl.mzstatic.com/image/thumb/Music128/v4/00/fe/d2/00fed269-058c-1fc9-7c52-061940ee7e93/source/1200x630bb.jpg"

# Where "repo-dir" is the directory within the rss repo you would like to store your output file and consequently forms part of the feed URL

# Requirements:
#  * GNU getopt (brew install gnu-getopt on macOS)
#  * Must be ran from the top-level of the `rss` repo.

validate_rfc2822_date() {
  local input="$1"

  # Normalize GMT → +0000 for stricter parsing
  input="${input/GMT/+0000}"

  python3 -c '
import sys
from email.utils import parsedate_to_datetime

try:
    parsedate_to_datetime(sys.argv[1])
    print("valid")
except Exception:
    print("invalid")
' "$input"
}

command_issued="$0 $*"

# Input Defaults
input_file=""
repo_dir=""
podcast_title=""
podcast_description=""
podcast_image_link=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-dir) repo_dir="$2"; shift 2 ;;
    --title) podcast_title="$2"; shift 2 ;;
    --description) podcast_description="$2"; shift 2 ;;
    --image-link) podcast_image_link="$2"; shift 2 ;;
    --) shift; break ;;
    --*) echo "Unknown option: $1" >&2; exit 1 ;;
    *)  # Positional arg
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
if [[ -z "$input_file" || -z "$repo_dir" || -z "$podcast_title" ]]; then
  echo "Usage: $0 input_file --repo-dir DIR --title TITLE [--description DESC] [--image-link URL]" >&2
  echo "Error: Missing required argument(s)" >&2
  exit 1
fi

csv_filename=$(basename "$input_file")
csv_file=./"$repo_dir"/"$csv_filename"

# Create repo dir and Copy input file to it
mkdir -p "$repo_dir"
cp "$input_file" "$csv_file"

output_file="${output_file:-${csv_file%%.csv}.xml}"
feed_filename=$(basename "$output_file")
repo_link="https://github.com/Stephan5/rss/$repo_dir"
self_feed_link="$repo_link/tree/main/$feed_filename"

echo "$command_issued" >> "./$repo_dir/cmd.txt"

#echo "Input file: $input_file"
#echo "Input filename: $csv_filename"
#echo "Output file: $output_file"
#echo "Output filename: $feed_filename"
#echo "Repo dir: $repo_dir"
#echo "Podcast title: $podcast_title"
#echo "Podcast description: ${podcast_description:-<none>}"
#echo "Podcast image link: ${podcast_image_link:-<none>}"

cat > "$output_file" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"
     xmlns:atom="http://www.w3.org/2005/Atom">
<channel>
    <atom:link href="$self_feed_link" rel="self" type="application/rss+xml"/>
    <title>$podcast_title</title>
    <description>$podcast_description</description>
    <language>en-gb</language>
    <copyright>none</copyright>
    <link>$repo_link</link>
    <image>
       <url>$podcast_image_link</url>
       <title>$podcast_title</title>
       <link>$repo_link</link>
    </image>
    <generator>csv2rss.sh v 0.01</generator>
    <ttl>1440</ttl>
EOF

{
  echo "<lastBuildDate>$(date -R)</lastBuildDate>";
  echo "<pubDate>$(date -R)</pubDate>";
  echo
} >> "$output_file"

while IFS= read -r line; do
  IFS=';' read -r item_number item_title item_description item_date item_link <<< "$line"

  # encode link
  # TODO fix this
  item_link=${item_link//" "/"%20"}
  item_link=${item_link//"["/"%5B"}
  item_link=${item_link//"]"/"%5D"}
  item_link=${item_link//"!"/"%21"}
  item_link=${item_link//"#"/"%23"}
  item_link=${item_link//"'"/"%27"}

  if [[ $(validate_rfc2822_date "$item_date") == "invalid" ]]; then
    echo "Invalid date $item_date for item $item_title. Dates must be in RFC 2822 format."
    exit 1
  fi

  # check link & extract content length
  content_length=$(curl "$item_link" --silent --head --fail | grep "content-length:" | cut -d " " -f 2 | tr -d '\r\n[:space:]')

  item_desc=${item_description:-"Episode $item_number of Matt and Shane's Secret Podcast"}

  {
    echo "<item>" >> "$output_file";
    echo "<link>$item_link</link>";
    echo "<guid>$item_link</guid>";
    echo "<title>$item_title</title>";
    echo "<description>$item_desc</description>";
    echo "<pubDate>$item_date</pubDate>";
    echo "<enclosure url=\"$item_link\" length=\"$content_length\" type=\"audio/mpeg\"/>";
    echo "</item>";
    echo
  } >> "$output_file"

done < <(tail -n +2 "$input_file")

cat >> "$output_file" <<EOF
</channel>
</rss>
EOF

#
# echo 'Please check result with: https://validator.w3.org/feed/#validate_by_input '
