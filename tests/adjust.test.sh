#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
check "корректировка с причиной" "90" "$(bash src/adjust.sh 100 -10 'ошибка оператора')"
check "без причины — отказ" "fail" "$(bash src/adjust.sh 100 -10 '' 2>/dev/null || echo fail)"
exit $FAILED
