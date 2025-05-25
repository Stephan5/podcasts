#!/bin/bash
source "$(dirname "$0")/common.sh"
set -euo pipefail
trap 'echo "Error on line $LINENO: Command exited with status $?" >&2' ERR

# Input Defaults
input_file=""
podcast_title=""
podcast_description=""
podcast_website_url=""
podcast_image_url=""
podcast_feed_url=""
csv_delimiter=","

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) podcast_title="$2"; shift 2 ;;
    --description) podcast_description="$2"; shift 2 ;;
    --website) podcast_website_url="$2"; shift 2 ;;
    --image-url) podcast_image_url="$2"; shift 2 ;;
    --feed-url) podcast_feed_url="$2"; shift 2 ;;
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
if [[ -z "$input_file" || -z "$podcast_title" ]]; then
  echo "Usage: $0 input_file --title TITLE [--description DESC] [--image-url URL] [--delimiter DELIMITER]" >&2
  echo "Error: Missing required argument(s)" >&2
  exit 1
fi

# set up base paths
input_file_abs="$(cd "$(dirname "$input_file")" && pwd)/$(basename "$input_file")"
if [[ ! -f "$input_file_abs" ]]; then
    echo "Error: Input file '$input_file_abs' not found" >&2
    exit 1
fi

# assuming $input_file is your CSV file path (e.g., ./feed/matt-and-shane/feed.csv)
repo_dir="$(basename "$(dirname "$input_file_abs")")"
feed_base_dir="$(cd "$(dirname "$(dirname "$input_file_abs")")" && pwd)"
feed_repo_path="feed/$repo_dir"

# Ensure feed directory exists
if [[ ! -d "$feed_base_dir" ]]; then
    echo "Error: feed directory not found at '$feed_base_dir'" >&2
    exit 1
fi

# Create repo path
repo_path="$feed_base_dir/$repo_dir"
if [[ ! -d "$repo_path" ]]; then
    echo "Creating directory: $repo_path"
    mkdir -p "$repo_path"
fi

# Get paths with proper directory structure
csv_filename=$(basename "$input_file")
csv_file="$repo_path/$csv_filename"

# Create repo dir and copy input file to it
if [[ "$(realpath "$input_file")" != "$(realpath "$csv_file")" ]]; then
  cp "$input_file" "$csv_file"
fi

tmp_xml=$(mktemp)
tmp_csv=$(mktemp)
output_file="${output_file:-${csv_file%%.csv}.xml}"
feed_filename=$(basename "$output_file")
repo="Stephan5/podcasts"
raw_content="https://raw.githubusercontent.com/$repo/refs/heads/main/$feed_repo_path"
repo_link="https://github.com/$repo"

# Default podcast hosting URLs
if [[ -z "$podcast_website_url" ]]; then
  podcast_website_url="$repo_link/tree/main/$feed_repo_path"
fi

if [[ -z "$podcast_feed_url" ]]; then
  podcast_feed_url="$raw_content/$feed_filename"
fi

if [[ -z "$podcast_image_url" ]]; then
  podcast_image_url="$raw_content/image.jpg"
fi

echo "Podcast Title: \"$podcast_title\""
echo "Podcast Description: \"$podcast_description\""
echo "Podcast Website: \"$podcast_website_url\""
echo "Podcast Image URL: \"$podcast_image_url\""
echo "Podcast Feed URL: \"$podcast_feed_url\""
echo
echo "Input File: \"$input_file\""
echo "Repo Directory: \"$repo_dir\""
echo "CSV Delimiter: \"$csv_delimiter\""
echo "CSV File: \"$csv_file\""
echo "Temporary File: \"$tmp_xml\""
echo "Output File: \"$output_file\""
echo

cat > "$tmp_xml" <<EOF
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
    <atom:link href="$podcast_feed_url" rel="self" type="application/rss+xml"/>
    <title>$podcast_title</title>
    <description>&lt;p&gt;$podcast_description &lt;/p&gt;&lt;br/&gt;&lt;br/&gt;&lt;p&gt;Generated using $repo.&lt;/p&gt;</description>
    <language>en-gb</language>
    <copyright>none</copyright>
    <link>$podcast_website_url</link>
    <image>
       <url>$podcast_image_url</url>
       <title>$podcast_title</title>
       <link>$podcast_website_url</link>
    </image>
    <generator>Stephan5/podcasts</generator>
    <ttl>1440</ttl>
EOF

{
  echo "<lastBuildDate>$(date -R)</lastBuildDate>";
  echo "<pubDate>$(date -R)</pubDate>";
} >> "$tmp_xml"

# Insert header into temp CSV file
echo "title${csv_delimiter}description${csv_delimiter}date${csv_delimiter}url${csv_delimiter}length" > "$tmp_csv"

item_number=1  # initialize before the loop

while IFS= read -r line; do
  IFS=$csv_delimiter read -r item_title item_description item_date item_link item_length <<< "$line"

  echo "Title: \"$item_title\""
  echo "Date: \"$item_date\""
  echo "Link: \"$item_link\""

  # validate date
  if ! validate_rfc2822_date "$item_date"; then
    echo "Invalid date $item_date for item $item_title. Dates must be in RFC 2822 format."
    exit 1
  fi

  # fallback to default description if not specified
  item_desc=${item_description:-"$item_title - Episode $item_number of $podcast_title"}
  item_desc=$(echo "$item_desc&lt;br/&gt;&lt;br/&gt;&lt;a href=\"$repo_link\" rel=\"nofollow noopener\" target=\"_blank\"&gt;Generated using $repo&lt;/a&gt;")

  # url encode URL
  if ! has_encoding "$item_link"; then
    item_link=$(url_encode "$item_link")
    echo "URL encoded URL: $item_link"
  fi

  # extract content length
  if [[ -z "$item_length" ]]; then
    item_length=$(curl "$item_link" --location --silent --head --fail | grep -i "content-length:" | cut -d " " -f 2 | tr -d '\r\n[:space:]')
    echo "Content-Length fetched: \"$item_length\""
  else
    echo "Content-Length provided: \"$item_length\""
  fi

  # html encode URL
  item_link=$(html_encode "$item_link")
  echo "HTML encoded URL: $item_link"

  # input item into file
  {
    echo "<item>";
    echo "<link>$item_link</link>";
    echo "<guid>$item_link</guid>";
    echo "<title>$item_number: $item_title</title>";
    echo "<description>$item_desc</description>";
    echo "<pubDate>$item_date</pubDate>";
    echo "<enclosure url=\"$item_link\" length=\"$item_length\" type=\"audio/mpeg\"/>";
    echo "</item>";
  } >> "$tmp_xml"

  # append item to temp CSV
  echo "$item_title$csv_delimiter$item_description$csv_delimiter$item_date$csv_delimiter$item_link$csv_delimiter$item_length" >> "$tmp_csv"

  ((item_number++))  # increment item_number

  echo
done < <(tail -n +2 "$input_file")

# add closing tags
cat >> "$tmp_xml" <<EOF
</channel>
</rss>
EOF

# reformat xml file
xmllint --format "$tmp_xml" -o "$tmp_xml"

# compare with existing file if any
existing_file_hash=""
if [[ -f "$output_file" ]]; then
  existing_file_hash=$(grep -vE "^    <lastBuildDate>|^    <pubDate>" "$output_file" | sha256sum | cut -d " " -f 1)
fi

temp_file_hash=$(grep -vE "^    <lastBuildDate>|^    <pubDate>" "$tmp_xml" | sha256sum | cut -d " " -f 1)

if [[ $(sha256sum "$input_file" | cut -d " " -f 1) == $(sha256sum "$tmp_csv" | cut -d " " -f 1) ]]; then
  rm "$tmp_csv"
else
  mv "$tmp_csv" "$input_file"
fi

if [[ "$existing_file_hash" == "$temp_file_hash" ]]; then
  echo "No changes detected. Skipping update."
  rm "$tmp_xml"
else
  mv "$tmp_xml" "$output_file"

  echo "Created podcast RSS XML feed: $(realpath "$output_file")"
  echo "Once deployed, check feed by entering $podcast_feed_url into https://validator.livewire.io"
fi
