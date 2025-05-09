#!/bin/bash
whoami

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

# Проверка пароля
if [ ! -s "$VNC_PASSWORD_FILE" ]; then
  echo "❌ Файл VNC_PASSWORD_FILE с паролем пуст или не существует — проверь маунт секрета" >&2
  exit 1
else
  export VNC_PASSWORD=$(cat "$VNC_PASSWORD_FILE")
  echo "🔐 Пароль от vnc успешно загружен из секрета"
fi
 
echo "🧹 Очищаем логи..."
find "$LOG_DIR" -type f -name "*.log" -exec truncate -s 0 {} \;

#-------- vnc ----------------

echo "🔑 Установка пароля VNC..."
VNC_HOME="/home/${ONEC_USER}/.vnc"
mkdir -p "$VNC_HOME"
chown -R ${ONEC_USER}:${ONEC_GROUP} "$VNC_HOME"

# Генерация пароля в файл
runuser -u ${ONEC_USER} -- bash -c "echo -e \"${VNC_PASSWORD}\n${VNC_PASSWORD}\" | vncpasswd -f > ~/.vnc/passwd"
chmod 600 "$VNC_HOME/passwd"
chown ${ONEC_USER}:${ONEC_GROUP} "$VNC_HOME/passwd"

# xstartup
cat <<EOF > "$VNC_HOME/xstartup"
#!/bin/sh
unset SESSION_MANAGER
exec openbox-session
EOF

chmod +x "$VNC_HOME/xstartup"
chown ${ONEC_USER}:${ONEC_GROUP} "$VNC_HOME/xstartup"

# Устраняем предупреждение об отсутствующем .Xauthority
touch "/home/${ONEC_USER}/.Xauthority"
chown ${ONEC_USER}:${ONEC_GROUP} "/home/${ONEC_USER}/.Xauthority"

#-------- end vnc ------------

echo "📄 Генерируем supervisord.conf из шаблона..."
envsubst < /etc/supervisord.template.conf > /etc/supervisord.conf

chown -R ${ONEC_USER}:${ONEC_GROUP} /var/1C/licenses
chmod -R 755 /var/1C/licenses
 
echo "🚀 Запускаем supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
