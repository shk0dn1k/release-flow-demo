#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
check "5% на 1000"                     "1050" "$(bash src/interest.sh 1000 5)"
check "округление вниз"                "101"  "$(bash src/interest.sh 101 1)"
check "на отрицательный не начисляем"  "-50"  "$(bash src/interest.sh -50 5)"
exit $FAILED
