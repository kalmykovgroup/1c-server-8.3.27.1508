FROM ubuntu:24.04
 
 
 # 📁 Установим переменные
ARG ONEC_VERSION
ARG ONEC_USER
ARG ONEC_GROUP
ARG LOG_DIR
ARG BIN
ARG DATA
ARG CACHE
ARG LICENSES
ARG HASP
ARG PATH_TO_1C

ARG WS_PUBLIC_DIR
ARG CLUSTER_PORT_RAGENT
ARG APACHE_PUBLICATION_CONF_DIR 

ENV ONEC_VERSION=${ONEC_VERSION}
ENV ONEC_USER=${ONEC_USER}
ENV ONEC_GROUP=${ONEC_GROUP}
ENV LOG_DIR=${LOG_DIR}
ENV BIN=${BIN}
ENV DATA=${DATA}
ENV CACHE=${CACHE}
ENV LICENSES=${LICENSES}
ENV HASP=${HASP}
ENV PATH_TO_1C=${PATH_TO_1C}

ENV WS_PUBLIC_DIR=${WS_PUBLIC_DIR}
ENV CLUSTER_PORT_RAGENT=${CLUSTER_PORT_RAGENT}
ENV APACHE_PUBLICATION_CONF_DIR=${APACHE_PUBLICATION_CONF_DIR} 

ENV DEBIAN_FRONTEND=noninteractive

# 🧑‍💼 Пользователь и группа для 1С
RUN groupadd -r ${ONEC_GROUP} && useradd -m -r -g ${ONEC_GROUP} -s /bin/bash ${ONEC_USER} 

# Починим недостающие ключи GPG для Ubuntu 24.04

RUN apt-get update || true \
 && apt-get install -y --no-install-recommends gnupg ca-certificates \
 && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32 \
 && apt-get update 

# Включаем поддержку i386 в источниках
RUN echo "deb [arch=amd64,i386] http://archive.ubuntu.com/ubuntu noble main restricted universe multiverse" > /etc/apt/sources.list.d/i386.list && \
    echo "deb [arch=amd64,i386] http://archive.ubuntu.com/ubuntu noble-updates main restricted universe multiverse" >> /etc/apt/sources.list.d/i386.list && \
    echo "deb [arch=amd64,i386] http://security.ubuntu.com/ubuntu noble-security main restricted universe multiverse" >> /etc/apt/sources.list.d/i386.list

 
# Установка 32-битных библиотек, необходимых для 1С
RUN dpkg --add-architecture i386 && \
 apt-get update && apt-get install -y --no-install-recommends \
    lib32z1 \
    libc6-i386 \
    libx11-6 \
    libxext6 \
    libxcb1 \
    libxrender1 \
    libxrandr2 \
    libxi6 \
    libxtst6 && \
 apt-get clean && rm -rf /var/lib/apt/lists/*

 
#VNC
RUN apt-get update && apt-get install -y --no-install-recommends \
    xorg \
    x11-apps \
    x11-utils \
    x11-xserver-utils \
    # Лёгкий оконный менеджер
    openbox \
    # Терминал в X
    xterm \
    tigervnc-standalone-server \
    tigervnc-common \
    tigervnc-tools \
    # Нужен для работы openbox-xdg-autostart
    python3-xdg \
    #Используется для отображения правого меню мыши (по умолчанию) Без него Openbox пишет: #Unable to find a valid menu file "/var/lib/openbox/debian-menu.xml"
    menu \
 && apt-get clean && rm -rf /var/lib/apt/lists/*
    
    # --- Для минимальной работы 1С и сервисов -----------------------  
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Менеджер процессов 1С
    supervisor \
    # Клиент PostgreSQL  
    postgresql-client \
    # Веб-сервер Apache (для работы для ws в этой версии он требует наличие) 
    apache2 \
    # Утилиты Apache
    apache2-utils \
    # SSL-сертификаты (HTTPS, подключение к внешним сервисам) 
    ca-certificates \
    # Для шаблонов конфигурации (например, supervisor.template.conf)  
    gettext \
    # Поддержка локалей (обязательно для русского языка)
    locales \
    # Работа со шрифтами (PDF-отчеты, печатные формы)
    fontconfig \
    #Для работы .sh файлов (проверка на доступность сервисов 1с)
    netcat-openbsd \
    # Использует start-ragent.sh. Утилиты для работы с сетью (ping, traceroute и т.д.)
    iproute2 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*  

    # --- Для локализации и отображения шрифтов --------------------  
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Подсистема шрифтов
    fontconfig \
    # Базовые шрифты 
    fonts-dejavu-core

    # --- Для сборки и добавления репозиториев (build-time) -------  
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Импорт PGP-ключей
    gnupg \
    # add-apt-repository
    software-properties-common \
    #Генерация русской и английской локалей
 && locale-gen en_US.UTF-8 ru_RU.UTF-8 \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* 

# Установка шрифтов Microsoft Core Font (требуется для 1С)
RUN apt-get update && \
    apt-get install -y ttf-mscorefonts-installer && \
    echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections && \
    apt-get install -y --no-install-recommends ttf-mscorefonts-installer && \
    fc-cache -f -v && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
 

 
# 🌐 Локализация
ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU.UTF-8
ENV LC_ALL=ru_RU.UTF-8

# 📂 Добавим 1С в PATH
ENV PATH="${PATH_TO_1C}:${PATH}"

# 📦 Установка 1С
COPY installer/setup-full-${ONEC_VERSION}-x86_64.run /tmp/
RUN chmod +x /tmp/setup-full-${ONEC_VERSION}-x86_64.run && \
    /tmp/setup-full-${ONEC_VERSION}-x86_64.run \
      --mode unattended \
      --enable-components server,server_admin,liberica_jre,v8_install_deps,ws,ru,client_full,desktop_icons \
      --disable-components client_thin,client_thin_fib \
      --debugtrace /tmp/install.log && \
    rm -f /tmp/setup-full-${ONEC_VERSION}-x86_64.run 


# server                      -  Сервер 1С. Без него сервер не будет работать.
# server_admin                -  Администрирование лицензий (веб-интерфейс на порту 1541).  
# liberica_jre                -  Java Runtime Environment (требуется для работы server_admin).
# v8_install_deps             -  Системные зависимости (библиотеки, пакеты)
# ws                          -  Веб-сервер для доступа через браузер (HTTP-сервисы, тонкий клиент). 
# ru                          -  Локализация на русский (уже включена по умолчанию).
# config_storage_server       -  Хранилище конфигураций (для командной разработки).  
# additional_admin_functions  -  Расширенные функции администрирования (настройка кластера, мониторинг).
# integrity_monitoring        -  Контроль целостности данных (аудит изменений). 

# Не нужно
# client_full                 -  Толстый клиент (для разработки/администрирования на ПК).
# client_thin                 -  Тонкий клиент (для работы через RDP/терминал).
# client_thin_fib             -  Тонкий клиент с ФИАС (геокодирование).
# desktop_icons               -  Ярлыки на рабочем столе (бессмысленно в контейнере).


# 📁 Каталоги и права 
RUN mkdir -p \
    ${LOG_DIR} \
    ${DATA} \
    ${CACHE} \
    /root/.vnc \
    /home/${ONEC_USER} && \
    touch \
         ${LOG_DIR}/ragent.out.log ${LOG_DIR}/ragent.err.log \
         ${LOG_DIR}/ras.out.log ${LOG_DIR}/ras.err.log \
         ${LOG_DIR}/rmngr.out.log ${LOG_DIR}/rmngr.err.log \
         ${LOG_DIR}/rphost.out.log ${LOG_DIR}/rphost.err.log \
         ${LOG_DIR}/init-ib.out.log ${LOG_DIR}/init-ib.err.log \
         ${LOG_DIR}/init-cluster.out.log ${LOG_DIR}/init-cluster.err.log \
         ${LOG_DIR}/init-server.out.log ${LOG_DIR}/init-server.err.log \
         ${LOG_DIR}/init-web.out.log ${LOG_DIR}/init-web.err.log \
         ${LOG_DIR}/vnc.out.log ${LOG_DIR}/vnc.err.log \
         ${LOG_DIR}/supervisord.log && \
    chown -R ${ONEC_USER}:${ONEC_GROUP} ${LOG_DIR} ${DATA} ${CACHE} /home/${ONEC_USER} /var/log/supervisor && \
    chmod -R 775 ${LOG_DIR} ${DATA} ${CACHE} ${LICENSES} /home/${ONEC_USER}


# 🧾 Скрипты, копируем в контейнер
COPY init-ib.sh ${BIN}/init-ib.sh
COPY start-ragent.sh ${BIN}/start-ragent.sh
COPY init-cluster.sh ${BIN}/init-cluster.sh
COPY init-server.sh ${BIN}/init-server.sh 
COPY init-web.sh ${BIN}/init-web.sh  
 
#Делаем исполняемыми и передаем право на управление пользователю ${ONEC_USER}:${ONEC_GROUP}
RUN \
  chmod +x \
    ${BIN}/init-ib.sh \
    ${BIN}/start-ragent.sh \
    ${BIN}/init-cluster.sh \
    ${BIN}/init-server.sh \
    ${BIN}/init-web.sh \
&& \
  chown ${ONEC_USER}:${ONEC_GROUP} \
    ${BIN}/init-ib.sh \
    ${BIN}/start-ragent.sh \
    ${BIN}/init-cluster.sh \
    ${BIN}/init-server.sh

# ⚙️ Конфигурация supervisor 
COPY supervisord.template.conf /etc/supervisord.template.conf 


# Копируем стартовый скрипт для VNC
COPY start-vnc.sh ${BIN}/start-vnc.sh
RUN chmod +x ${BIN}/start-vnc.sh

# Настройка xstartup для VNC
RUN echo '#!/bin/sh' > /root/.vnc/xstartup && \
    echo 'xrdb $HOME/.Xresources' >> /root/.vnc/xstartup && \
    echo 'openbox-session &' >> /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup 

RUN mkdir -p ${APACHE_PUBLICATION_CONF_DIR} && \
     touch ${APACHE_PUBLICATION_CONF_DIR}/${APACHE_PUBLICATION_CONF_FILE} && \
    chown root:root ${APACHE_PUBLICATION_CONF_DIR} && \
    chmod 755 ${APACHE_PUBLICATION_CONF_DIR} 
     

# 🔁 Запуск
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
CMD ["/usr/local/bin/entrypoint.sh"]
