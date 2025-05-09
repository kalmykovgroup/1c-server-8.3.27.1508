FROM nginx:latest
 

# Установим утилиты для отладки и envsubst (он уже есть в base Alpine образе, но добавим netcat)
RUN apt update && \
    apt install -y net-tools telnet netcat-openbsd gettext-base && \
    rm -rf /var/lib/apt/lists/*

# Копируем скрипт запуска
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Установим entrypoint
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
