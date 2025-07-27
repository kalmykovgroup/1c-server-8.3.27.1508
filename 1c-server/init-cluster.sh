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
MARKER_FILE="${DATA}/full-initialized.marker"

echo "📦 Старт инициализации кластера..."

# Проверка существующего marker-файла
if [ -f "$MARKER_FILE" ]; then
  echo "✅ Marker файл найден: $MARKER_FILE"
  SAVED_HOST=$(grep '^HOSTNAME=' "$MARKER_FILE" | cut -d'=' -f2)
  if [ "$SAVED_HOST" == "$DOMAIN" ]; then
      echo "✅ Хост совпадает, пересоздание кластера не требуется."
      exit 0
  else
      echo "⚠️ Хост в marker не совпадает! Был: $SAVED_HOST, сейчас: $DOMAIN"
      echo "🧹 Удаляем старый кластер..."
  fi
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

if [ "$CLUSTER_HOST" != "$DOMAIN" ]; then
    echo "⚠️ Host кластера '$CLUSTER_HOST' отличается от ожидаемого '$DOMAIN'"
    echo "🧹 Удаляем старый кластер..."

    $RAC_BIN 127.0.0.1 $RAS_PORT cluster remove --cluster="$CLUSTER_ID"

    echo "🛠️ Создание нового кластера с host='$DOMAIN'"
    $RAC_BIN 127.0.0.1 $RAS_PORT cluster insert --host=$DOMAIN --port=$RMNGR_PORT

    echo "⏳ Ожидание регистрации нового кластера..."
    for i in {1..10}; do
        CLUSTERS=$($RAC_BIN 127.0.0.1 $RAS_PORT cluster list | awk '/cluster/ {print $3}')
        if [ -n "$CLUSTERS" ]; then
            break
        fi
        sleep 1
    done

    CLUSTER_ID="$CLUSTERS"
    echo "✅ Новый кластер зарегистрирован: $CLUSTER_ID"
else
    echo "✅ Host совпадает. Обновление не требуется."
fi

# Записываем новый marker-файл
{
  echo "CLUSTER_ID=${CLUSTER_ID}"
  echo "HOSTNAME=${DOMAIN}"
  echo "TIMESTAMP=$(date -Iseconds)"
} > "$MARKER_FILE"

sync

echo "📄 Содержимое marker-файла:"
cat "$MARKER_FILE"
echo "✅ Marker файл создан: $MARKER_FILE"

echo "✅ Инициализация кластера завершена."
