FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# --- Аргументы сборки ---
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

# --- Переменные среды ---
ENV LANG=ru_RU.UTF-8 \
    LANGUAGE=ru_RU.UTF-8 \
    LC_ALL=ru_RU.UTF-8 \
    PATH_TO_1C=${PATH_TO_1C} \
    ONEC_USER=${ONEC_USER} \
    ONEC_GROUP=${ONEC_GROUP} \
    LOG_DIR=${LOG_DIR} \
    BIN=${BIN} \
    DATA=${DATA} \
    CACHE=${CACHE} \
    LICENSES=${LICENSES} \
    HASP=${HASP} \
    WS_PUBLIC_DIR=${WS_PUBLIC_DIR} \
    ONEC_INSTALLER_NAME=${ONEC_INSTALLER_NAME} \
    APACHE_PUBLICATION_CONF_DIR=${APACHE_PUBLICATION_CONF_DIR} \
    PATH="${PATH_TO_1C}:${PATH}"

# --- Создание пользователя ---
RUN groupadd -r ${ONEC_GROUP} && useradd -m -r -g ${ONEC_GROUP} -s /bin/bash ${ONEC_USER}

# --- Зависимости 1С сервера ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    net-tools supervisor postgresql-client apache2 apache2-utils \
    ca-certificates gettext locales fontconfig fonts-dejavu-core \
    netcat-openbsd iproute2 software-properties-common gnupg \
 && locale-gen ru_RU.UTF-8 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

#
RUN apt-get update && apt-get install -y --no-install-recommends iputils-ping curl

# --- VNC и GUI ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 🖥️ Сам VNC-сервер (основной процесс Xvnc)
    tigervnc-standalone-server \
    # 📦 Общие библиотеки для VNC
    tigervnc-common \
    # 🛠️ Утилиты VNC: vncpasswd, vncconfig и т.п.
    tigervnc-tools \
    # 🪟 Основное графическое окружение XFCE (панели, рабочий стол)
    xfce4 \
    # 🔧 Полезные утилиты и компоненты для XFCE (xfce4-terminal и др.)
    xfce4-goodies \
    # 🔌 D-Bus через X11 (требуется большинству GUI-программ, включая 1С)
    dbus-x11 \
    # 🔡 Базовые X-шрифты (нужны для корректного отображения интерфейса)
    xfonts-base \
    # 🔐 Авторизация X-сессий (важно для запуска через VNC)
    xauth \
    # 📂 xdg-open и другие утилиты взаимодействия с рабочим окружением
    xdg-utils \
    # 🧱 GTK-библиотека — основа графического интерфейса 1С
    libgtk-3-0 \
    # 🖼️ Отрисовка изображений, иконок, интерфейсов
    libgdk-pixbuf2.0-0 \
    # 🎮 OpenGL-библиотека (нужна для PDF-форм, отрисовки, графики)
    libgl1 \
    # 🔧 Обработка XML через XSLT (некоторые компоненты 1С это используют)
    libxslt1.1 \
    # 🌐 WebKit2 — обязателен для client_full 1С
    libwebkit2gtk-4.1-0 \
    # 🔁 glib-интеграция с D-Bus — используется серверной частью 1С
    libdbus-glib-1-2 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*


# --- Шрифты Microsoft ---
RUN echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections && \
    apt-get update && \
    apt-get install -y --no-install-recommends ttf-mscorefonts-installer && \
    fc-cache -f -v && \
    apt-get clean && rm -rf /var/lib/apt/lists/* 

#Не достающие пакеты для client_full (Для тонкого клиента)
RUN apt-get update && apt-get install -y --no-install-recommends \
    policykit-1 zenity x11-utils evince libglu1-mesa \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Установка 1С платформы --- 
COPY installer/ /tmp/installer/
RUN chmod +x /tmp/installer/*.run && chmod +x /tmp/installer/installAsRoot && \
    /tmp/installer/installAsRoot \
      --mode unattended \
      --enable-components server,server_admin,liberica_jre,v8_install_deps,ws,ru,client_full,desktop_icons \
      --disable-components client_thin,client_thin_fib\
      --debugtrace /tmp/install.log  && \
    rm -rf /tmp/installer




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


# --- Каталоги и права ---
RUN mkdir -p \
    ${LOG_DIR} ${DATA} ${CACHE} ${LICENSES} ${HASP} ${BIN} \
    ${WS_PUBLIC_DIR} ${APACHE_PUBLICATION_CONF_DIR} /root/.vnc \
    /home/${ONEC_USER} /var/log/supervisor && \
    touch ${LOG_DIR}/supervisord.log && \
    chown -R ${ONEC_USER}:${ONEC_GROUP} \
      ${LOG_DIR} ${DATA} ${CACHE} ${LICENSES} ${HASP} ${BIN} ${WS_PUBLIC_DIR} \
      /home/${ONEC_USER} /var/log/supervisor && \
    chmod -R 775 ${LOG_DIR} ${DATA} ${CACHE} ${LICENSES} ${HASP} ${WS_PUBLIC_DIR}

# --- Скрипты и конфиги --- 
COPY init-ib.sh start-ragent.sh init-cluster.sh init-server.sh start-ras.sh init-web.sh start-vnc.sh ${BIN}/
RUN chmod +x ${BIN}/*.sh && \
    chown ${ONEC_USER}:${ONEC_GROUP} ${BIN}/*.sh

COPY supervisord.template.conf /etc/supervisord.template.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
 

# --- Apache ---
RUN mkdir -p ${APACHE_PUBLICATION_CONF_DIR} && \
    chown root:root ${APACHE_PUBLICATION_CONF_DIR} && \
    chmod 755 ${APACHE_PUBLICATION_CONF_DIR}

# --- Запуск ---
CMD ["/usr/local/bin/entrypoint.sh"]

