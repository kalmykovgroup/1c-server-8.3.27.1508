#!/bin/bash
set -e

echo "DEBUG: Запуск entrypoint.sh"

export LANG=ru_RU.UTF-8
export LC_ALL=ru_RU.UTF-8

# Проверка обязательных переменных
if [ -z "$POSTGRES_VERSION" ]; then echo "❌ Не указано POSTGRES_VERSION" >&2; exit 1; fi
if [ -z "$POSTGRES_USER" ]; then echo "❌ Не указано POSTGRES_USER" >&2; exit 1; fi
if [ -z "$POSTGRES_DB" ]; then echo "❌ Не указано POSTGRES_DB" >&2; exit 1; fi
if [ -z "$PG_DATA_DIR" ]; then echo "❌ Не указано PG_DATA_DIR" >&2; exit 1; fi
if [ -z "$PG_CONF_DIR" ]; then echo "❌ Не указано PG_CONF_DIR" >&2; exit 1; fi 
 

# Проверка пароля
if [ ! -s "$POSTGRES_PASSWORD_FILE" ]; then
  echo "❌ Файл с паролем пуст или не существует — проверь маунт секрета" >&2
  exit 1
else
  POSTGRES_PASSWORD=$(cat "$POSTGRES_PASSWORD_FILE")
  echo "🔐 Пароль успешно загружен из секрета"
fi
 
 

# Проверка наличия конфигов
if [ ! -f "$PG_CONF_DIR/postgresql.conf" ] || [ ! -f "$PG_CONF_DIR/pg_hba.conf" ]; then
  echo "❌ Конфигурационные файлы PostgreSQL не найдены!"
  exit 1
fi

LOG_DIR="$PG_DATA_DIR/log"

if [ -d "$LOG_DIR" ]; then
  echo "🛠 Установка владельца postgres для log директории..."
  chown -R postgres:postgres "$LOG_DIR"
else
  echo "📁 log директория отсутствует, создаём..."
  mkdir -p "$LOG_DIR"
  chown -R postgres:postgres "$LOG_DIR"
fi

# Убедимся, что прописан data_directory
grep -q "^data_directory" "$PG_CONF_DIR/postgresql.conf" || {
  echo "data_directory = '$PG_DATA_DIR'" >> "$PG_CONF_DIR/postgresql.conf"
  echo "🛠 Прописали data_directory вручную"
}

# Запуск временного кластера
echo "🔁 Запуск кластера для смены пароля..."
pg_ctlcluster "$POSTGRES_VERSION" main start

# Смена пароля
echo "🔧 Изменение пароля пользователя $POSTGRES_USER..."
su - postgres -c "psql -d postgres -c \"ALTER USER \\\"$POSTGRES_USER\\\" WITH PASSWORD '$POSTGRES_PASSWORD';\""


# Остановка
echo "🛑 Остановка кластера..."
pg_ctlcluster "$POSTGRES_VERSION" main stop
 
# Финальный запуск через pg_ctlcluster
echo "▶️ Запуск PostgreSQL сервера через pg_ctlcluster..."
exec pg_ctlcluster "$POSTGRES_VERSION" main start --foreground

