#!/usr/bin/env bash
FAILED=0
check() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    echo "  ok    $name"
  else
    echo "  FAIL  $name: ожидали '$expected', получили '$actual'"
    FAILED=1
  fi
}
