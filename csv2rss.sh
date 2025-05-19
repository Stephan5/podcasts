#!/bin/bash
set -euo pipefail

url_encode() {
  python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1], safe=':/()'))" "$1"
}

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

# Input Defaults
input_file=""
repo_dir=""
podcast_title=""
podcast_description=""
podcast_image_link=""
csv_delimiter=","

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-dir) repo_dir="$2"; shift 2 ;;
    --title) podcast_title="$2"; shift 2 ;;
    --description) podcast_description="$2"; shift 2 ;;
    --image-link) podcast_image_link="$2"; shift 2 ;;
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
if [[ -z "$input_file" || -z "$repo_dir" || -z "$podcast_title" ]]; then
  echo "Usage: $0 input_file --repo-dir DIR --title TITLE [--description DESC] [--image-link URL] [--delimiter DELIMITER]" >&2
  echo "Error: Missing required argument(s)" >&2
  exit 1
fi

csv_filename=$(basename "$input_file")
csv_file=./"$repo_dir"/"$csv_filename"

# Create repo dir and Copy input file to it
mkdir -p "$repo_dir"
if [[ "$(realpath "$input_file")" != "$(realpath "$csv_file")" ]]; then
  cp "$input_file" "$csv_file"
fi

output_file="${output_file:-${csv_file%%.csv}.xml}"
feed_filename=$(basename "$output_file")
repo="Stephan5/rss"
raw_content="https://raw.githubusercontent.com/$repo/refs/heads/main/$repo_dir"
repo_link="https://github.com/$repo/tree/main/$repo_dir"
self_feed_link="$raw_content/$feed_filename"

if [[ -z "$podcast_image_link" ]]; then
  podcast_image_link="$raw_content/image.jpg"
fi

cat > "$output_file" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"
     xmlns:atom="http://www.w3.org/2005/Atom"
     xmlns:content="http://purl.org/rss/1.0/modules/content/"
     xmlns:wfw="http://wellformedweb.org/CommentAPI/"
     xmlns:dc="http://purl.org/dc/elements/1.1/"
     xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd"
     xmlns:googleplay="http://www.google.com/schemas/play-podcasts/1.0"
     xmlns:spotify="http://www.spotify.com/ns/rss"
     xmlns:podcast="https://podcastindex.org/namespace/1.0"
     xmlns:media="http://search.yahoo.com/mrss/">
<channel>
    <atom:link href="$self_feed_link" rel="self" type="application/rss+xml"/>
    <title>$podcast_title</title>
    <description>$podcast_description
    <br/><br/>
     Generated using $repo</description>
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
  IFS=$csv_delimiter read -r item_number item_title item_description item_date item_link <<< "$line"

  if [[ $(validate_rfc2822_date "$item_date") == "invalid" ]]; then
    echo "Invalid date $item_date for item $item_title. Dates must be in RFC 2822 format."
    exit 1
  fi

  # encode URL
  item_link=$(url_encode "$item_link")

  response_headers=$(curl --silent --head --fail "$item_link")
  redirect_location=$(echo "$response_headers" | grep -i "^Location:" | cut -d " " -f 2 | tr -d '\r\n[:space:]' || true)

  # FIXME I don't think extracting the redirects is necessary (or even desired), and can just use "curl -L" to follow all redirects to validate links and get content length
  # If there's a redirect, fetch the content-length from the redirect target
  if [[ -n "$redirect_location" ]]; then
    content_length=$(curl --silent --head --fail "$redirect_location" | grep -i "Content-Length:" | cut -d " " -f 2 | tr -d '\r\n[:space:]')
  else
    content_length=$(echo "$response_headers" | grep -i "Content-Length:" | cut -d " " -f 2 | tr -d '\r\n[:space:]')
  fi

  item_link=${redirect_location:-$item_link}

  item_desc=${item_description:-"$item_title - Episode $item_number of $podcast_title"}

  {
    echo "<item>" >> "$output_file";
    echo "<link>$item_link</link>";
    echo "<guid>$item_link</guid>";
    echo "<title>$item_number - $item_title</title>";
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

echo "Created podcast RSS XML feed: $(realpath "$output_file")"
echo 'Check with: https://validator.livewire.io'
