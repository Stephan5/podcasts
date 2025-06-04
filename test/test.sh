#!/bin/bash
set -Eeuo pipefail

cd "$(dirname "$0")"

status=0

for test in *.test.sh; do
  if [ -x "$test" ]; then
     echo
     echo
     echo "========== Running $test =========="
     echo
    ./"$test" || status=1
  else
    echo "Skipping $test (not executable)"
  fi
done

exit $status