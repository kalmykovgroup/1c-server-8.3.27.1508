FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# --- Аргументы сборки --- 
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

# --- Зависимости 1С сервера ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    net-tools supervisor postgresql-client apache2 apache2-utils \
    ca-certificates gettext locales fontconfig fonts-dejavu-core \
    netcat-openbsd iproute2 software-properties-common gnupg \
 && locale-gen ru_RU.UTF-8 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*

#
RUN apt-get update && apt-get install -y --no-install-recommends iputils-ping curl

RUN apt-get update && apt-get install -y --no-install-recommends \
    # 🖥️ Рабочее окружение XFCE
    xfce4 \
    xfce4-goodies \
    dbus-x11 \
    xfonts-base \
    xauth \
    xdg-utils \
    # 🔒 RDP-сервер и его зависимости
    xrdp \
    xinit \
    xorgxrdp \
    xserver-xorg-core \
    # 🧱 GTK и другие GUI-библиотеки, нужные для 1С
    libgtk-3-0 \
    libgdk-pixbuf2.0-0 \
    libgl1 \
    libxslt1.1 \
    libwebkit2gtk-4.1-0 \
    libdbus-glib-1-2 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*


# Виртуальный X-сервер для headless GUI (для запуска 1cv8 /Execute без DISPLAY)
RUN apt-get update && apt-get install -y --no-install-recommends xvfb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

 
# (Удаленный рабочий стол )
RUN adduser xrdp ssl-cert
RUN echo "startxfce4" > /etc/skel/.xsession
RUN echo "startxfce4" > /root/.xsession
RUN apt-get install -y --no-install-recommends xserver-xorg-core
RUN cp /etc/pam.d/common-session /etc/pam.d/xrdp-sesman
RUN sed -i 's|^.*exec.*|exec startxfce4|' /etc/xrdp/startwm.sh # Обновляем конфигурацию XRDP для запуска XFCE

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

#RUN groupadd -r grp1cv8 && useradd -r -g grp1cv8 -s /bin/false usr1cv8 || true  # "|| true" на случай, если уже создан

RUN apt-get update \
 && add-apt-repository universe \
 && apt-get update && apt-get install -y sudo
 

# --- Каталоги и права ---
RUN mkdir -p ${DATA} ${CACHE} ${LICENSES} ${HASP} ${BIN} \
    ${WS_PUBLIC_DIR} ${APACHE_PUBLICATION_CONF_DIR} /root/.vnc
 
# --- Скрипты и конфиги ---
COPY init-ib.sh start-ragent.sh init-cluster.sh init-server.sh start-ras.sh init-web.sh ${BIN}/
RUN chmod +x ${BIN}/*.sh



COPY supervisord.template.conf /etc/supervisord.template.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
 

# --- Apache ---
RUN mkdir -p ${APACHE_PUBLICATION_CONF_DIR} && \
    chmod 755 ${APACHE_PUBLICATION_CONF_DIR}


# Копируем скрипты VBEP
COPY scripts/ /opt/scripts/
RUN chmod +r /opt/scripts/*.vbep

# --- Запуск ---
CMD ["/usr/local/bin/entrypoint.sh"]

