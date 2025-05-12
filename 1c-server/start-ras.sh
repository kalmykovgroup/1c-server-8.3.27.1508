#!/bin/bash
set -e

echo "⏳ Ожидаем доступности rmngr на 1541..."
until nc -z localhost 1541; do
  sleep 1
done

echo "🚀 Запуск ras..."
exec ${PATH_TO_1C}/ras cluster --port=1545 --monitor-port=1555
