#!/bin/bash
set -e

# Уведомление при ошибке
: "${NOTIFY_SH:?❌ NOTIFY_SH не задан!}" 
SCRIPT_NAME="init-cluster.sh (1c-server)"
source ${NOTIFY_SH}
trap 'handle_exit' EXIT

# Проверка переменных окружения
: "${ONEC_VERSION:?❌ ONEC_VERSION не задан! Проверь переменные окружения.}"
: "${DOMAIN:?❌ DOMAIN не задан! Проверь переменные окружения.}"
: "${DATA:?❌ DATA не задано! Проверь переменные окружения.}"
: "${PATH_TO_1C:?❌ PATH_TO_1C не задан! Проверь переменные окружения.}"

RAC_BIN="${PATH_TO_1C}/rac"
RAS_PORT=1545
RMNGR_PORT=1541
EXPECTED_HOSTNAME="$DOMAIN"
MARKER_FILE="${DATA}/cluster-initialized.marker"

echo "📦 Старт инициализации кластера..."

if [ -f "$MARKER_FILE" ]; then
  echo "✅ Кластер уже инициализирован."
  exit 0
fi

# Ждём RAS
echo "⏳ Ожидание доступности RAS (127.0.0.1:$RAS_PORT)..."
for i in {1..30}; do
    if nc -z localhost "$RAS_PORT"; then
        echo "✅ RAS доступен."
        break
    fi
    sleep 1
done

echo "🔍 Получение списка кластеров..."
CLUSTERS=$($RAC_BIN 127.0.0.1 $RAS_PORT cluster list | awk '/cluster/ {print $3}')
CLUSTER_COUNT=$(echo "$CLUSTERS" | wc -w)

if [ "$CLUSTER_COUNT" -eq 0 ]; then 
    LAST_ERROR_MESSAGE="❌ Кластер не найден. Этот скрипт не должен создавать кластер."
    echo "$LAST_ERROR_MESSAGE" >&2
    exit 1
    
elif [ "$CLUSTER_COUNT" -gt 1 ]; then 
    LAST_ERROR_MESSAGE="❌ Обнаружено несколько кластеров. Обновление невозможно."
    echo "$LAST_ERROR_MESSAGE" >&2
    exit 1
fi

CLUSTER_ID="$CLUSTERS"
echo "✅ Найден кластер: $CLUSTER_ID"

echo "🔎 Проверка имени хоста в кластере..."
CLUSTER_HOST=$($RAC_BIN 127.0.0.1 $RAS_PORT cluster info --cluster="$CLUSTER_ID" | awk -F':' '/host/{gsub(/^[ \t]+/, "", $2); print $2}')
echo "ℹ️ Текущий host: '$CLUSTER_HOST'"

if [ "$CLUSTER_HOST" != "$EXPECTED_HOSTNAME" ]; then
    echo "⚠️ Host кластера '$CLUSTER_HOST' отличается от ожидаемого '$EXPECTED_HOSTNAME'"
    echo "🧹 Удаляем старый кластер..."

    $RAC_BIN 127.0.0.1 $RAS_PORT cluster remove --cluster="$CLUSTER_ID"

    echo "🛠️ Создание нового кластера с host='$EXPECTED_HOSTNAME'"

    CMD="$RAC_BIN 127.0.0.1 $RAS_PORT cluster insert --host=\"$EXPECTED_HOSTNAME\" --port=$RMNGR_PORT"
    echo "🔧 Выполняем команду: $CMD"
    eval $CMD

    echo "✅ Кластер пересоздан."
else
    echo "✅ Host совпадает. Обновление не требуется."
fi

touch "$MARKER_FILE"
echo "✅ Инициализация кластера завершена."
