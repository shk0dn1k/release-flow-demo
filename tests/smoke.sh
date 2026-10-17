#!/usr/bin/env bash
# Smoke-проверка «работающей системы» после деплоя
set -euo pipefail
cd "$(dirname "$0")/.."
echo "Версия: $(cat version.txt)"
[[ "$(bash src/balance.sh 1 1)" == "2" ]] && echo "Smoke OK"
