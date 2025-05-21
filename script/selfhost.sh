#!/bin/bash
source "$(dirname "$0")/common.sh"
set -euo pipefail
trap 'echo "Error on line $LINENO: Command exited with status $?" >&2' ERR

# Example:
# ./selfhost.sh ./mssp/feed.csv --delimiter ";" --repo-dir "mssp" --bucket "podcast.mysite.co.uk"

s3_cp() {
  local src="$1"
  local dst="$2"
  if aws s3 cp "$src" "$dst"; then
    validate_url "$dst"
    return 0
  else
    echo "Failed to transfer $src to $dst." >&2
    return 1
  fi
}

s3_mv() {
  local src="$1"
  local dst="$2"
  if aws s3 mv "$src" "$dst"; then
    validate_url "$dst"
    return 0
  else
    echo "Failed to transfer $src to $dst." >&2
    return 1
  fi
}

input_file=""
bucket=""
prefix=""
region="eu-west-2"
csv_delimiter=","

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bucket) bucket="$2"; shift 2 ;;
    --prefix) prefix="$2"; shift 2 ;;
    --region) region="$2"; shift 2 ;;
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
if [[ -z "$input_file" || -z "$bucket" ]]; then
  echo "Usage: $0 input_file --bucket BUCKET" >&2
  echo "Error: Missing required argument(s)" >&2
  exit 1
fi

tmp_file=$(mktemp)
output_file="${output_file:-${input_file}}"

# set up base paths
input_file_abs="$(cd "$(dirname "$input_file")" && pwd)/$(basename "$input_file")"
if [[ ! -f "$input_file_abs" ]]; then
    echo "Error: Input file '$input_file_abs' not found" >&2
    exit 1
fi

# assuming $input_file is your CSV file path (e.g., ./feed/matt-and-shane/feed.csv)
repo_dir="$(basename "$(dirname "$input_file_abs")")"


echo "About to check region for bucket \"$bucket\""

echo "Input File: \"$input_file\""
echo "Temp File: \"$tmp_file\""
echo "Output File: \"$output_file\""
echo "Repo Directory: \"$repo_dir\""
echo "CSV Delimiter: \"$csv_delimiter\""
echo "Bucket: \"$bucket\""
echo "Prefix: \"$prefix\""
echo "Region: \"$region\""

item_number=1  # initialize before the loop

# Read the CSV line by line
while IFS= read -r line; do
  IFS=$csv_delimiter read -r item_title item_description item_date src_url <<< "$line"

  # Skip the header if present
  if [[ "$item_title" == "title" ]]; then
    echo "$item_title$csv_delimiter$item_description$csv_delimiter$item_date$csv_delimiter$src_url" >> "$tmp_file"
    continue
  fi

  # Remove query parameters
  clean_url="${src_url%%\?*}"

  # Extract the filename
  url_filename="${clean_url##*/}"

  # Extract extension
  if [[ "$url_filename" == *.* ]]; then
    extension="${url_filename##*.}"
  else
    echo "No extension found in filename from URL \"$url_filename\", defaulting to mp3"
    extension="mp3"
  fi

  # Build filename
  file_name=$(echo "$item_number-$item_title" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//' | sed 's/-$//')
  file_name="${file_name}.${extension}"

  # Encode URLs
  if has_encoding "$src_url"; then
    src_url_enc=$src_url
  else
    src_url_enc=$(url_encode "$src_url")
    echo "Encoded URL: $src_url_enc"
  fi

  http_dst_link=$(url_encode "https://s3.$region.amazonaws.com/$bucket$prefix/$repo_dir/$file_name")
  s3_dst_link=$(convert_to_s3 "$http_dst_link")

  echo "Src URL (Encoded): \"$src_url_enc\""
  echo "Dst URL: \"$http_dst_link\""
  echo "Dst S3: \"$http_dst_link\""
  echo "File Name: \"$file_name\""
  echo "Extension: \"$extension\""

  # Check already exists, if so, skip
  if [[ "$src_url_enc" == "$http_dst_link" ]]; then
        echo "Link already self-hosted: \"$src_url_enc\". Skipping."
        new_link="$src_url_enc"

  # Check if link is already in the bucket, if so move it
  elif [[ "$src_url_enc" == "https://s3.$region.amazonaws.com/$bucket"* ]]; then
      echo "Link already self-hosted: \"$src_url_enc\". Moving to new location \"$http_dst_link\""
      new_link="$http_dst_link"

      # Check src link is a valid link
      validate_url "$src_url_enc"

     decoded_src_link=$(url_decode "$src_url")
     echo "Src URL (decoded): \"$decoded_src_link\""
     s3_src_link=$(convert_to_s3 "$decoded_src_link")
     echo "Src S3: \"$s3_src_link\""

     if s3_mv "$s3_src_link" "$s3_dst_link"; then
       new_link="$http_dst_link"
     else
       new_link="$src_url_enc"
     fi

  # Check if the link is a local file
  elif [[ -f "$src_url" ]]; then
    echo "Local file detected: \"$src_url\". Attempting to upload to S3."

    if s3_cp "$src_url" "$s3_dst_link"; then
      new_link="$http_dst_link"
    else
      new_link="$src_url_enc"
    fi

  # Check if the link is valid
  elif validate_url "$src_url_enc"; then
    # Download the file locally
    temp_download=$(mktemp)
    echo "Attempting to download file for \"$file_name\" from provided link"
    if curl --silent --fail --location "$src_url_enc" --output "$temp_download"; then
      # Transfer the downloaded file to S3
      echo "Attempting to upload file for \"$file_name\" to S3"
      if s3_cp "$temp_download" "$s3_dst_link"; then
        new_link="$http_dst_link"
      else
        new_link="$src_url_enc"
      fi
    else
      echo "Failed to download $src_url_enc. Keeping the original link."
      new_link="$src_url_enc"
    fi

    # Clean up the temporary file
    rm -f "$temp_download"

  else
    echo "Invalid link: \"$src_url_enc\". Keeping the original link."
    new_link="$src_url_enc"
  fi

  echo
  # Write the updated line to the temp file
  echo "$item_title$csv_delimiter$item_description$csv_delimiter$item_date$csv_delimiter$new_link" >> "$tmp_file"

  ((item_number++))  # increment item_number
done < "$input_file"

# backup output file if exists
mv "$output_file" "$output_file".old;

# replace output file with our new one
mv "$tmp_file" "$output_file"
