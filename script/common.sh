#!/bin/bash
# Source me!

validate_url() {
  curl --head --silent --fail --location "$1" > /dev/null
}

url_encode() {
  python3 -c "import urllib.parse, sys; print(urllib.parse.quote(urllib.parse.unquote(sys.argv[1]), safe=':/()?&='))" "$1"
}

url_decode() {
  python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.argv[1]))" "$1"
}

has_encoding() {
  case "$1" in
    (*%[0-9A-Fa-f][0-9A-Fa-f]*)
      return 0 ;;
    (*)
      return 1 ;;
  esac
}

html_encode() {
  python3 -c "import html, sys; print(html.escape(sys.argv[1]))" "$1"
}

html_decode() {
  python3 -c "import html, sys; print(html.unescape(sys.argv[1]))" "$1"
}

parse_rfc2822_date() {
  local date_str="$1"
  if date --version >/dev/null 2>&1; then
    # GNU date
    # Normalize GMT to +0000
    date_str="${date_str/GMT/+0000}"
    date -d "$date_str" "+%s" 2>/dev/null || {
      echo "Failed to parse date: $date_str"
      return 1
    }
  else
    # BSD/macOS date
    if date -j -f "%a, %d %b %Y %T %Z" "$date_str" "+%s" 2>/dev/null; then
      return 0
    else
      # Try with numeric offset
      local date_no_tz=$(echo "$date_str" | sed 's/[-+][0-9]\{4\}$//')
      local tz_offset=$(echo "$date_str" | grep -o '[-+][0-9]\{4\}$')
      if [[ -n "$tz_offset" ]]; then
        local hours=${tz_offset:1:2}
        local minutes=${tz_offset:3:2}
        local seconds=$((hours * 3600 + minutes * 60))
        local base_timestamp=$(date -j -f "%a, %d %b %Y %T" "$date_no_tz" "+%s" 2>/dev/null)
        if [[ ${tz_offset:0:1} == "+" ]]; then
          echo $((base_timestamp - seconds))
        else
          echo $((base_timestamp + seconds))
        fi
      else
        echo "Failed to parse date: $date_str"
        return 1
      fi
    fi
  fi
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
    sys.exit(0)  # valid
except Exception:
    sys.exit(1)  # invalid
' "$input"
}

convert_to_s3() {
  local url;
  local clean_url;
  local s3_url;

  url="$1"
  clean_url="${url%%\?*}"
  s3_url=$(echo "$clean_url" | sed -E 's~https://s3[^/]+.amazonaws.com/~s3://~')

  echo "$s3_url"
}