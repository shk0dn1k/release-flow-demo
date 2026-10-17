#!/usr/bin/env bash
source "$(dirname "$0")/lib.sh"
check "пополнение" "150" "$(bash src/balance.sh 100 50)"
check "списание"   "70"  "$(bash src/balance.sh 100 -30)"
exit $FAILED
