#!/bin/bash
set -e
whoami
# Проверка необходимых переменных окружения
: "${ONEC_VERSION:?❌ ONEC_VERSION не задан! Проверь переменные окружения.}"
: "${DOMAIN:?❌ DOMAIN не задан! Проверь переменные окружения.}"
: "${DATA:?❌ DATA не задан! Проверь переменные окружения.}"
: "${PATH_TO_1C:?❌ PATH_TO_1C не задан! Проверь переменные окружения.}"

MARKER_FILE="${DATA}/initialized.marker"
RAS_PORT=1545
RAC_BIN="${PATH_TO_1C}/rac"
SERVER_NAME="$DOMAIN"

if [ -f "$MARKER_FILE" ]; then
    echo "✅ Кластер уже инициализирован. Пропускаем."
    exit 0
fi

echo "⏳ Ожидаем доступность RAS..."
until nc -z localhost 1541 && nc -z localhost "$RAS_PORT"; do
    sleep 1
done

echo "🔍 Получаем ID кластера..."
CLUSTER_ID=$("$RAC_BIN" 127.0.0.1 "$RAS_PORT" cluster list | awk '/cluster/{print $3}')
if [ -z "$CLUSTER_ID" ]; then
    echo "❌ Кластер не найден!" >&2
    exit 1
fi

echo "✅ Кластер найден: $CLUSTER_ID"

# Проверим, зарегистрирован ли сервер
echo "🔍 Проверка регистрации сервера..."
if ! "$RAC_BIN" 127.0.0.1 "$RAS_PORT" server list --cluster="$CLUSTER_ID" | grep -q "$SERVER_NAME"; then
    echo "📌 Регистрируем сервер '$SERVER_NAME' в кластере..."
    "$RAC_BIN" 127.0.0.1 "$RAS_PORT" server register \
        --cluster="$CLUSTER_ID" \
        --name="$SERVER_NAME" \
        --host="$SERVER_NAME"
else
    echo "✅ Сервер '$SERVER_NAME' уже зарегистрирован."
fi

touch "$MARKER_FILE"
echo "✅ Инициализация завершена."
