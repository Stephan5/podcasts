#!/bin/bash
set -euo pipefail

# Paths
SCRIPT="$(dirname "$0")/../script/csv2rss.sh"
INPUT="$(dirname "$0")/../feed/test/csv2rss.csv"
EXPECTED_OUTPUT="$(dirname "$0")/expected/csv2rss.xml"
ACTUAL_OUTPUT="$(dirname "$0")/../feed/test/csv2rss.xml"

# Clean up output on exit
trap 'rm -f "$ACTUAL_OUTPUT"' EXIT

# Clean up any existing output
rm -f "$ACTUAL_OUTPUT"

# Run your script (customize flags as needed)
"$SCRIPT" "$INPUT" --delimiter $'\x1F' \
                   --title "Dudes Rock" \
                   --description "Hell yeah dude!" \
                   --author "Real-ass dudes" \
                   --image-url "https://link.com/image.jpg"

echo
echo

# Extract and check <lastBuildDate>
last_build_date=$(grep -m1 '<lastBuildDate>' "$ACTUAL_OUTPUT" | sed -E 's/.*<lastBuildDate>(.*)<\/lastBuildDate>.*/\1/')
if [[ ! "$last_build_date" =~ ^[A-Z][a-z]{2},\ [0-9]{2}\ [A-Z][a-z]{2}\ [0-9]{4}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\ [+-][0-9]{4}$ ]]; then
  echo "❌ TEST FAIL: <lastBuildDate> is missing or malformed: $last_build_date"
  exit 1
fi

# Extract and check channel-level <pubDate>
channel_pub_date=$(grep -m1 '<pubDate>' "$ACTUAL_OUTPUT" | sed -E 's/.*<pubDate>(.*)<\/pubDate>.*/\1/')
if [[ ! "$channel_pub_date" =~ ^[A-Z][a-z]{2},\ [0-9]{2}\ [A-Z][a-z]{2}\ [0-9]{4}\ [0-9]{2}:[0-9]{2}:[0-9]{2}\ [+-][0-9]{4}$ ]]; then
  echo "❌ TEST FAIL: channel <pubDate> is missing or malformed: $channel_pub_date"
  exit 1
fi

# Compare output
if diff -u \
     <(awk '/<lastBuildDate>/ {next} /<pubDate>/ && !seen++ {next} 1' "$EXPECTED_OUTPUT") \
     <(awk '/<lastBuildDate>/ {next} /<pubDate>/ && !seen++ {next} 1' "$ACTUAL_OUTPUT"); then
  echo "✅ TEST PASS: Output matches expected."
else
  echo "❌ TEST FAIL: Output does not match expected."
  exit 1
fi
