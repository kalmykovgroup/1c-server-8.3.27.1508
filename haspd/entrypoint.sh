#!/bin/bash
set -e

echo "🧹 Очищаем логи и временные файлы..."
find "$LOG_DIR" -type f -name "*.log" -exec truncate -s 0 {} \;
rm -rf /tmp/.X* /tmp/.X11-unix /root/.vnc/*.pid

: "${LOG_DIR:?❌ LOG_DIR не задан! Проверь переменные окружения.}"
 
# Проверка и загрузка VNC-пароля
if [ ! -s "$VNC_PASSWORD_FILE" ]; then
  echo "❌ Файл VNC_PASSWORD_FILE пуст или не существует — проверь маунт секрета" >&2
  exit 1
else
  export VNC_PASSWORD=$(cat "$VNC_PASSWORD_FILE")
  echo "🔐 Пароль от VNC успешно загружен из секрета"
fi

# Создание файла xstartup
echo "⚙️ Настройка xstartup..."
cat <<EOF > /root/.vnc/xstartup
#!/bin/sh
export DISPLAY=:1
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec startxfce4
EOF
chmod +x /root/.vnc/xstartup

# Генерация supervisord.conf
echo "📄 Генерация supervisord.conf..."
envsubst < /etc/supervisord.template.conf > /etc/supervisord.conf

# Запуск supervisord
echo "🚀 Запуск supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
