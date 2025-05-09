FROM ubuntu:24.04

RUN apt update && apt install -y \
    novnc \
    websockify \
    python3-websockify \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /opt/novnc
ENTRYPOINT ["/entrypoint.sh"]
