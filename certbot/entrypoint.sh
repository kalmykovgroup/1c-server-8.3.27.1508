#!/usr/bin/env bash
set -euo pipefail

# Уведомление при ошибке
: "${NOTIFY_SH:?❌ NOTIFY_SH не задан!}" 
SCRIPT_NAME="entrypoint.sh (1c-server)"
source "${NOTIFY_SH}"
trap 'handle_exit' EXIT

# Переменные окружения
: "${DOMAIN:?❌ DOMAIN не задан!}" 
: "${DOMAIN_RDP_SERVER:?❌ DOMAIN_RDP_SERVER не задан!}" 
: "${DOMAIN_RDP_HASPD:?❌ DOMAIN_RDP_HASPD не задан!}" 
: "${CERTBOT_EMAIL:?❌ CERTBOT_EMAIL не задан!}" 
: "${CLOUD_FLARE:?❌ CLOUD_FLARE не задан!}" 

echo "🌐 Certbot entrypoint запущен..." 
echo "🔹 EMAIL: ${CERTBOT_EMAIL}"
echo "🔹 DOMAIN: ${DOMAIN}"

RENEW_CRON="/etc/cron.d/certbot-renew"

# --- Проверка срока действия ---
is_cert_valid() {
  local cert_name="$1"
  local cert_file="/etc/letsencrypt/live/${cert_name}/cert.pem"

  if [[ ! -f "$cert_file" ]]; then
    return 1
  fi

  local end_date
  end_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
  local end_ts
  end_ts=$(date -d "$end_date" +%s || return 1)
  local now_ts
  now_ts=$(date +%s)
  local diff_days=$(( (end_ts - now_ts) / 86400 ))

  if [[ $diff_days -lt 7 ]]; then
    echo "⚠️  Сертификат ${cert_name} истекает через ${diff_days} дней — перевыпускаем"
    return 1
  fi

  echo "✅ Сертификат ${cert_name} действителен ещё ${diff_days} дней"
  return 0
}

# --- Выпуск при отсутствии или истечении ---
issue_if_missing_or_expired() {
  local cert_name="$1"
  local domains=("${@:2}")

  if is_cert_valid "$cert_name"; then
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
      LAST_ERROR_MESSAGE="⛔ Превышен лимит Let's Encrypt на выпуск для ${cert_name}\n$output"
      echo "$LAST_ERROR_MESSAGE" >&2
      exit 1
    else
      LAST_ERROR_MESSAGE="❌ Ошибка при выпуске сертификата для ${cert_name}:\n$output"
      echo "$LAST_ERROR_MESSAGE" >&2
      exit 1 
    fi
  else
    echo "✅ Сертификат успешно выпущен для ${cert_name}"
  fi
}

# --- Выпуск всех нужных сертификатов --- 
issue_if_missing_or_expired "${DOMAIN}" "${DOMAIN}"
issue_if_missing_or_expired "${DOMAIN_RDP_SERVER}" "${DOMAIN_RDP_SERVER}"
issue_if_missing_or_expired "${DOMAIN_RDP_HASPD}" "${DOMAIN_RDP_HASPD}"

# --- Ручной запуск renew ---
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
