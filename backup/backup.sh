#!/bin/bash
set -e

DATE=$(date +'%Y-%m-%d_%H-%M')
BACKUP_DIR="/backup/$DATE"
mkdir -p "$BACKUP_DIR"

# Проверка пароля
if [ ! -s "$POSTGRES_PASSWORD_FILE" ]; then
  echo "❌ Файл POSTGRES_PASSWORD_FILE с паролем пуст или не существует — проверь маунт секрета" >&2
  exit 1
else
  export PGPASSWORD=$(cat "$POSTGRES_PASSWORD_FILE")
  echo "🔐 Пароль от postgres успешно загружен из секрета"
fi

echo "⏸️ Останавливаем 1С сервер..."
docker exec server supervisorctl stop all

echo "📥 PostgreSQL dump..."
pg_dumpall -h "$POSTGRES_HOST" -U "$POSTGRES_USER" > "$BACKUP_DIR/pgsql.sql"

echo "📁 Архивирование..."
tar czf "$BACKUP_DIR/onec_data.tar.gz" "$ONEC_DATA"
tar czf "$BACKUP_DIR/onec_user_home.tar.gz" "$ONEC_DATA_COMMON"
tar czf "$BACKUP_DIR/licenses.tar.gz" "$LICENSES"
tar czf "$BACKUP_DIR/haspd.tar.gz" "$HASPD_DATA"

echo "☁️ Загрузка в Yandex Cloud..."
rclone copy "$BACKUP_DIR" yandex:${BACKUP_CLOUD_DIR}/

echo "🧹 Удаление локальных бэкапов (оставить 3)..."
ls -1dt /backup/* | tail -n +4 | xargs -d '\n' rm -rf

echo "🧹 Удаление старых облачных бэкапов (оставить 3)..."
rclone lsf yandex:${BACKUP_CLOUD_DIR}/ --dirs-only | sort -r | tail -n +4 | while read OLD; do
  echo "⛔ Удаляю $OLD из облака..."
  rclone purge "yandex:${BACKUP_CLOUD_DIR}/$OLD"
done

docker exec server supervisorctl start all

echo "✅ Backup готов: $BACKUP_DIR"
