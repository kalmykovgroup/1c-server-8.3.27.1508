FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client tar gzip cron 

# Установка docker-cli
RUN apt-get update && apt-get install -y --no-install-recommends docker.io

# Установка rclone из локального установщика
COPY installer/rclone-v1.69.2-linux-amd64/rclone /usr/bin/rclone
RUN chmod 755 /usr/bin/rclone

COPY backup.sh /backup.sh
COPY entrypoint.sh /entrypoint.sh
COPY /templates/crontab.template /crontab.template

RUN chmod +x /backup.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
