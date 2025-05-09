#!/bin/bash

# Подразумевается, что запускается от ${ONEC_USER}
export USER=${ONEC_USER}
export HOME=/home/${ONEC_USER}

# Удалим возможные остатки
vncserver -kill :1 > /dev/null 2>&1 || true
rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1

# Убедимся, что .vnc директория существует
mkdir -p "$HOME/.vnc"

# Запускаем VNC
echo "🚀 Запускаем VNC-сервер..."
if ! vncserver :1 -geometry 1280x800 -depth 24 -localhost no; then
  echo "❌ Ошибка запуска VNC-сервера. Лог:"
  cat "$HOME/.vnc/"*.log
  exit 1
fi

LOG_FILE="$HOME/.vnc/$(hostname):1.log"

# Ждём, пока лог появится
for i in {1..10}; do
  if [ -f "$LOG_FILE" ]; then
    break
  fi
  echo "⏳ Ожидаем появление лога VNC..."
  sleep 1
done

# Вывод лога
if [ -f "$LOG_FILE" ]; then
  tail -F "$LOG_FILE"
else
  echo "❌ Лог VNC не найден: $LOG_FILE"
  exit 1
fi
