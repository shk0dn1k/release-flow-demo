#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
check "перевод"               "70 130" "$(bash src/transfer.sh 100 100 30)"
check "недостаточно средств"  "fail"   "$(bash src/transfer.sh 10 100 30 2>/dev/null || echo fail)"
check "нулевая сумма — отказ" "fail"   "$(bash src/transfer.sh 100 100 0 2>/dev/null || echo fail)"
exit $FAILED
