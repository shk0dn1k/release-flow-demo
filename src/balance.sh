#!/usr/bin/env bash
# Использование: balance.sh <текущий баланс> <изменение>
set -euo pipefail
[[ $# -eq 2 ]] || { echo "использование: balance.sh <баланс> <изменение>" >&2; exit 1; }
current="$1"
delta="$2"
echo $(( current + delta ))
