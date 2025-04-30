#!/bin/bash
set -e
whoami
# Проверка переменных окружения
: "${ONEC_PORT_RANGE:?❌ ONEC_PORT_RANGE не задан! Проверь переменные окружения.}"
: "${PATH_TO_1C:?❌ PATH_TO_1C не задан! Проверь переменные окружения.}"
: "${DATA:?❌ DATA не задан! Проверь переменные окружения.}"  #/var/lib/1c-server

echo "✅ ONEC_PORT_RANGE: $ONEC_PORT_RANGE"
echo "✅ PATH_TO_1C: $PATH_TO_1C"
echo "✅ DATA: $DATA"

exec "${PATH_TO_1C}/ragent" \
    -d "$DATA" \
  -port 1540 \
  -regport 1541 \
  -range "$ONEC_PORT_RANGE" 
