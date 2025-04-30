#!/bin/bash

# Проверка переменных окружения
: "${LOG_DIR:?❌ LOG_DIR не задан! Проверь переменные окружения.}"

echo "🧹 Очищаем логи и временные файлы..."
find "$LOG_DIR" -type f -name "*.log" -exec truncate -s 0 {} \;
rm -rf /tmp/.X* /tmp/.X11-unix /root/.vnc/*.pid

echo "🔑 Установка пароля VNC..."
mkdir -p /root/.vnc
vncpasswd -f <<< "VKKg2259"$'\nVKKg2259' > /root/.vnc/passwd
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
