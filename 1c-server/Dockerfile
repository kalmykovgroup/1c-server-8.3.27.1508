FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive



# --- Аргументы сборки ------------------------------------------------
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
ARG ONEC_INSTALLER_NAME 
ARG APACHE_PUBLICATION_CONF_DIR

# --- Переменные среды ------------------------------------------------
ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU.UTF-8
ENV LC_ALL=ru_RU.UTF-8
ENV PATH_TO_1C=${PATH_TO_1C}
ENV ONEC_USER=${ONEC_USER}
ENV ONEC_GROUP=${ONEC_GROUP}
ENV LOG_DIR=${LOG_DIR}
ENV BIN=${BIN}
ENV DATA=${DATA}
ENV CACHE=${CACHE}
ENV LICENSES=${LICENSES}
ENV HASP=${HASP}
ENV WS_PUBLIC_DIR=${WS_PUBLIC_DIR}  
ENV ONEC_INSTALLER_NAME=${ONEC_INSTALLER_NAME} 
ENV APACHE_PUBLICATION_CONF_DIR=${APACHE_PUBLICATION_CONF_DIR}
 

ENV WS_PUBLIC_DIR=${WS_PUBLIC_DIR}  

# --- Создание пользователя 1С ----------------------------------------
RUN groupadd -r ${ONEC_GROUP} && useradd -m -r -g ${ONEC_GROUP} -s /bin/bash ${ONEC_USER}

# --- Установка зависимостей для 1С-сервера --------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Для отладки \
    net-tools \
    # Менеджер процессов supervisor
    supervisor \
    # Клиент PostgreSQL
    postgresql-client \
    # Веб-сервер Apache
    apache2 \
    # Утилиты Apache
    apache2-utils \
    # SSL-сертификаты
    ca-certificates \
    # Генерация шаблонов из шаблонов конфигурации
    gettext \
    # Поддержка локалей
    locales \
    # Работа со шрифтами (печатные формы, PDF)
    fontconfig \
    # Базовые шрифты
    fonts-dejavu-core \
    # Проверка доступности сервисов
    netcat-openbsd \
    # Утилиты для работы с сетью (ping, ip и др.)
    iproute2 \
    # Работа с репозиториями и ключами
    software-properties-common \
    gnupg \
 && locale-gen ru_RU.UTF-8 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*


# --- Установка зависимостей для VNC и GUI (активация лицензии) ------
RUN apt-get update && apt-get install -y --no-install-recommends \
    # X-сервер (виртуальное графическое окружение)
    xorg \
    # Утилиты X11 (xrandr, xdpyinfo и др.)
    x11-utils \
    # Дополнительные утилиты X-сервера
    x11-xserver-utils \
    # Лёгкий оконный менеджер
    openbox \
    # Терминал в GUI
    xterm \
    # Сервер VNC
    tigervnc-standalone-server \
    # Общие компоненты VNC
    tigervnc-common \
    # Поддержка xdg-меню в openbox
    python3-xdg \
    # Меню приложений для Openbox
    menu \
 && apt-get clean && rm -rf /var/lib/apt/lists/*


# --- Установка шрифтов Microsoft Core Fonts (для печати) ------------
RUN echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections && \
    apt-get update && \
    apt-get install -y --no-install-recommends ttf-mscorefonts-installer && \
    fc-cache -f -v && \
    apt-get clean && rm -rf /var/lib/apt/lists/* 


# 🌐 Локализация
ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU.UTF-8
ENV LC_ALL=ru_RU.UTF-8

# 📂 Добавим 1С в PATH
ENV PATH="${PATH_TO_1C}:${PATH}"

# --- Установка платформы 1С ------------------------------------------
COPY installer/*.run /tmp/
RUN chmod +x /tmp/*.run && /tmp/*.run \
      --mode unattended \
      --enable-components server,server_admin,liberica_jre,v8_install_deps,ws,ru,client_full \
      --disable-components client_thin,client_thin_fib,desktop_icons \
      --debugtrace /tmp/install.log && \
    rm -f /tmp/*

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


# 📁 Каталоги, логи и права
RUN mkdir -p \
    ${LOG_DIR} \
    ${DATA} \
    ${CACHE} \
    ${LICENSES} \
    ${HASP} \
    ${BIN} \
    ${WS_PUBLIC_DIR} \
    /root/.vnc \
    /home/${ONEC_USER} \
    ${APACHE_PUBLICATION_CONF_DIR} \
    /var/log/supervisor && \
# Лог-файлы, которые нужны для supervisor и скриптов
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
# Права доступа
    chown -R ${ONEC_USER}:${ONEC_GROUP} \
      ${LOG_DIR} \
      ${DATA} \
      ${CACHE} \
      ${LICENSES} \
      ${HASP} \
      ${BIN} \
      ${WS_PUBLIC_DIR} \
      /home/${ONEC_USER} \
      /var/log/supervisor && \
    chmod -R 775 \
      ${LOG_DIR} \
      ${DATA} \
      ${CACHE} \
      ${LICENSES} \
      ${HASP} \
      ${WS_PUBLIC_DIR} \
      /home/${ONEC_USER}


# 🧾 Копируем скрипты
COPY init-ib.sh ${BIN}/init-ib.sh
COPY start-ragent.sh ${BIN}/start-ragent.sh
COPY init-cluster.sh ${BIN}/init-cluster.sh
COPY init-server.sh ${BIN}/init-server.sh 
COPY init-web.sh ${BIN}/init-web.sh  
COPY start-vnc.sh ${BIN}/start-vnc.sh
 
#Делаем исполняемыми и передаем право на управление пользователю ${ONEC_USER}:${ONEC_GROUP}
# 🛠️ Права на скрипты
RUN chmod +x \
      ${BIN}/init-ib.sh \
      ${BIN}/start-ragent.sh \
      ${BIN}/init-cluster.sh \
      ${BIN}/init-server.sh \
      ${BIN}/init-web.sh \
      ${BIN}/start-vnc.sh && \
    chown ${ONEC_USER}:${ONEC_GROUP} \
      ${BIN}/init-ib.sh \
      ${BIN}/start-ragent.sh \
      ${BIN}/init-cluster.sh \
      ${BIN}/init-server.sh \
      ${BIN}/init-web.sh \
      ${BIN}/start-vnc.sh 
    
# ⚙️ Конфигурация supervisor 
COPY supervisord.template.conf /etc/supervisord.template.conf 

# Настройка xstartup для VNC
RUN echo '#!/bin/sh' > /root/.vnc/xstartup && \
    echo 'xrdb $HOME/.Xresources' >> /root/.vnc/xstartup && \
    echo 'openbox-session &' >> /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup 

# 🌐 Apache: папка для публикации
RUN mkdir -p ${APACHE_PUBLICATION_CONF_DIR} && \
    chown root:root ${APACHE_PUBLICATION_CONF_DIR} && \
    chmod 755 ${APACHE_PUBLICATION_CONF_DIR} 
     

# 🔁 Запуск
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
CMD ["/usr/local/bin/entrypoint.sh"]
