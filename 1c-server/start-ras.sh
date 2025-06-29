#!/bin/bash
set -e

# Уведомление при ошибке
: "${NOTIFY_SH:?❌ NOTIFY_SH не задан!}" 
SCRIPT_NAME="start-ras.sh (1c-server)"
source ${NOTIFY_SH}
trap 'handle_exit' EXIT

# Проверка необходимых переменных
: "${PATH_TO_1C:?❌ PATH_TO_1C не задан! Проверь переменные окружения.}"

echo "⏳ Ожидаем доступности rmngr на порту 1541..."
until nc -z localhost 1541; do
  sleep 1
done

echo "🚀 Запуск ras..."
exec "${PATH_TO_1C}/ras" cluster --port=1545 --monitor-port=1555
