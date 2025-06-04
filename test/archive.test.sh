#!/bin/bash
set -euo pipefail

cleanup() {
  rm -rf "$INPUT_DIR"
  rm -rf "$OUTPUT_DIR"
  rm -rf "$TEST_DIR"
}

# Given

# Create a temporary directory for test files
INPUT_DIR=$(mktemp -d)
OUTPUT_DIR=$(mktemp -d)
TEST_DIR=$(mktemp -d)

# Clean up on exit
trap cleanup EXIT

# Paths
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../script" && pwd)/archive.sh"

EXPECTED="$TEST_DIR/expected.csv"

TEST_SRC_URL_1="https://freetestdata.com/wp-content/uploads/2021/09/Free_Test_Data_100KB_MP3.mp3"
TEST_SRC_URL_2="https://freetestdata.com/wp-content/uploads/2021/09/Free_Test_Data_100KB_OGG.ogg"

# Create a sample CSV input
cat > "$INPUT_DIR/feed.csv" <<EOF
title;description;date;url
Episode 1;Desc 1;Jun 1, 2023;$TEST_SRC_URL_1
Episode 2;Desc 2;Jul 2, 2023;$TEST_SRC_URL_2
EOF

echo "foo" > "$INPUT_DIR/foo.txt"

cat > "$EXPECTED" <<EOF
title;description;date;url
Episode 1;Desc 1;Jun 1, 2023;file://items/Free_Test_Data_100KB_MP3.mp3
Episode 2;Desc 2;Jul 2, 2023;file://items/Free_Test_Data_100KB_OGG.ogg
EOF

# When
"$SCRIPT" "$INPUT_DIR" "$OUTPUT_DIR" --delimiter ";"

# Then
OUTPUT_FEED="$OUTPUT_DIR/$(basename "$INPUT_DIR")"

# Check MP3 file
MP3_FILE="$OUTPUT_FEED/items/Free_Test_Data_100KB_MP3.mp3"
if [[ ! -f "$MP3_FILE" ]]; then
  echo "❌ TEST FAIL: MP3 file not found at $MP3_FILE"
  exit 1
fi

# Check OGG file
OGG_FILE="$OUTPUT_FEED/items/Free_Test_Data_100KB_OGG.ogg"
if [[ ! -f "$OGG_FILE" ]]; then
  echo "❌ TEST FAIL: OGG file not found at $OGG_FILE"
  exit 1
fi

# Check file sizes (approximately 100KB)
MP3_SIZE=$(stat -f%z "$MP3_FILE" 2>/dev/null || stat -c%s "$MP3_FILE")
if [[ "$MP3_SIZE" -lt 100000 || "$MP3_SIZE" -gt 105000 ]]; then
  echo "❌ TEST FAIL: MP3 file size unexpected: $MP3_SIZE bytes (expected ~100KB)"
  exit 1
fi

OGG_SIZE=$(stat -f%z "$OGG_FILE" 2>/dev/null || stat -c%s "$OGG_FILE")
if [[ "$OGG_SIZE" -lt 100000 || "$OGG_SIZE" -gt 105000 ]]; then
  echo "❌ TEST FAIL: OGG file size unexpected: $OGG_SIZE bytes (expected ~100KB)"
  exit 1
fi

# Check if foo.txt was copied correctly
FOO_FILE="$OUTPUT_FEED/foo.txt"
if [[ ! -f "$FOO_FILE" ]]; then
  echo "❌ TEST FAIL: foo.txt not found at $FOO_FILE"
  exit 1
fi

# Check the content of foo.txt
if [[ "$(cat "$FOO_FILE")" != "foo" ]]; then
  echo "❌ TEST FAIL: foo.txt content doesn't match expected. Found: $(cat "$FOO_FILE")"
  exit 1
fi

if ! diff -u "$EXPECTED" <(cat "$OUTPUT_FEED/local.csv"); then
  echo "❌ TEST FAIL: Output does not match expected."
  exit 1
fi

echo "✅ TEST PASS."