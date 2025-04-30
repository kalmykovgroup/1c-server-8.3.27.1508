#!/bin/bash

export USER=root  # 🛠 Обязательный фикс

# Удалим возможные остатки
vncserver -kill :1 > /dev/null 2>&1 || true
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1

# Запускаем VNC
echo "🚀 Запускаем VNC-сервер..."
if ! vncserver :1 -geometry 1280x800 -depth 24; then
  echo "❌ Ошибка запуска VNC-сервера. Лог:"
  cat /root/.vnc/*.log
  exit 1
fi

# Живой вывод лога
tail -F /root/.vnc/*:1.log
