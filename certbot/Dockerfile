﻿# Базовый образ с Ubuntu 22.04
FROM ubuntu:22.04

# 1. Пакеты: certbot CLI, cron, docker‑cli (для post‑hook), pip
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        certbot python3-pip cron docker.io && \
    pip3 install --no-cache-dir certbot-dns-cloudflare && \
    rm -rf /var/lib/apt/lists/*
 
# 3. Entrypoint‑скрипт
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
