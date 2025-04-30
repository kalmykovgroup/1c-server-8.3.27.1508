FROM ubuntu:24.04

# Аргументы для путей логов и бинарных файлов
ARG LOG_DIR=/var/log
ARG BIN=/usr/local/bin

# Установка переменных окружения
ENV LOG_DIR=${LOG_DIR}
ENV BIN=${BIN}
ENV DEBIAN_FRONTEND=noninteractive

# Установка базовых зависимостей + VNC
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        gnupg \
        ca-certificates \
        software-properties-common && \
    echo "deb [arch=amd64,i386] http://security.ubuntu.com/ubuntu focal-security main" > /etc/apt/sources.list.d/focal-i386.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3B4FE6ACC0B21F32

# Установка 32-битных зависимостей и GUI
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        # Основные зависимости для HASP
        libc6:i386 \
        libncurses6:i386 \
        libstdc++6:i386 \
        lib32z1 \
        lib32ncurses6 \
        libssl1.1:i386 \
        libusb-0.1-4:i386 \
        # Графическая среда
        tightvncserver \
        xserver-xorg-core \
        xorgxrdp \
        xauth \
        x11-xkb-utils \
        x11-utils \
        x11-apps \
        xdg-utils \
        xfce4 \
        xfce4-goodies \
        xfonts-base \
        dbus-x11 \
        # Системные утилиты
        locales \
        supervisor \
        gettext \
        libudev1 \
        lsb-release \
        usbutils \
        net-tools \
        curl \
        file && \
        # 🚀 Браузер
        apt-get purge -y firefox && \
        add-apt-repository -y ppa:mozillateam/ppa && \
        apt-get update && \
        echo 'Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001' > /etc/apt/preferences.d/mozilla-firefox && \
        # Устанавливаем firefox из PPA
        apt-get install -y firefox && \
        # Очистка
        apt-get clean && \
        rm -rf /var/lib/apt/lists/* 
 
 
# Остальные части Dockerfile
RUN echo "ru" > /etc/default/keyboard

# Устанавливаем русскую локаль
RUN sed -i 's/# ru_RU.UTF-8/ru_RU.UTF-8/' /etc/locale.gen && \
    locale-gen && update-locale LANG=ru_RU.UTF-8

# Копируем и устанавливаем Sentinel HASP runtime
COPY installer/aksusbd_10.13-1_amd64.deb /tmp/aksusbd.deb
RUN chmod +x /tmp/aksusbd.deb && \
    apt-get update && \
    apt-get install -y /tmp/aksusbd.deb && \
    rm /tmp/aksusbd.deb

# Создаем директории для логов и бинарных файлов
RUN mkdir -p \
    /var/log/supervisor \
    /root/.vnc \
    ${LOG_DIR} ${BIN} && \
    touch \
    ${LOG_DIR}/hasp.out.log ${LOG_DIR}/hasp.err.log \
    ${LOG_DIR}/vnc.out.log ${LOG_DIR}/vnc.err.log \
    ${LOG_DIR}/supervisord.log && \
    chmod -R 775 ${LOG_DIR} /var/log/supervisor

# Копируем стартовый скрипт для VNC
COPY vncwrapper.sh ${BIN}/vncwrapper.sh
RUN chmod +x ${BIN}/vncwrapper.sh

# Настройка xstartup для VNC
RUN echo '#!/bin/sh' > /root/.vnc/xstartup && \
    echo 'xrdb $HOME/.Xresources' >> /root/.vnc/xstartup && \
    echo 'startxfce4 &' >> /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Конфигурация supervisord
COPY supervisord.template.conf /etc/supervisord.template.conf

# Настройка entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Открываем порты для VNC, Sentinel и других сервисов
EXPOSE 5901 1947 8080

# Запуск entrypoint
CMD ["/usr/local/bin/entrypoint.sh"]
