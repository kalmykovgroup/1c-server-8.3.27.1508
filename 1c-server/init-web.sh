#!/bin/bash
set -e

IB_NAME="${1:-$POSTGRES_DB}" # "1c-database"

# Проверка необходимых переменных окружения 
: "${DOMAIN:?❌ DOMAIN не задан! Проверь переменные окружения.}" # "1c.kalmykov-group.ru"
: "${APACHE_PUBLICATION_CONF_DIR:?❌ APACHE_PUBLICATION_CONF_DIR не задан! Проверь переменные окружения.}" #"/etc/apache2/sites-available"
: "${PATH_TO_1C:?❌ PATH_TO_1C не задан! Проверь переменные окружения.}" #"/opt/1cv8/x86_64/${VERSION}"
: "${IB_NAME:?❌ IB_NAME не задан! Проверь переменные окружения.}"
: "${WS_PUBLIC_DIR:?❌ WS_PUBLIC_DIR не задан! Проверь переменные окружения.}" #"/var/www/ws"


# 🔧 Конфигурация    
  

APACHE_PUBLICATION_CONF_FILE="${IB_NAME}.conf" # 1c-database.conf
WS_PUBLIC_DIR="${WS_PUBLIC_DIR}/${IB_NAME}"  #"/var/www/ws/1c-database"
VRD_FILE="${WS_PUBLIC_DIR}/default.vrd" #"/var/www/ws/1c-database/default.vrd"

echo "DOMAIN: $DOMAIN"
echo "APACHE_PUBLICATION_CONF_DIR: $APACHE_PUBLICATION_CONF_DIR"
echo "PATH_TO_1C: $PATH_TO_1C"
echo "IB_NAME: $IB_NAME"
echo "WS_PUBLIC_DIR: $WS_PUBLIC_DIR"
echo "APACHE_PUBLICATION_CONF_FILE: $APACHE_PUBLICATION_CONF_FILE"
echo "VRD_FILE: $VRD_FILE"


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

# ❗ Если init-ib не завершился — ошибка
STATUS=$(supervisorctl status init-ib | awk '{print $2}')
if [[ "$STATUS" != "EXITED" ]]; then
  echo "❌ init-ib не завершился за отведённое время (статус: $STATUS)" >&2
  exit 1
fi


echo "📦 Публикация ИБ '${IB_NAME}'"
 

# Убедимся, что директория для VRD существует
mkdir -p "$WS_PUBLIC_DIR"

# Создаём VRD 

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

# Генерация Apache-конфига публикации
CONF_PATH="${APACHE_PUBLICATION_CONF_DIR}/${APACHE_PUBLICATION_CONF_FILE}"
if [ ! -f "$CONF_PATH" ]; then
  echo "⚙️ Создание Apache-конфигурации публикации..."
  cat > "$CONF_PATH" <<EOF
LoadModule _1cws_module "${PATH_TO_1C}/wsap24.so"

Alias "/${IB_NAME}" "${WS_PUBLIC_DIR}"
<Directory "${WS_PUBLIC_DIR}">
    AllowOverride All
    Options None
    Require all granted
    SetHandler 1c-application
    ManagedApplicationDescriptor "${VRD_FILE}"
</Directory>
EOF
else
  echo "✅ Apache-конфигурация уже есть — пропускаем."
fi

# Активируем сайт
a2ensite "${APACHE_PUBLICATION_CONF_FILE}" || true
a2dissite 000-default || true
# Проверка конфигурации и перезапуск
apache2ctl configtest
apache2ctl graceful 

echo "✅ Веб-клиент успешно опубликован на /${IB_NAME}"
