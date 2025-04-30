#!/bin/sh

: "${DOMAIN_NAME:?❌ DOMAIN_NAME не задан! Проверь переменные окружения.}" 
: "${IP_VM_1C:?❌ IP_VM_1C не задан! Проверь переменные окружения.}" 

echo "DOMAIN_NAME: $DOMAIN_NAME" 
echo "IP_VM_1C: $IP_VM_1C" 

export DOMAIN_NAME
export IP_VM_1C

CONF_DIR="/etc/nginx/conf.d"
STREAM_DIR="/etc/nginx/stream.d"

TEMPLATE_HTTP="/etc/nginx/templates/http.template" 
TEMPLATE_STREAM="/etc/nginx/templates/stream.template" 

TARGET_CONF="$CONF_DIR/default.conf"
TARGET_STREAM="$STREAM_DIR/stream.conf"

echo "🌐 NGINX entrypoint запущен..."

envsubst '${DOMAIN_NAME} ${IP_VM_1C}' < "$TEMPLATE_HTTP" > "$TARGET_CONF"
envsubst '${DOMAIN_NAME} ${IP_VM_1C}' < "$TEMPLATE_STREAM" > "$TARGET_STREAM"

echo "📁 Список /etc/nginx/conf.d после генерации:"
ls -l /etc/nginx/conf.d
echo "📄 Содержимое default.conf:"
cat /etc/nginx/conf.d/default.conf

echo "📁 Список /etc/nginx/stream.d после генерации:"
ls -l /etc/nginx/stream.d
echo "📄 Содержимое stream.conf:"
cat /etc/nginx/stream.d/stream.conf

ls -l /docker-entrypoint.d

echo "🚀 Запуск nginx..."
nginx -g "daemon off;"
