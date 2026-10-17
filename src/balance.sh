#!/usr/bin/env bash
# Использование: balance.sh <текущий баланс> <изменение>
set -euo pipefail
current="$1"
delta="$2"
echo $(( current + delta ))
