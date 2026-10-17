#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.."
status=0
for t in tests/*.test.sh; do
  echo "$t"
  bash "$t" || status=1
done
[[ $status -eq 0 ]] && echo "Все тесты прошли" || echo "Есть упавшие тесты"
exit $status
