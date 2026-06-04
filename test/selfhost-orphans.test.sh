#!/bin/bash
set -Eeuo pipefail

cleanup() {
  aws s3 rm "s3://$BUCKET$BUCKET_PREFIX/$(basename "$TEST_DIR")/" --recursive || true
  rm -rf "$TEST_DIR"
}

TEST_DIR=$(mktemp -d)
trap cleanup EXIT

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../script" && pwd)/selfhost-orphans.sh"
INPUT="$TEST_DIR/feed.csv"

if [[ -n "${AWS_ENDPOINT_URL:-}" ]]; then
  BUCKET="test-bucket"
else
  BUCKET="test.blakeslee.uk"
fi

BUCKET_PREFIX="/rss"
REPO_DIR="$(basename "$TEST_DIR")"
ROOT="s3://$BUCKET$BUCKET_PREFIX/$REPO_DIR"

OBJ_1="$ROOT/1-episode-1.mp3"
OBJ_2="$ROOT/2-episode-2.mp3"
OBJ_3="$ROOT/3-orphan.mp3"

URL_1="https://s3.eu-west-2.amazonaws.com/$BUCKET$BUCKET_PREFIX/$REPO_DIR/1-episode-1.mp3"
URL_2="https://s3.eu-west-2.amazonaws.com/$BUCKET$BUCKET_PREFIX/$REPO_DIR/2-episode-2.mp3"

# Seed remote objects
aws s3 cp "resources/test.mp3" "$OBJ_1" >/dev/null
aws s3 cp "resources/test.mp3" "$OBJ_2" >/dev/null
aws s3 cp "resources/test.mp3" "$OBJ_3" >/dev/null

# CSV references only first two files
cat > "$INPUT" <<EOF
title;description;date;url
Episode 1;Desc 1;Jun 1, 2023;$URL_1
Episode 2;Desc 2;Jul 2, 2023;$URL_2
EOF

OUTPUT="$("$SCRIPT" "$INPUT" --delimiter ";" --bucket "$BUCKET" --prefix "$BUCKET_PREFIX")"

echo "$OUTPUT"

if grep -q "ORPHAN s3://$BUCKET$BUCKET_PREFIX/$REPO_DIR/3-orphan.mp3" <<< "$OUTPUT"; then
  echo "✅ TEST PASS: orphan detected."
else
  echo "❌ TEST FAIL: expected orphan not detected."
  exit 1
fi

if grep -q "1-episode-1.mp3" <<< "$OUTPUT" || grep -q "2-episode-2.mp3" <<< "$OUTPUT"; then
  echo "❌ TEST FAIL: referenced files were incorrectly flagged."
  exit 1
fi

DELETE_OUTPUT="$("$SCRIPT" "$INPUT" --delimiter ";" --bucket "$BUCKET" --prefix "$BUCKET_PREFIX" --delete-orphans)"

echo "$DELETE_OUTPUT"

if grep -q "DELETE s3://$BUCKET$BUCKET_PREFIX/$REPO_DIR/3-orphan.mp3" <<< "$DELETE_OUTPUT"; then
  echo "✅ TEST PASS: orphan deleted."
else
  echo "❌ TEST FAIL: expected orphan delete output not found."
  exit 1
fi

POST_DELETE_OUTPUT="$("$SCRIPT" "$INPUT" --delimiter ";" --bucket "$BUCKET" --prefix "$BUCKET_PREFIX")"

echo "$POST_DELETE_OUTPUT"

if grep -q "No orphaned self-hosted files found." <<< "$POST_DELETE_OUTPUT"; then
  echo "✅ TEST PASS: no orphans remain after delete."
else
  echo "❌ TEST FAIL: orphan still present after delete."
  exit 1
fi
