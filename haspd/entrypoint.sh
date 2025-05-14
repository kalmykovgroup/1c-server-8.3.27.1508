#!/bin/bash
set -e

: "${NOTIFY_SH:?❌ NOTIFY_SH не задан!}" 
SCRIPT_NAME="entrypoint.sh (haspd)"
source ${NOTIFY_SH}
trap 'handle_exit' EXIT

echo "🧹 Очищаем логи и временные файлы..."
find "$LOG_DIR" -type f -name "*.log" -exec truncate -s 0 {} \; 

: "${RDP_USER:?❌ RDP_USER не задан!}" 

# Проверка пароля
if [ ! -s "$RDP_PASSWORD_FILE" ]; then 
  LAST_ERROR_MESSAGE="❌ Файл RDP_PASSWORD_FILE с паролем пуст или не существует — проверь маунт секрета"
  echo "$LAST_ERROR_MESSAGE" >&2
  exit 1
else
  export RDP_PASSWORD=$(cat "$RDP_PASSWORD_FILE")
  echo "🔐 Пароль от vnc успешно загружен из секрета"
fi

echo "👤 Создаём пользователя '$RDP_USER'"
if ! id "$RDP_USER" &>/dev/null; then
  useradd -m -s /bin/bash "$RDP_USER"
  echo "$RDP_USER:$RDP_PASSWORD" | chpasswd
  usermod -aG sudo "$RDP_USER"
  echo "startxfce4" > /home/$RDP_USER/.xsession
  chown $RDP_USER:$RDP_USER /home/$RDP_USER/.xsession

echo "👤 Настраиваем окружение пользователя '$RDP_USER'..."

USER_HOME="/home/$RDP_USER"

# Создание домашней директории
mkdir -p "$USER_HOME"
chown "$RDP_USER:$RDP_USER" "$USER_HOME"

# Создание .xsession
echo "startxfce4" > "$USER_HOME/.xsession"
chmod +x "$USER_HOME/.xsession"
chown "$RDP_USER:$RDP_USER" "$USER_HOME/.xsession"

# Создание .Xauthority
su - "$RDP_USER" -c "touch ~/.Xauthority"
chown "$RDP_USER:$RDP_USER" "$USER_HOME/.Xauthority"

# Добавление пользователя в группы
usermod -aG audio,video "$RDP_USER"

mkdir -p /home/ivan/Desktop

cat > /home/ivan/Desktop/hasp.desktop <<EOF
[Desktop Entry]
Version=1.0
Name=HASP Admin Control Center
Comment=Открыть http://localhost:1947
Exec=firefox http://localhost:1947
Icon=firefox
Terminal=false
Type=Application
Categories=Network;WebBrowser;
EOF

chmod +x /home/ivan/Desktop/hasp.desktop
chown ivan:ivan /home/ivan/Desktop/hasp.desktop

echo "✅ Окружение настроено."

fi

: "${LOG_DIR:?❌ LOG_DIR не задан! Проверь переменные окружения.}" 

rm -f /var/run/xrdp/xrdp-sesman.pid
 
# Генерация supervisord.conf
echo "📄 Генерация supervisord.conf..."
envsubst < /etc/supervisord.template.conf > /etc/supervisord.conf

# Запуск supervisord
echo "🚀 Запуск supervisord..."
exec /usr/bin/supervisord -c /etc/supervisord.conf
