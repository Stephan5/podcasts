#!/bin/bash
set -euo pipefail
trap 'echo "Error on line $LINENO: Command exited with status $?" >&2' ERR

# Example:
# ./selfhost.sh ./mssp/feed.csv --delimiter ";" --repo-dir "mssp" --bucket "podcast.mysite.co.uk"

url_encode() {
  python3 -c "import urllib.parse, sys; print(urllib.parse.quote(urllib.parse.unquote(sys.argv[1]), safe=':/()'))" "$1"
}

input_file=""
repo_dir=""
bucket=""
csv_delimiter=","

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-dir) repo_dir="$2"; shift 2 ;;
    --bucket) bucket="$2"; shift 2 ;;
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
if [[ -z "$input_file" || -z "$repo_dir" || -z "$bucket" ]]; then
  echo "Usage: $0 input_file --repo-dir DIR --bucket BUCKET" >&2
  echo "Error: Missing required argument(s)" >&2
  exit 1
fi

tmp_file=$(mktemp)
output_file="${output_file:-${input_file}}"

# Get the S3 bucket region
region=$(aws s3api get-bucket-location --bucket "$bucket" --query "LocationConstraint" --output text)
if [[ "$region" == "None" ]]; then
  exit 1
fi

echo "Input File: \"$input_file\""
echo "Repo Directory: \"$repo_dir\""
echo "CSV Delimiter: \"$csv_delimiter\""
echo "Output File: \"$output_file\""
echo "Bucket: \"$bucket\""
echo "Region: \"$region\""

# Read the CSV line by line
while IFS= read -r line; do
  IFS=$csv_delimiter read -r item_number item_title item_description item_date src_url <<< "$line"

  # Skip the header if present
  if [[ "$item_number" == "ordinal" ]]; then
    echo "$item_number$csv_delimiter$item_title$csv_delimiter$item_description$csv_delimiter$item_date$csv_delimiter$src_url" >> "$tmp_file"
    continue
  fi

  # Extract the file name from the link
  file_name=$(basename "$src_url")

  # Encode URLs
  src_url_enc=$(url_encode "$src_url")
  self_hosted_url=$(url_encode "https://s3.$region.amazonaws.com/$bucket/$repo_dir/$file_name")

  echo "Source URL (Encoded): \"$src_url_enc\""
  echo "Self-Hosted URL: \"$self_hosted_url\""
  echo "File Name: \"$file_name\""

  # Check if the link is a local file
  if [[ "$src_url" == "https://s3.$region.amazonaws.com/$bucket"* ]]; then
      echo "Link already self-hosted: \"$src_url\". Skipping."
      new_link="$src_url"

  # Check if the link is valid
  elif [[ -f "$src_url" ]]; then
    echo "Local file detected: \"$src_url\". Attempting to upload to S3."

    if aws s3 cp "$src_url" "s3://$bucket/$repo_dir/$file_name"; then
      new_link=$self_hosted_url
      echo "Successfully uploaded local file to S3: \"$new_link\""
    else
      echo "Failed to upload local file \"$src_url\" to S3. Keeping the original path."
      new_link="$src_url"
    fi

  # Check if the link is valid and not already self-hosted
  elif curl --head --silent --fail --location "$src_url_enc" > /dev/null; then
    # Download the file locally
    temp_download=$(mktemp)
    echo "Attempting to download file for $item_title from provided link"
    if curl --silent --fail --location "$src_url_enc" --output "$temp_download"; then
      # Transfer the downloaded file to S3
      echo "Attempting to upload file for $item_title to S3"
      if aws s3 cp "$temp_download" "s3://$bucket/$repo_dir/$file_name"; then
        # Construct the normalized HTTPS link
        new_link=$self_hosted_url

	      # Check if the link is a valid S3 link
	      curl --head --silent --fail --location "$new_link" > /dev/null;
      else
        echo "Failed to upload $src_url_enc to S3. Keeping the original link."
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
  echo "$item_number$csv_delimiter$item_title$csv_delimiter$item_description$csv_delimiter$item_date$csv_delimiter$new_link" >> "$tmp_file"
done < "$input_file"

# backup output file if exists
cp "$output_file" "$output_file".old;

# replace output file with our new one
mv "$tmp_file" "$output_file"
