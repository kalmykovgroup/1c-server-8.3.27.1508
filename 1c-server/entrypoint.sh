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

# Проверка переменных окружения
: "${LOG_DIR:?❌ LOG_DIR не задан! Проверь переменные окружения.}" 
: "${PATH_TO_1C:?❌ PATH_TO_1C не задан! Проверь переменные окружения.}"
: "${RDP_USER:?❌ RDP_USER не задан!}"

USER_HOME="/home/$RDP_USER"

# Проверка паролей
if [ ! -s "$POSTGRES_PASSWORD_FILE" ]; then 
  LAST_ERROR_MESSAGE="❌ Файл POSTGRES_PASSWORD_FILE с паролем пуст или не существует — проверь маунт секрета"
  echo "$LAST_ERROR_MESSAGE" >&2
  exit 1
else
  export POSTGRES_PASSWORD=$(cat "$POSTGRES_PASSWORD_FILE")
  echo "🔐 Пароль от postgres успешно загружен из секрета"
fi

if [ ! -s "$RDP_PASSWORD_FILE" ]; then 
  LAST_ERROR_MESSAGE="❌ Файл RDP_PASSWORD_FILE с паролем пуст или не существует — проверь маунт секрета"
  echo "$LAST_ERROR_MESSAGE" >&2
  exit 1
else
  export RDP_PASSWORD=$(cat "$RDP_PASSWORD_FILE")
  echo "🔐 Пароль от vnc успешно загружен из секрета"
fi

# --- Создание пользователя RDP ---
echo "👤 Создаём пользователя '$RDP_USER'" 
if ! id "$RDP_USER" &>/dev/null; then
  useradd -m -s /bin/bash "$RDP_USER"
  echo "$RDP_USER:$RDP_PASSWORD" | chpasswd
  usermod -aG sudo "$RDP_USER"
fi

echo "👤 Настраиваем окружение пользователя '$RDP_USER'..."

mkdir -p "$USER_HOME"
chown "$RDP_USER:$RDP_USER" "$USER_HOME"

# xhost в .xprofile (работает в RDP-сессии)
echo 'xhost +SI:localuser:root' > "$USER_HOME/.xprofile"
chown "$RDP_USER:$RDP_USER" "$USER_HOME/.xprofile"

# Создаём папку для скриптов, если её нет
mkdir -p "$USER_HOME/bin"
chown $RDP_USER:$RDP_USER "$USER_HOME/bin"

# Скрипт для запуска 1С
cat > "$USER_HOME/bin/run-1c.sh" <<EOF
#!/bin/bash
xhost +SI:localuser:root
sudo DISPLAY=\$DISPLAY XAUTHORITY=\$XAUTHORITY /opt/1cv8/x86_64/8.3.27.1508/1cv8c
EOF

chmod +x "$USER_HOME/bin/run-1c.sh"
chown $RDP_USER:$RDP_USER "$USER_HOME/bin/run-1c.sh"

mkdir -p "$USER_HOME/Desktop"

cat > "$USER_HOME/Desktop/1C-ThinClient.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=1C:Enterprise (root)
Exec=$USER_HOME/bin/run-1c.sh
Icon=1cv8
Terminal=false
Categories=Office;
EOF

chmod +x "$USER_HOME/Desktop/1C-ThinClient.desktop"
chown $RDP_USER:$RDP_USER "$USER_HOME/Desktop/1C-ThinClient.desktop" 

# Разрешаем запуск без пароля
echo "$RDP_USER ALL=(ALL) NOPASSWD: /opt/1cv8/x86_64/8.3.27.1508/1cv8c" > /etc/sudoers.d/1c-thinclient
chmod 440 /etc/sudoers.d/1c-thinclient

# Удаляем PID-файл XRDP (на случай падения)
rm -f /var/run/xrdp/xrdp-sesman.pid

#chown -R usr1cv8:grp1cv8 ${DATA} ${LOG_DIR} ${CACHE} ${LICENSES}

# --- Supervisor ---
echo "📄 Генерируем supervisord.conf из шаблона..."
envsubst < /etc/supervisord.template.conf > /etc/supervisord.conf

#cat /etc/supervisord.conf
 
exec /usr/bin/supervisord -c /etc/supervisord.conf
