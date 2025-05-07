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
if [ -z "$POSTGRES_PASSWORD" ]; then echo "❌ Не указано POSTGRES_PASSWORD" >&2; exit 1; fi
if [ -z "$POSTGRES_DB" ]; then echo "❌ Не указано POSTGRES_DB" >&2; exit 1; fi
 
echo "🚀 Запуск и инициализация PostgreSQL..."

        # Запускаем временный сервер для первоначальной настройки
        echo "Запуск временного сервера..."
          su - postgres -c "$PG_BIN/pg_ctl -D '$DATA_DIR' -o \"
            -c listen_addresses='localhost' \
            -c config_file='$CONF_DIR/postgresql.conf' \
            -c data_directory='$DATA_DIR' \
            -c hba_file='$CONF_DIR/pg_hba.conf' \
            -c ident_file='$CONF_DIR/pg_ident.conf' \
            -c unix_socket_directories='$SOCKET_DIR'
          \" -w start"
  echo "📦 Кластер не         # Запускаем временный сервер для первоначальной настройки
        echo "Запуск временного сервера..."
          su - postgres -c "$PG_BIN/pg_ctl -D '$DATA_DIR' -o \"
            -c listen_addresses='localhost' \
            -c config_file='$CONF_DIR/postgresql.conf' \
            -c data_directory='$DATA_DIR' \
            -c hba_file='$CONF_DIR/pg_hba.conf' \
            -c ident_file='$CONF_DIR/pg_ident.conf' \
            -c unix_socket_directories='$SOCKET_DIR'
          \" -w start"найден, создаём..."
  pg_createcluster 16 main

  echo "▶️ Временный запуск PostgreSQL..."
  pg_ctlcluster 16 main start
  sleep 3

  echo "👤 Создание пользователя $POSTGRES_USER..."
  psql -U postgres -tc "SELECT 1 FROM pg_roles WHERE rolname='$POSTGRES_USER'" | grep -q 1 || \
  psql -U postgres -c "CREATE USER $POSTGRES_USER WITH ENCRYPTED PASSWORD '$POSTGRES_PASSWORD';"

  echo "⛔ Остановка временного PostgreSQL..."
  pg_ctlcluster 16 main stop
fi

echo "▶️ Запуск PostgreSQL от пользователя postgres..."
exec su - postgres -c "$PG_BIN/postgres -D $DATA_DIR -c config_file=$CONF_DIR/postgresql.conf -k $SOCKET_DIR"

        # Запускаем временный сервер для первоначальной настройки
        echo "Запуск временного сервера..."
          su - postgres -c "$PG_BIN/pg_ctl -D '$DATA_DIR' -o \"
            -c listen_addresses='localhost' \
            -c config_file='$CONF_DIR/postgresql.conf' \
            -c data_directory='$DATA_DIR' \
            -c hba_file='$CONF_DIR/pg_hba.conf' \
            -c ident_file='$CONF_DIR/pg_ident.conf' \
            -c unix_socket_directories='$SOCKET_DIR'
          \" -w start"        # Запускаем временный сервер для первоначальной настройки
        echo "Запуск временного сервера..."
          su - postgres -c "$PG_BIN/pg_ctl -D '$DATA_DIR' -o \"
            -c listen_addresses='localhost' \
            -c config_file='$CONF_DIR/postgresql.conf' \
            -c data_directory='$DATA_DIR' \
            -c hba_file='$CONF_DIR/pg_hba.conf' \
            -c ident_file='$CONF_DIR/pg_ident.conf' \
            -c unix_socket_directories='$SOCKET_DIR'
          \" -w start"
        # Запускаем временный сервер для первоначальной настройки
        echo "Запуск временного сервера..."
          su - postgres -c "$PG_BIN/pg_ctl -D '$DATA_DIR' -o \"
            -c listen_addresses='localhost' \
            -c config_file='$CONF_DIR/postgresql.conf' \
            -c data_directory='$DATA_DIR' \
            -c hba_file='$CONF_DIR/pg_hba.conf' \
            -c ident_file='$CONF_DIR/pg_ident.conf' \
            -c unix_socket_directories='$SOCKET_DIR'
          \" -w start"
