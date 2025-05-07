#!/bin/bash
whoami

# Используем переменные окружения или значения по умолчанию
# Проверка переменных окружения
: "${LOG_DIR:?❌ LOG_DIR не задан! Проверь переменные окружения.}"
: "${ONEC_USER:?❌ ONEC_USER не задан! Проверь переменные окружения.}"
: "${ONEC_GROUP:?❌ ONEC_GROUP не задано! Проверь переменные окружения.}"
: "${PATH_TO_1C:?❌ PATH_TO_1C не задан! Проверь переменные окружения.}"

PWFILE=/run/secrets/pass_pgsql
 
# прочитать пароль из секрета
if [ -f $PWFILE ]; then
  export POSTGRES_PASSWORD="$(<"$PWFILE")"
else
  echo "⚠️ Секрет /run/secrets/pass_pgsql не найден" >&2
fi
 
rm $PWFILE  
 
echo "🧹 Очищаем логи..."
find "$LOG_DIR" -type f -name "*.log" -exec truncate -s 0 {} \;

#-------- vnc ----------------

echo "🔑 Установка пароля VNC..."
VNC_HOME="/home/${ONEC_USER}/.vnc"
mkdir -p "$VNC_HOME"
chown -R ${ONEC_USER}:${ONEC_GROUP} "$VNC_HOME"

runuser -u ${ONEC_USER} -- bash -c "vncpasswd -f <<< 'VKKg2259\nVKKg2259' > ~/.vnc/passwd"
chmod 600 "$VNC_HOME/passwd"

cat <<EOF > "$VNC_HOME/xstartup"
#!/bin/sh
unset SESSION_MANAGER
exec openbox-session
EOF

chmod +x "$VNC_HOME/xstartup"
chown ${ONEC_USER}:${ONEC_GROUP} "$VNC_HOME/xstartup"

#Устраняем предупреждение "/usr/bin/xauth:  file /home/usr1cv8/.Xauthority does not exist" 
touch /home/${ONEC_USER}/.Xauthority
chown ${ONEC_USER}:${ONEC_GROUP} /home/${ONEC_USER}/.Xauthority

#-------- end vnc ------------

echo "📄 Генерируем supervisord.conf из шаблона..."
envsubst < /etc/supervisord.template.conf > /etc/supervisord.conf

chown -R ${ONEC_USER}:${ONEC_GROUP} /var/1C/licenses
chmod -R 755 /var/1C/licenses
 
echo "🚀 Запускаем supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
