#!/bin/bash
set -e

# Уведомление при ошибке
: "${NOTIFY_SH:?❌ NOTIFY_SH не задан!}" 
SCRIPT_NAME="entrypoint.sh (1c-server)"
source ${NOTIFY_SH}
trap 'handle_exit' EXIT
 
 
echo "🧹 Очищаем логи и временные файлы..."
find "$LOG_DIR" -type f -name "*.log" -exec truncate -s 0 {} \;
rm -rf /tmp/.X* /tmp/.X11-unix /root/.vnc/*.pid

# Используем переменные окружения или значения по умолчанию
# Проверка переменных окружения
: "${LOG_DIR:?❌ LOG_DIR не задан! Проверь переменные окружения.}" 
: "${PATH_TO_1C:?❌ PATH_TO_1C не задан! Проверь переменные окружения.}"

# Проверка пароля
if [ ! -s "$POSTGRES_PASSWORD_FILE" ]; then 
  LAST_ERROR_MESSAGE="❌ Файл POSTGRES_PASSWORD_FILE с паролем пуст или не существует — проверь маунт секрета"
  echo "$LAST_ERROR_MESSAGE" >&2
  exit 1
else
  export POSTGRES_PASSWORD=$(cat "$POSTGRES_PASSWORD_FILE")
  echo "🔐 Пароль от postgres успешно загружен из секрета"
fi



echo "📄 Генерируем supervisord.conf из шаблона..."
envsubst < /etc/supervisord.template.conf > /etc/supervisord.conf

echo "🚀 Запускаем supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
