#!/usr/bin/env bash
set -euo pipefail

# Уведомление при ошибке
: "${NOTIFY_SH:?❌ NOTIFY_SH не задан!}" 
SCRIPT_NAME="entrypoint.sh (1c-server)"
source ${NOTIFY_SH}
trap 'handle_exit' EXIT
 
: "${DOMAIN:?❌ DOMAIN не задан!}" 
: "${DOMAIN_VNC_SERVER:?❌ DOMAIN_VNC_SERVER не задан!}" 
: "${DOMAIN_VNC_HASPD:?❌ DOMAIN_VNC_HASPD не задан!}" 
: "${CERTBOT_EMAIL:?❌ CERTBOT_EMAIL не задан!}" 
: "${CLOUD_FLARE:?❌ CLOUD_FLARE не задан!}" 

echo "🌐 Certbot entrypoint запущен..." 
echo "🔹 EMAIL: ${CERTBOT_EMAIL}"
echo "🔹 DOMAIN: ${DOMAIN}"

RENEW_CRON="/etc/cron.d/certbot-renew"
 
issue_if_missing() {
  local cert_name="$1"
  local domains=("${@:2}")
  local cert_path="/etc/letsencrypt/live/${cert_name}/fullchain.pem"

  if [[ -f "$cert_path" ]]; then
    echo "✅ Сертификат для ${cert_name} уже существует — пропускаем"
    return
  fi

  echo "🔐 Выпуск сертификата для ${cert_name}:"
  for d in "${domains[@]}"; do echo "   - $d"; done

  set +e
  output=$(certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials "$CLOUD_FLARE" \
    --dns-cloudflare-propagation-seconds 30 \
    --cert-name "$cert_name" \
    "${domains[@]/#/-d }" \
    --agree-tos \
    --email "$CERTBOT_EMAIL" \
    --non-interactive 2>&1)
  status=$?
  set -e

  if [[ $status -ne 0 ]]; then
    if echo "$output" | grep -q "too many certificates"; then 
      LAST_ERROR_MESSAGE="⛔ Превышен лимит Let's Encrypt на выпуск для ${cert_name} \n $output" | grep -oE "retry after .*"
      echo "$LAST_ERROR_MESSAGE" >&2
      exit 1
    else
      LAST_ERROR_MESSAGE="❌ Ошибка при выпуске сертификата для ${cert_name}: \n $output"
      echo "$LAST_ERROR_MESSAGE" >&2
      exit 1 
    fi
  else
    echo "✅ Сертификат успешно выпущен для ${cert_name}"
  fi
}


# --- Выпуск всех нужных сертификатов --- 
issue_if_missing "${DOMAIN}" "${DOMAIN}"        # 1c.kalmykov.group
issue_if_missing "${DOMAIN_VNC_SERVER}" "${DOMAIN_VNC_SERVER}"        # 1c.kalmykov.group
issue_if_missing "${DOMAIN_VNC_HASPD}" "${DOMAIN_VNC_HASPD}"        # 1c.kalmykov.group

echo "🔁 Проверка продления сертификатов при запуске..." 
if ! certbot renew \
  --quiet \
  --dns-cloudflare \
  --dns-cloudflare-credentials "$CLOUD_FLARE" \
  --post-hook 'docker exec nginx nginx -s reload' \
  >> /var/log/certbot-renew.log 2>&1; then
  LAST_ERROR_MESSAGE="❌ Ошибка продления сертификата при запуске certbot"
  return 1
fi

# --- Cron для продления ---
cat <<EOF > "$RENEW_CRON"
0 3 * * * root bash -c '
  source /opt/scripts/utils.sh
  certbot renew \
    --quiet \
    --dns-cloudflare \
    --dns-cloudflare-credentials $CLOUD_FLARE \
    --post-hook "docker exec nginx nginx -s reload" \
    >> /var/log/certbot-renew.log 2>&1 || notify "❌ Ошибка продления сертификата в certbot (cron)"
'
EOF

chmod 0644 "$RENEW_CRON"
echo "🗓  Cron‑задача для продления создана: $RENEW_CRON"

echo "🚀 Запуск cron (foreground)..."
cron -f

