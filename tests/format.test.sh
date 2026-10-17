#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
check "меньше тысячи"   "999 ₽"         "$(bash src/format.sh 999)"
check "миллион"         "1 234 567 ₽"   "$(bash src/format.sh 1234567)"
check "отрицательная"   "-12 000 ₽"     "$(bash src/format.sh -12000)"
check "не число — отказ" "fail"         "$(bash src/format.sh abc 2>/dev/null || echo fail)"
exit $FAILED
