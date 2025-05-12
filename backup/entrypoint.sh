#!/bin/bash
set -e


: "${BACKUP_SCHEDULE:?❌ BACKUP_SCHEDULE не задан! Проверь переменные окружения.}" 
: "${BACKUP_CLOUD_DIR:?❌ BACKUP_CLOUD_DIR не задан! Проверь переменные окружения.}" 
: "${POSTGRES_USER:?❌ POSTGRES_USER не задан! Проверь переменные окружения.}"  
: "${POSTGRES_HOST:?❌ POSTGRES_HOST не задан! Проверь переменные окружения.}"  
: "${ONEC_DATA:?❌ ONEC_DATA не задан! Проверь переменные окружения.}"  
: "${PG_DATA_DIR:?❌ PG_DATA_DIR не задан! Проверь переменные окружения.}"  
: "${ONEC_DATA_COMMON:?❌ ONEC_DATA_COMMON не задан! Проверь переменные окружения.}"  
: "${HASPD_DATA:?❌ HASPD_DATA не задан! Проверь переменные окружения.}"  
: "${LICENSES:?❌ LICENSES не задан! Проверь переменные окружения.}"  
: "${TEMPLATES:?❌ TEMPLATES не задан! Проверь переменные окружения.}"
     

 
if [ ! -s "$RCLONE_CONFIG_FILE" ]; then
  echo "❌ Файл RCLONE_CONFIG_FILE с паролем пуст или не существует — проверь маунт секрета" >&2
  exit 1
else
  # Подключение rclone config
  echo "📂 Подключение rclone.conf"
  mkdir -p /root/.config/rclone
  cp "$RCLONE_CONFIG_FILE" /root/.config/rclone/rclone.conf
fi
  

echo "📦 Настройка cron по расписанию: $BACKUP_SCHEDULE"
 
# Подставим расписание
sed "s|{{BACKUP_SCHEDULE}}|${BACKUP_SCHEDULE:-0 3 * * *}|" /${TEMPLATES}/crontab.template > /etc/cron.d/backup
chmod 0644 /etc/cron.d/backup
crontab /etc/cron.d/backup

touch /var/log/1c_backup.log

echo "🚀 Запуск cron..."
cron -f
