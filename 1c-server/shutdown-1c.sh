#!/bin/bash
set -e

# Уведомление при ошибке
: "${NOTIFY_SH:?❌ NOTIFY_SH не задан!}" 
SCRIPT_NAME="shutdown.sh (1c-server)"
source ${NOTIFY_SH}
trap 'handle_exit' EXIT

LOG="${OG_DIR}/1c-shutdown.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] 🛑 Остановка служб 1С через supervisor..." >> "$LOG"

supervisorctl stop all >> "$LOG" 2>&1

echo "[$DATE] ✅ Все службы 1С остановлены" >> "$LOG"
