FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client curl unzip tar gzip cron \
 && curl -Of https://downloads.rclone.org/rclone-current-linux-amd64.zip \
 && unzip rclone-current-linux-amd64.zip \
 && cd rclone-*-linux-amd64 && cp rclone /usr/bin/ && chmod 755 /usr/bin/rclone && cd .. \
 && rm -rf rclone*

COPY backup.sh /backup.sh
COPY entrypoint.sh /entrypoint.sh 

RUN chmod +x /backup.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
