#!/bin/bash
set -euo pipefail

# Create a temporary directory for test files
TEST_DIR=$(mktemp -d)

# Paths
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../script" && pwd)/pubdate.sh"
INPUT="$TEST_DIR/test.csv"

# Clean up output on exit
trap 'rm -rf "$TEST_DIR"' EXIT

# Create a sample CSV input
cat > "$INPUT" <<EOF
title;description;date;url
Episode 1;Desc 1;Jun 1, 2023;http://example.com/1
Episode 2;Desc 2;Jul 2, 2023;http://example.com/2
Episode 3;Desc 3;Jul. 3, 2023;http://example.com/3
EOF

# Run pubdate.sh with custom input format and delimiter
"$SCRIPT" "$INPUT" --input-format "%b %d, %Y" --delimiter ";"

# Check output
if grep -q "Thu, 01 Jun 2023 03:00:00 GMT" "$INPUT" && \
   grep -q "Sun, 02 Jul 2023 03:00:00 GMT" "$INPUT" && \
   grep -q "Mon, 03 Jul 2023 03:00:00 GMT" "$INPUT"; then
  echo "✅ TEST PASS: Output matches expected."
else
  echo "❌ TEST FAIL: Output does not match expected."
  exit 1
fi