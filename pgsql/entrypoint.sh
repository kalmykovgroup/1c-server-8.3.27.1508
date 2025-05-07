#!/bin/bash
set -e
echo "DEBUG: Запуск entrypoint.sh"

export LANG=ru_RU.UTF-8
export LC_ALL=ru_RU.UTF-8
 
# Проверка обязательных переменных
if [ -z "$PG_BIN" ]; then echo "❌ Не указано PG_BIN" >&2; exit 1; fi
if [ -z "$CONF_DIR" ]; then echo "❌ Не указано CONF_DIR" >&2; exit 1; fi
if [ -z "$DATA_DIR" ]; then echo "❌ Не указано DATA_DIR" >&2; exit 1; fi
if [ -z "$SOCKET_DIR" ]; then echo "❌ Не указано SOCKET_DIR" >&2; exit 1; fi
if [ -z "$POSTGRES_USER" ]; then echo "❌ Не указано POSTGRES_USER" >&2; exit 1; fi 
if [ -z "$POSTGRES_DB" ]; then echo "❌ Не указано POSTGRES_DB" >&2; exit 1; fi
 
 
 # pwfile всегда /tmp/pwfile, монтируется из секрета
 PWFILE=/run/secrets/pass_pgsql
 if [ ! -s "$PWFILE" ]; then
   echo "❌ Файл /tmp/pwfile пуст или не существует — проверь маунт секрета" >&2
   exit 1
 fi
 


if [ ! -d "$DATA_DIR" ] || [ -z "$(ls -A "$DATA_DIR" 2>/dev/null)" ]; then
  echo "📦 Создаем кластер initdb..."
  mkdir -p "$DATA_DIR"
  chown -R postgres:postgres "$DATA_DIR"

  su - postgres -c "$PG_BIN/initdb \
    --locale=ru_RU.UTF-8 \
    --encoding=UTF8 \
    --pwfile=$PWFILE \
    -D '$DATA_DIR'"
else
  echo "📦 Кластер уже инициализирован, пропускаем initdb."
fi

rm $PWFILE 

echo "▶️ Запуск PostgreSQL..."
exec su - postgres -c "\
  $PG_BIN/postgres \
    -D '$DATA_DIR' \
    -c config_file='$CONF_DIR/postgresql.conf' \
    -c hba_file='$CONF_DIR/pg_hba.conf' \
    -c unix_socket_directories='$SOCKET_DIR'"
