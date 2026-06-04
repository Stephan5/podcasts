#!/bin/bash
source "$(dirname "$0")/common.sh"
set -Eeuo pipefail
trap 'echo "Error on line $LINENO: Command exited with status $?" >&2' ERR

# Find self-hosted files in S3 that are no longer referenced by a CSV feed.
#
# Example:
# ./script/selfhost-orphans.sh ./feed/stavvys-world/feed.csv --bucket podcast.mysite.uk
#
# Exit codes:
#   0 = success, no orphans (or orphans found but --fail-on-orphans not set)
#   2 = orphans found and --fail-on-orphans set

input_file=""
bucket=""
prefix=""
region="eu-west-2"
csv_delimiter=$'\x1F'
fail_on_orphans=0
delete_orphans=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bucket) bucket="$2"; shift 2 ;;
    --prefix) prefix="$2"; shift 2 ;;
    --region) region="$2"; shift 2 ;;
    --delimiter) csv_delimiter="$2"; shift 2 ;;
    --fail-on-orphans) fail_on_orphans=1; shift ;;
    --delete-orphans) delete_orphans=1; shift ;;
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

if [[ -z "$input_file" || -z "$bucket" ]]; then
  echo "Usage: $0 input_file --bucket BUCKET [--prefix PREFIX] [--region REGION] [--delimiter DELIM] [--fail-on-orphans] [--delete-orphans]" >&2
  exit 1
fi

input_file_abs="$(cd "$(dirname "$input_file")" && pwd)/$(basename "$input_file")"
if [[ ! -f "$input_file_abs" ]]; then
  echo "Error: Input file '$input_file_abs' not found" >&2
  exit 1
fi

repo_dir="$(basename "$(dirname "$input_file_abs")")"

# Normalize prefix: "" or "rss" (no leading/trailing slash)
prefix_norm="${prefix#/}"
prefix_norm="${prefix_norm%/}"

if [[ -n "$prefix_norm" ]]; then
  key_root="$prefix_norm/$repo_dir/"
else
  key_root="$repo_dir/"
fi

s3_root="s3://$bucket/$key_root"
http_root="https://s3.$region.amazonaws.com/$bucket/$key_root"

echo "Input File: \"$input_file_abs\""
echo "Bucket: \"$bucket\""
echo "Prefix: \"$prefix\""
echo "Region: \"$region\""
echo "Repo Directory: \"$repo_dir\""
echo "CSV Delimiter: \"$csv_delimiter\""
echo "S3 Root: \"$s3_root\""
echo "HTTP Root: \"$http_root\""
echo "Delete Orphans: \"$delete_orphans\""

# Bash 3.2-compatible approach: use temp files + sort/comm instead of associative arrays.
tmp_referenced="$(mktemp)"
tmp_remote="$(mktemp)"
tmp_orphans="$(mktemp)"

cleanup() {
  rm -f "$tmp_referenced" "$tmp_remote" "$tmp_orphans"
}
trap cleanup EXIT

# Parse CSV and collect referenced self-hosted object keys.
while IFS= read -r line; do
  IFS="$csv_delimiter" read -r item_title item_description item_date src_url <<< "$line"

  # Header
  if [[ "$item_title" == "title" ]]; then
    continue
  fi

  # Skip blank / missing URL field
  if [[ -z "${src_url:-}" ]]; then
    continue
  fi

  decoded_url="$(url_decode "$src_url")"
  clean_url="${decoded_url%%\?*}"

  # Accept both HTTPS and S3 URL forms.
  if [[ "$clean_url" =~ ^https://s3\.[^/]+\.amazonaws\.com/([^/]+)/(.+)$ ]]; then
    url_bucket="${BASH_REMATCH[1]}"
    key="${BASH_REMATCH[2]}"
    [[ "$url_bucket" == "$bucket" ]] || continue
    [[ "$key" == "$key_root"* ]] || continue
    printf "%s\n" "$key" >> "$tmp_referenced"
  elif [[ "$clean_url" =~ ^s3://([^/]+)/(.+)$ ]]; then
    url_bucket="${BASH_REMATCH[1]}"
    key="${BASH_REMATCH[2]}"
    [[ "$url_bucket" == "$bucket" ]] || continue
    [[ "$key" == "$key_root"* ]] || continue
    printf "%s\n" "$key" >> "$tmp_referenced"
  fi
done < "$input_file_abs"

# List remote keys under this feed root.
while IFS= read -r row; do
  # aws s3 ls --recursive output: DATE TIME SIZE KEY
  key="$(awk '{print $4}' <<< "$row")"
  if [[ -n "$key" ]]; then
    printf "%s\n" "$key" >> "$tmp_remote"
  fi
done < <(aws s3 ls "$s3_root" --recursive)

# Deduplicate and sort for deterministic comparison.
sort -u "$tmp_referenced" -o "$tmp_referenced"
sort -u "$tmp_remote" -o "$tmp_remote"

referenced_count="$(wc -l < "$tmp_referenced" | tr -d ' ')"
remote_count="$(wc -l < "$tmp_remote" | tr -d ' ')"

echo "Referenced keys in CSV: $referenced_count"
echo "Remote keys in S3: $remote_count"

# Orphans = remote - referenced (both inputs are sorted).
comm -23 "$tmp_remote" "$tmp_referenced" > "$tmp_orphans"
orphans_count="$(wc -l < "$tmp_orphans" | tr -d ' ')"

if [[ "$orphans_count" -eq 0 ]]; then
  echo "No orphaned self-hosted files found."
  exit 0
fi

echo
echo "Found $orphans_count orphaned self-hosted file(s):"
while IFS= read -r key; do
  [[ -n "$key" ]] || continue
  echo "ORPHAN s3://$bucket/$key"
done < "$tmp_orphans"

if [[ "$delete_orphans" -eq 1 ]]; then
  echo
  echo "Deleting orphaned self-hosted file(s)..."
  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    orphan_path="s3://$bucket/$key"
    echo "DELETE $orphan_path"
    aws s3 rm "$orphan_path" >/dev/null
  done < "$tmp_orphans"
fi

if [[ "$fail_on_orphans" -eq 1 ]]; then
  exit 2
fi