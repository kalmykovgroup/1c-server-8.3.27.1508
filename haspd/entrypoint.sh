#!/bin/bash

echo "🧹 Очищаем логи..."
find "$LOG_DIR" -type f -name "*.log" -exec truncate -s 0 {} \;

# Проверка переменных окружения
: "${LOG_DIR:?❌ LOG_DIR не задан! Проверь переменные окружения.}"

# Проверка пароля
if [ ! -s "$VNC_PASSWORD_FILE" ]; then
  echo "❌ Файл VNC_PASSWORD_FILE с паролем пуст или не существует — проверь маунт секрета" >&2
  exit 1
else
  export VNC_PASSWORD=$(cat "$VNC_PASSWORD_FILE")
  echo "🔐 Пароль от vnc успешно загружен из секрета"
fi
 
echo "🧹 Очищаем логи и временные файлы..."
find "$LOG_DIR" -type f -name "*.log" -exec truncate -s 0 {} \;
rm -rf /tmp/.X* /tmp/.X11-unix /root/.vnc/*.pid

echo "🔑 Установка пароля VNC..."
mkdir -p /root/.vnc
printf "%s\n%s\n" "$VNC_PASSWORD" "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd

cat <<EOF > /root/.vnc/xstartup
#!/bin/sh
unset SESSION_MANAGER
exec /bin/sh /etc/xdg/xfce4/xinitrc
EOF
chmod +x /root/.vnc/xstartup

echo "📄 Генерируем supervisord.conf..."
envsubst < /etc/supervisord.template.conf > /etc/supervisord.conf

echo "🚀 Запускаем supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
