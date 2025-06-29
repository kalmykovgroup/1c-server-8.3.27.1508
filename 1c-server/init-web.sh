#!/bin/bash
set -e

# Уведомление при ошибке
: "${NOTIFY_SH:?❌ NOTIFY_SH не задан!}"
SCRIPT_NAME="init-web.sh (1c-server)"
source ${NOTIFY_SH}
trap 'handle_exit' EXIT

IB_NAME="${1:-$POSTGRES_DB}" # например: "1c-database"

# Проверка переменных окружения
: "${DOMAIN:?❌ DOMAIN не задан! Проверь переменные окружения.}"
: "${APACHE_PUBLICATION_CONF_DIR:?❌ APACHE_PUBLICATION_CONF_DIR не задан!}"
: "${PATH_TO_1C:?❌ PATH_TO_1C не задан!}"
: "${IB_NAME:?❌ IB_NAME не задан!}"
: "${WS_PUBLIC_DIR:?❌ WS_PUBLIC_DIR не задан!}"

APACHE_PUBLICATION_CONF_FILE="${IB_NAME}.conf"
WS_PUBLIC_DIR_FULL="${WS_PUBLIC_DIR}/${IB_NAME}"
VRD_FILE="${WS_PUBLIC_DIR_FULL}/default.vrd"
CONF_PATH="${APACHE_PUBLICATION_CONF_DIR}/${APACHE_PUBLICATION_CONF_FILE}"
MARKER_FILE="${WS_PUBLIC_DIR_FULL}/web-${IB_NAME}.marker"

echo "DOMAIN: $DOMAIN"
echo "APACHE_PUBLICATION_CONF_DIR: $APACHE_PUBLICATION_CONF_DIR"
echo "PATH_TO_1C: $PATH_TO_1C"
echo "IB_NAME: $IB_NAME"
echo "WS_PUBLIC_DIR_FULL: $WS_PUBLIC_DIR_FULL"
echo "APACHE_PUBLICATION_CONF_FILE: $APACHE_PUBLICATION_CONF_FILE"
echo "VRD_FILE: $VRD_FILE"

# Проверка marker
if [ -f "$MARKER_FILE" ]; then
    SAVED_DOMAIN=$(grep '^DOMAIN=' "$MARKER_FILE" | cut -d'=' -f2)
    SAVED_IB_NAME=$(grep '^IB_NAME=' "$MARKER_FILE" | cut -d'=' -f2)
    echo "✅ Marker файл найден: $MARKER_FILE"
    if [ "$SAVED_DOMAIN" == "$DOMAIN" ] && [ "$SAVED_IB_NAME" == "$IB_NAME" ]; then
        echo "✅ DOMAIN и IB_NAME совпадают, пересоздание не требуется."
        exit 0
    else
        echo "⚠️ Значения в marker не совпадают! Пересоздаём VRD и Apache-конфиг..."
        rm -f "$CONF_PATH" "$VRD_FILE" "$MARKER_FILE"
    fi
fi

# ⏳ Ждём завершения init-ib
echo "⏳ Ожидание завершения init-ib..."
for i in {1..60}; do
  STATUS=$(supervisorctl status init-ib | awk '{print $2}')
  echo "🔍 init-ib статус: $STATUS"
  if [[ "$STATUS" == "EXITED" ]]; then
    echo "✅ init-ib завершён."
    break
  fi
  sleep 3
done

STATUS=$(supervisorctl status init-ib | awk '{print $2}')
if [[ "$STATUS" != "EXITED" ]]; then
  LAST_ERROR_MESSAGE="❌ init-ib не завершился за отведённое время (статус: $STATUS)"
  echo "$LAST_ERROR_MESSAGE" >&2
  exit 1
fi

echo "📦 Проверка VRD и Apache-конфига..."

# Создаём директорию для VRD
mkdir -p "$WS_PUBLIC_DIR_FULL"

# Генерация VRD
echo "⚙️ Генерация VRD в $VRD_FILE"
cat > "$VRD_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<point xmlns="http://v8.1c.ru/8.2/virtual-resource-system"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                base="/${IB_NAME}"
                ib="Srvr=${DOMAIN};Ref=${IB_NAME}">
        <ws pointEnableCommon="true"/>
        <standardOdata enable="false"
                        reuseSessions="autouse"
                        sessionMaxAge="20"
                        poolSize="10"
                        poolTimeout="5"/>
        <analytics enable="true"/>
</point>
EOF

# Генерация Apache-конфига
echo "⚙️ Создание Apache-конфигурации в $CONF_PATH"
cat > "$CONF_PATH" <<EOF
LoadModule _1cws_module "${PATH_TO_1C}/wsap24.so"

Alias "/${IB_NAME}" "${WS_PUBLIC_DIR_FULL}"
<Directory "${WS_PUBLIC_DIR_FULL}">
    AllowOverride All
    Options None
    Require all granted
    SetHandler 1c-application
    ManagedApplicationDescriptor "${VRD_FILE}"
</Directory>
EOF

# Активируем сайт
a2ensite "${APACHE_PUBLICATION_CONF_FILE}" || true
a2dissite 000-default || true

# Проверка конфигурации и перезапуск
apache2ctl configtest
apache2ctl graceful

# Запись marker-файла
{
    echo "DOMAIN=${DOMAIN}"
    echo "IB_NAME=${IB_NAME}"
    echo "TIMESTAMP=$(date -Iseconds)"
} > "$MARKER_FILE"
sync

echo "📄 Содержимое marker-файла:"
cat "$MARKER_FILE"
echo "✅ Marker файл создан: $MARKER_FILE"

echo "✅ Веб-клиент успешно опубликован на /${IB_NAME}"
