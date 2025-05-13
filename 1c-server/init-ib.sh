#!/bin/bash
set -e

# Уведомление при ошибке
: "${NOTIFY_SH:?❌ NOTIFY_SH не задан!}" 
SCRIPT_NAME="init-ib.sh (1c-server)"
source ${NOTIFY_SH}
trap 'handle_exit' EXIT

# Проверка доступности psql
for i in {1..60}; do
    if command -v psql >/dev/null; then
        echo "✅ psql найден"
        break
    else
        echo "⏳ Ожидание появления psql... попытка $i"
        sleep 1
    fi
done

if ! command -v psql >/dev/null; then 
    LAST_ERROR_MESSAGE="❌ psql не найден даже после ожидания"
    echo "$LAST_ERROR_MESSAGE" >&2
    exit 1
fi

# 📦 Пути
: "${PATH_TO_1C:?❌ Не задан PATH_TO_1C}"
RAC_BIN="${PATH_TO_1C}/rac"

# 📋 Аргументы и ENV
IB_NAME="${1:-$POSTGRES_DB}"
DB_HOST="${POSTGRES_HOST}"

# 🔐 Обязательные переменные
: "${POSTGRES_USER:?❌ Не указано имя пользователя Postgres}"
: "${POSTGRES_PASSWORD:?❌ Не указан пароль пользователя Postgres}"
: "${IB_NAME:?❌ Не указано имя информационной базы}"
: "${DB_HOST:?❌ Не указан хост базы данных}" 

echo "ℹ️ Имя базы данных:        $IB_NAME"
echo "ℹ️ Пользователь Postgres:  $POSTGRES_USER"
echo "ℹ️ Хост PostgreSQL:        $DB_HOST"

# 🕓 Ожидание RAS
RAC_HOST="127.0.0.1"
RAC_PORT="1545"
echo "⏳ Ожидание запуска RAS на $RAC_HOST:$RAC_PORT..."

CLUSTER_ID=""
for i in {1..60}; do
    if "$RAC_BIN" "$RAC_HOST" "$RAC_PORT" cluster list &>/dev/null; then
        CLUSTER_ID=$("$RAC_BIN" "$RAC_HOST" "$RAC_PORT" cluster list | awk '/cluster/{print $3}')
        [ -n "$CLUSTER_ID" ] && break
    fi
    echo "🔄 Попытка $i/60: кластер не найден, ожидание..."
    sleep 1
done

[ -z "$CLUSTER_ID" ] && {
      LAST_ERROR_MESSAGE="❌ Кластер не найден"
      echo "$LAST_ERROR_MESSAGE" >&2
      exit 1 
  }
echo "✅ Кластер найден: $CLUSTER_ID"
 
# Проверка публикации через rac 
IB_EXIST=$(
  "$RAC_BIN" "$RAC_HOST" "$RAC_PORT" infobase summary list --cluster="$CLUSTER_ID" | \
  awk -v name="$IB_NAME" '
    $1 == "infobase" { uuid = $3 }
    $1 == "name" && $3 == name { found = 1 }
    found && $1 == "name" && $3 == name { print uuid; exit }
  '
)

if [ -n "$IB_EXIST" ]; then
    echo "ℹ️ Публикация для '$IB_NAME' уже существует по данным RAS. Пропускаем."
    exit 0
fi


# 🚀 Создание новой ИБ
echo "🚀 Создание новой ИБ '$IB_NAME'..."
timeout 180 "$RAC_BIN" "$RAC_HOST" "$RAC_PORT" infobase create \
  --cluster="$CLUSTER_ID" \
  --create-database \
  --name="$IB_NAME" \
  --dbms=PostgreSQL \
  --db-server="$DB_HOST" \
  --db-name="$IB_NAME" \
  --db-user="$POSTGRES_USER" \
  --db-pwd="$POSTGRES_PASSWORD" \
  --locale=ru

# ✅ Проверка физического создания
echo "✅ Проверяем физическое наличие ИБ '$IB_NAME' в PostgreSQL..."
if PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$DB_HOST" -U "$POSTGRES_USER" -d postgres -tAc \
  "SELECT 1 FROM pg_database WHERE datname = '$IB_NAME'" | grep -q 1; then
    echo "✅ Физическая база '$IB_NAME' найдена в PostgreSQL."
else 
    LAST_ERROR_MESSAGE="❌ База '$IB_NAME' НЕ была создана в PostgreSQL!"
    echo "$LAST_ERROR_MESSAGE" >&2
    exit 1
fi

# 📦 Получение UUID
get_ib_uuid() {
    "$RAC_BIN" "$RAC_HOST" "$RAC_PORT" infobase summary list --cluster="$CLUSTER_ID" | \
    awk -v name="$IB_NAME" '$1=="infobase"{uuid=$3} $1=="name" && $3==name {print uuid; exit}'
}

IB_UUID=$(get_ib_uuid)
[ -z "$IB_UUID" ] && {  
  LAST_ERROR_MESSAGE="❌ Не удалось получить UUID для '$IB_NAME'"
  echo "$LAST_ERROR_MESSAGE" >&2
  exit 1
}

# 📢 Публикация ИБ
echo "📢 Публикация ИБ '$IB_NAME'..."
"$RAC_BIN" "$RAC_HOST" "$RAC_PORT" infobase update \
    --cluster="$CLUSTER_ID" \
    --infobase="$IB_UUID" \
    --descr="ИБ '$IB_NAME'" \
    --license-distribution=allow \
    --scheduled-jobs-deny=off \
    --sessions-deny=off
 

# 🔍 Проверка параметров публикации
INFO_OUTPUT=$("$RAC_BIN" "$RAC_HOST" "$RAC_PORT" infobase info --cluster="$CLUSTER_ID" --infobase="$IB_UUID")
LICENSE_DIST=$(echo "$INFO_OUTPUT" | awk -F ':' '/license-distribution/{gsub(/^[ \t]+/, "", $2); print $2}')
SESSIONS_DENY=$(echo "$INFO_OUTPUT" | awk -F ':' '/sessions-deny/{gsub(/^[ \t]+/, "", $2); print $2}')
SCHED_JOBS=$(echo "$INFO_OUTPUT" | awk -F ':' '/scheduled-jobs-deny/{gsub(/^[ \t]+/, "", $2); print $2}')

if [[ "$LICENSE_DIST" == "allow" && "$SESSIONS_DENY" == "off" && "$SCHED_JOBS" == "off" ]]; then
    echo "✅ База '$IB_NAME' опубликована и готова к использованию."
else
    echo "⚠️ Параметры публикации отличаются от ожидаемых:"
    echo "license-distribution: $LICENSE_DIST"
    echo "sessions-deny:        $SESSIONS_DENY"
    echo "scheduled-jobs-deny:  $SCHED_JOBS"
fi

