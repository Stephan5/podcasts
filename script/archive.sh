#!/bin/bash
source "$(dirname "$0")/common.sh"
set -Eeuo pipefail
trap 'echo "Error on line $LINENO: Command exited with status $?" >&2' ERR

input_dir=""
output_dir=""
csv_delimiter=$'\x1F'

while [[ $# -gt 0 ]]; do
  case "$1" in
    --delimiter) csv_delimiter="$2"; shift 2 ;;
    --) shift; break ;;
    --*) echo "Unknown option: $1" >&2; exit 1 ;;
    *)
      if [[ -z "$input_dir" ]]; then
        input_dir="$1"
      elif [[ -z "$output_dir" ]]; then
        output_dir="$1"
      else
        echo "Unexpected extra argument: $1" >&2
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$input_dir" || -z "$output_dir" ]]; then
  echo "Usage: $0 input_dir output_dir" >&2
  echo "Error: Missing required argument(s)" >&2
  exit 1
fi

input_dir="$(realpath "$input_dir")"
if [[ ! -d "$input_dir" ]]; then
    echo "Error: Input directory '$input_dir' not found" >&2
    exit 1
fi

output_dir="$(realpath "$output_dir")"
if [[ ! -d "$output_dir" ]]; then
    echo "Error: Output directory '$output_dir' not found" >&2
    exit 1
fi

feed_name="$(basename "$input_dir")"
feed_dir="$output_dir/$feed_name"
media_dir="$feed_dir/items"

mkdir -p "$feed_dir" "$media_dir"

if [[ ! -d "$feed_dir" ]]; then
    echo "Error: Feed directory '$feed_dir' not found" >&2
    exit 1
fi

# Find CSV file in the input directory
csv_files=()
while IFS= read -r file; do
  csv_files+=("$file")
done < <(find "$input_dir" -maxdepth 1 -type f -name "*.csv")

if [[ ${#csv_files[@]} -eq 0 ]]; then
  echo "Error: No CSV files found in '$input_dir'" >&2
  exit 1
fi

if [[ ${#csv_files[@]} -gt 1 ]]; then
  echo "Error: Multiple CSV files found in '$input_dir'. Please provide a directory with only one CSV file." >&2
  exit 1
fi

input_csv="${csv_files[0]}"
echo "Using CSV file: $input_csv"

tmp_directory=$(mktemp -d)
tmp_csv=$(mktemp)

echo "Input Directory: \"$input_dir\""
echo "Output Directory: \"$output_dir\""
echo "Feed Directory: \"$feed_dir\""
echo "Temp Directory: \"$tmp_directory\""
echo "Temp CSV: \"$tmp_csv\""
echo "CSV Delimiter: \"$csv_delimiter\""

# Read the CSV line by line
while IFS= read -r line; do
  IFS=$csv_delimiter read -r item_title item_description item_date src_url <<< "$line"

  # Skip the header if present
  if [[ "$item_title" == "title" ]]; then
    echo "$item_title$csv_delimiter$item_description$csv_delimiter$item_date$csv_delimiter$src_url" >> "$tmp_csv"
    continue
  fi

  # Extract filename from URL
  clean_url="${src_url%%\?*}"
  filename="${clean_url##*/}"

  # Check extension
  if [[ ! "$filename" =~ \.(mp3|m4a|m4b|ogg)$ ]]; then
      echo "Failed to detect supported extension in filename \"$filename\""
      exit 1
  fi

  # Encode URLs
  echo "Src URL: \"$src_url\""
  if has_encoding "$src_url"; then
    src_url_enc=$src_url
  else
    src_url_enc=$(url_encode "$src_url")
    echo "Encoded Src URL: \"$src_url\""
  fi

  echo "File Name: \"$filename\""

  if validate_url "$src_url_enc"; then
    echo "Downloading file for \"$filename\" from URL \"$src_url_enc\""
    if curl --silent --fail --location "$src_url_enc" --output "$tmp_directory/$filename"; then
      echo "Successfully downloaded to \"$tmp_directory/$filename\""
    else
      echo "Failed to download $src_url_enc"
      exit 1
    fi
  else
    echo "Invalid link: \"$src_url_enc\""
    exit 1
  fi

  local_file="file://$(basename "$media_dir")/$filename"
  echo "Eventual relative file location: \"$local_file\""
  echo "$item_title$csv_delimiter$item_description$csv_delimiter$item_date$csv_delimiter$local_file" >> "$tmp_csv"

  echo

done < "$input_csv"

echo "Moving downloaded files to output directory: $media_dir"
mv "$tmp_directory"/* "$media_dir"

echo "Copying any files in input directory to output directory: $feed_dir"
cp "$tmp_csv" "$feed_dir/local.csv"
cp -r $input_dir/* "$feed_dir"
rm -r "$feed_dir/cmd.sh" || true

echo "Archive of podcast files completed successfully in: $output_dir"
rm -rf "$tmp_directory"
rm -r "$tmp_csv"