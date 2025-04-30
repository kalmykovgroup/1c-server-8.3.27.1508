#!/bin/bash
set -e

echo "DEBUG: Запуск entrypoint.sh"
 
export LANG=ru_RU.UTF-8

export LC_ALL=ru_RU.UTF-8
 

# Переменные окружения
ADMIN_USER="${POSTGRES_USER}"            # суперпользователь
ADMIN_PASS="${POSTGRES_PASSWORD}"        # пароль суперпользователя

TARGET_USER="${POSTGRES_USER_1C}"        # пользователь для 1С
TARGET_PASS="${POSTGRES_USER_PASSWORD_1C}"
TARGET_DB="${POSTGRES_DB}"
 
# Проверяем, хотим ли мы запустить PostgreSQL
if [ "$1" = "postgres" ]; then
  
    # Проверка обязательных переменных
    if [ -z "$PG_BIN" ]; then echo "❌ Не указано PG_BIN" >&2; exit 1; fi           # Путь к бинарникам PostgreSQL "/usr/pgsql-17/bin"  
    if [ -z "$CONF_DIR" ]; then echo "❌ Не указано CONF_DIR" >&2; exit 1; fi       # Путь к каталогу конфигурации "/etc/postgresql/pgsql-17/main"
    if [ -z "$DATA_DIR" ]; then echo "❌ Не указано DATA_DIR" >&2; exit 1; fi       # Путь к каталогу данных "/var/lib/postgresql/pgsql-17/main"  
    if [ -z "$SOCKET_DIR" ]; then echo "❌ Не указано SOCKET_DIR" >&2; exit 1; fi   #socket "/var/run/postgresql"
    if [ -z "$ADMIN_USER" ]; then echo "❌ Не указано ADMIN_USER" >&2; exit 1; fi   #postgres
    if [ -z "$ADMIN_PASS" ]; then echo "❌ Не указано ADMIN_PASS" >&2; exit 1; fi   #******
    if [ -z "$TARGET_USER" ]; then echo "❌ Не указано TARGET_USER" >&2; exit 1; fi #1c-user
    if [ -z "$TARGET_PASS" ]; then echo "❌ Не указано TARGET_PASS" >&2; exit 1; fi #******
    if [ -z "$TARGET_DB" ]; then echo "❌ Не указано TARGET_DB" >&2; exit 1; fi     #1c-database 

    echo "Начало запуска pgsql"

    # Если каталог данных не инициализирован, инициализируем
    if [ ! -d "$DATA_DIR" ] || [ -z "$(ls -A "$DATA_DIR" 2>/dev/null)" ]; then
        echo "Инициализация базы данных..."
        mkdir -p "$DATA_DIR"
        chown -R postgres:postgres /var/lib/postgresql

        # Инициализация кластера initdb
        su - postgres -c "$PG_BIN/initdb --locale=ru_RU.UTF-8 --encoding=UTF8 -D '$DATA_DIR'"

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


        # Устанавливаем пароль суперпользователю
        psql -v ON_ERROR_STOP=1 -U postgres <<-EOSQL
            ALTER USER "$ADMIN_USER" WITH PASSWORD '$ADMIN_PASS';
EOSQL

   echo "👤 Создание пользователя $TARGET_USER с правами для работы 1С..."
   
psql -v ON_ERROR_STOP=1 -U "$ADMIN_USER" <<-EOSQL
DO \$\$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_catalog.pg_roles WHERE rolname = '$TARGET_USER'
    ) THEN
        CREATE ROLE "$TARGET_USER" 
            WITH LOGIN
            SUPERUSER
            PASSWORD '$TARGET_PASS';
    END IF;
END
\$\$;

-- На всякий случай назначаем SUPERUSER, если пользователь уже был создан ранее
ALTER ROLE "$TARGET_USER" SUPERUSER;
EOSQL

 
        # Остановка временного сервера
        echo "Остановка временного сервера..."
        su - postgres -c "$PG_BIN/pg_ctl -D '$DATA_DIR' -m fast -w stop"
    fi

    echo "Запуск PostgreSQL..."
   exec su - postgres -c "
     $PG_BIN/postgres \
       -D '$DATA_DIR' \
       -c config_file='$CONF_DIR/postgresql.conf' \
       -c data_directory='$DATA_DIR' \
       -c hba_file='$CONF_DIR/pg_hba.conf' \
       -c ident_file='$CONF_DIR/pg_ident.conf' \
       -c unix_socket_directories='$SOCKET_DIR'
   "
else 
  echo "Выход без инициализации"
fi

 

# Если передана другая команда — выполняем её напрямую
exec "$@"
