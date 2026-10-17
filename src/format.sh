#!/usr/bin/env bash
# Использование: format.sh <сумма в рублях>
# Выводит сумму с разделителем тысяч: 1234567 → «1 234 567 ₽»
set -euo pipefail
[[ $# -eq 1 && "$1" =~ ^-?[0-9]+$ ]] || { echo "использование: format.sh <целая сумма>" >&2; exit 1; }
sign="" n="$1"
[[ "$n" == -* ]] && { sign="-"; n="${n#-}"; }
out=""
while (( ${#n} > 3 )); do out=" ${n: -3}$out"; n="${n:0:${#n}-3}"; done
echo "$sign$n$out ₽"
