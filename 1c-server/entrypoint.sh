#!/bin/bash
whoami
 
echo "🧹 Очищаем логи и временные файлы..."
find "$LOG_DIR" -type f -name "*.log" -exec truncate -s 0 {} \;
rm -rf /tmp/.X* /tmp/.X11-unix /root/.vnc/*.pid

# Используем переменные окружения или значения по умолчанию
# Проверка переменных окружения
: "${LOG_DIR:?❌ LOG_DIR не задан! Проверь переменные окружения.}"
: "${ONEC_USER:?❌ ONEC_USER не задан! Проверь переменные окружения.}"
: "${ONEC_GROUP:?❌ ONEC_GROUP не задано! Проверь переменные окружения.}"
: "${PATH_TO_1C:?❌ PATH_TO_1C не задан! Проверь переменные окружения.}"

# Проверка пароля
if [ ! -s "$POSTGRES_PASSWORD_FILE" ]; then
  echo "❌ Файл POSTGRES_PASSWORD_FILE с паролем пуст или не существует — проверь маунт секрета" >&2
  exit 1
else
  export POSTGRES_PASSWORD=$(cat "$POSTGRES_PASSWORD_FILE")
  echo "🔐 Пароль от postgres успешно загружен из секрета"
fi

echo "🔧 Устанавливаем права на /var/1C/licenses..."
chown -R ${ONEC_USER}:${ONEC_GROUP} /var/1C/licenses
chmod -R 755 /var/1C/licenses

#-------- vnc ----------------

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

#-------- end vnc ------------

echo "📄 Генерируем supervisord.conf из шаблона..."
envsubst < /etc/supervisord.template.conf > /etc/supervisord.conf

chown -R ${ONEC_USER}:${ONEC_GROUP} /var/1C/licenses
chmod -R 755 /var/1C/licenses
 
echo "🚀 Запускаем supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
