#!/bin/bash
# Source me!

url_encode() {
  python3 -c "import urllib.parse, sys; print(urllib.parse.quote(urllib.parse.unquote(sys.argv[1]), safe=':/()'))" "$1"
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