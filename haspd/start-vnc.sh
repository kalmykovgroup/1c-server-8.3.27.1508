#!/bin/bash
set -e

export USER=root

# Проверка переменной с паролем
if [ -z "$VNC_PASSWORD" ]; then
  echo "❌ Переменная VNC_PASSWORD не установлена!" >&2
  exit 1
fi

# Удаляем старую сессию, если есть
vncserver -kill :1 > /dev/null 2>&1 || true
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1 /root/.vnc/*.pid

# Генерация пароля через tigervncpasswd
mkdir -p /root/.vnc
echo "$VNC_PASSWORD" | tigervncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd

# Запуск VNC
echo "🚀 Запускаем VNC-сервер..."
vncserver :1 -geometry 1280x800 -depth 24 -localhost no

# Живой лог
tail -F /root/.vnc/*:1.log
