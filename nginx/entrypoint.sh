#!/bin/sh
 
# Уведомление при ошибке
: "${NOTIFY_SH:?❌ NOTIFY_SH не задан!}" 
SCRIPT_NAME="entrypoint.sh (nginx)"
source ${NOTIFY_SH}
trap 'handle_exit' EXIT

: "${PROXMOX_IP:?❌ PROXMOX_IP не задан! Проверь переменные окружения.}" 
: "${PROXMOX_PORT:?❌ PROXMOX_PORT не задан! Проверь переменные окружения.}"  

: "${IP_VM_1C:?❌ IP_VM_1C не задан! Проверь переменные окружения.}" 
: "${DOMAIN:?❌ DOMAIN не задан! Проверь переменные окружения.}"  
: "${DOMAIN_VNC_SERVER:?❌ DOMAIN_VNC_SERVER не задан! Проверь переменные окружения.}"  
: "${DOMAIN_VNC_HASPD:?❌ DOMAIN_VNC_HASPD не задан! Проверь переменные окружения.}"  

 
echo "🧹 Очищаем логи..."
find "/var/log/nginx/" -type f -name "*.log" -exec truncate -s 0 {} \;

 

echo "📁 Список /etc/nginx/conf.d до генерации:"
ls -l /etc/nginx/conf.d 
 
export PROXMOX_IP
export PROXMOX_PORT

export DOMAIN
export IP_VM_1C

export DOMAIN_VNC_SERVER
export DOMAIN_VNC_HASPD
 

CERT_PATH="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"

CONF_DIR="/etc/nginx/conf.d"
STREAM_DIR="/etc/nginx/stream.d"

TEMPLATES="/etc/nginx/templates"

TEMPLATE_HTTP="$TEMPLATES/default.http.template.conf"
TEMPLATE_HTTPS="$TEMPLATES/http.template.conf"
TEMPLATE_STREAM="$TEMPLATES/stream.template.conf"

TEMPLATE_PROXMOX="$TEMPLATES/proxmox.template.conf"
TEMPLATE_VNC_HASPD="$TEMPLATES/vnc-haspd.template.conf"
TEMPLATE_VNC_SERVER="$TEMPLATES/vnc-server.template.conf"

HTTP_CONF="$CONF_DIR/default.conf"
STREAM_CONF="$STREAM_DIR/stream.conf"

PROXMOX_CONF="$CONF_DIR/proxmox.conf"
VNC_HASPD_CONF="$CONF_DIR/vnc-haspd.conf"
VNC_SERVER_CONF="$CONF_DIR/vnc-server.conf"
 
echo "PROXMOX_IP:  $PROXMOX_IP"
echo "PROXMOX_PORT:  $PROXMOX_PORT" 

echo "IP_VM_1C:  $IP_VM_1C"
echo "DOMAIN:  $DOMAIN" 
echo "DOMAIN_VNC_SERVER:  $DOMAIN_VNC_SERVER" 
echo "DOMAIN_VNC_HASPD:  $DOMAIN_VNC_HASPD" 

echo "🌐 NGINX entrypoint запущен..."

if [ -f "$CERT_PATH" ]; then

  echo "🔒 SSL-сертификат найден, генерируем конфиг с HTTPS..."
  envsubst '${IP_VM_1C} ${DOMAIN}' < "$TEMPLATE_HTTPS" > "$HTTP_CONF"
  envsubst '${IP_VM_1C}' < "$TEMPLATE_STREAM" > "$STREAM_CONF"
  
  envsubst '${PROXMOX_IP} ${PROXMOX_PORT} ${DOMAIN}' < "$TEMPLATE_PROXMOX" > "$PROXMOX_CONF"
  envsubst '${DOMAIN_VNC_HASPD}' < "$TEMPLATE_VNC_HASPD" > "$VNC_HASPD_CONF"
  envsubst '${DOMAIN_VNC_SERVER}' < "$TEMPLATE_VNC_SERVER" > "$VNC_SERVER_CONF"
else
  echo "🌐 SSL ещё нет, запускаемся с HTTP-only..."
  envsubst '${DOMAIN} ${DOMAIN_VNC_SERVER} ${DOMAIN_VNC_HASPD}' < "$TEMPLATE_HTTP" > "$HTTP_CONF"
fi

echo "📁 Список /etc/nginx/conf.d после генерации:"
ls -l /etc/nginx/conf.d
echo "📄 Содержимое default.conf:"
cat /etc/nginx/conf.d/default.conf 

echo "📁 Список /etc/nginx/stream.d после генерации:"
ls -l /etc/nginx/stream.d
echo "📄 Содержимое stream.conf:"
cat /etc/nginx/stream.d/stream.conf 

echo "🚀 Запуск nginx..."
nginx -g "daemon off;"
