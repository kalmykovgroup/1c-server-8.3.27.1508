#!/bin/bash
set -e

DATE=$(date +'%Y-%m-%d_%H-%M')
BACKUP_DIR="/backup/$DATE"
mkdir -p "$BACKUP_DIR"

echo "📥 PostgreSQL dump..."
pg_dumpall -U "$POSTGRES_USER" > "$BACKUP_DIR/pgsql.sql"

echo "📁 Архивирование..."
tar czf "$BACKUP_DIR/onec_data.tar.gz" "$ONEC_DATA"
tar czf "$BACKUP_DIR/onec_user_home.tar.gz" "$ONEC_DATA_COMMON"
tar czf "$BACKUP_DIR/licenses.tar.gz" "$LICENSES"
tar czf "$BACKUP_DIR/haspd.tar.gz" "$HASPD_DATA"

echo "☁️ Загрузка в Yandex Cloud..."
rclone copy "$BACKUP_DIR" yandex:kalmykov-group.ru/volnaya-28/backup/

echo "🧹 Удаление старых бэкапов в облаке..."
rclone delete --min-age 7d yandex:kalmykov-group.ru/volnaya-28/backup/

echo "✅ Backup готов: $BACKUP_DIR"
