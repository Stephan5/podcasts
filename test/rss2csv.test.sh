#!/bin/bash
set -euo pipefail

# Paths
SCRIPT="$(dirname "$0")/../script/rss2csv.sh"
INPUT="$(dirname "$0")/../feed/test/rss2csv.xml"
EXPECTED_OUTPUT="$(dirname "$0")/expected-rss2csv.csv"
ACTUAL_OUTPUT="$(dirname "$0")/../feed/test/rss2csv.csv"

# Clean up output on exit
#trap 'rm -f "$ACTUAL_OUTPUT"' EXIT

# Clean up any existing output
rm -f "$ACTUAL_OUTPUT"

# Run your script (customize flags as needed)
"$SCRIPT" "$INPUT" --delimiter $'\x1F' \
                   --repo-dir "test"

echo
echo

# Compare output
if diff -u "$EXPECTED_OUTPUT" "$ACTUAL_OUTPUT"; then
  echo "✅ TEST PASS: Output matches expected."
else
  echo "❌ TEST FAIL: Output does not match expected."
  exit 1
fi
