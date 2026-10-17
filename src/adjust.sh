#!/usr/bin/env bash
# Использование: adjust.sh <баланс> <изменение> <причина>
set -euo pipefail
[[ $# -eq 3 && -n "$3" ]] || { echo "нужна причина" >&2; exit 1; }
bash "$(dirname "$0")/balance.sh" "$1" "$2"
