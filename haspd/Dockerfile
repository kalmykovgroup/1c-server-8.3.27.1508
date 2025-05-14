FROM ubuntu:24.04

# Аргументы для путей логов и бинарных файлов
ARG LOG_DIR
ARG BIN

# Установка переменных окружения
ENV LOG_DIR=${LOG_DIR}
ENV BIN=${BIN}
ENV DEBIAN_FRONTEND=noninteractive

# Обновляем кэш пакетов один раз
RUN apt-get update

# Устанавливаем утилиты для репозиториев и APT
RUN dpkg --add-architecture i386                                           # Добавляем архитектуру i386 для поддержки 32-битных библиотек
RUN apt-get install -y --no-install-recommends gnupg                       # Устанавливаем GnuPG для apt-key
RUN apt-get install -y --no-install-recommends ca-certificates             # для https-запросов 
RUN apt-get install -y --no-install-recommends software-properties-common  # для https-запросов 

 

#Для отладки
RUN apt-get install -y net-tools             # ifconfig, netstat и др.
RUN apt-get install -y curl                  # Утилита загрузки по HTTP
RUN apt-get install -y file                  # Определение типа файлов
RUN apt-get install -y nano                  #  


RUN apt-get install -y sudo                  #Для нового пользователя  

# Добавляем поддержку архитектуры i386 и ключ для focal-security (нужно для HASP)
RUN echo "deb [arch=amd64,i386] http://security.ubuntu.com/ubuntu focal-security main" > /etc/apt/sources.list.d/focal-i386.list

# Импортируем GPG-ключ и сохраняем в формате .gpg
RUN curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x3B4FE6ACC0B21F32" | gpg --dearmor -o /etc/apt/trusted.gpg.d/ubuntu-focal-security.gpg

# Повторное обновление кэша — обязательно!
RUN apt-get update

# Основные зависимости для HASP
RUN apt-get install -y libc6:i386            # Базовая 32-битная libc
RUN apt-get install -y libncurses6:i386      # Поддержка текстового интерфейса (32-бит)
RUN apt-get install -y libstdc++6:i386       # Стандартные C++ библиотеки (32-бит)
RUN apt-get install -y lib32z1               # 32-битная zlib (сжатие)
RUN apt-get install -y lib32ncurses6         # ncurses для 32-битных приложений
RUN apt-get install -y libssl1.1:i386        # OpenSSL 1.1 (32-бит) для шифрования
RUN apt-get install -y libusb-0.1-4:i386     # Драйвер доступа к USB (32-бит)

# Системные утилиты
RUN apt-get install -y locales               # Локализация и генерация языков
RUN apt-get install -y supervisor            # Контроль запуска сервисов
RUN apt-get install -y gettext               # Утилиты локализации (msgfmt и др.)
RUN apt-get install -y libudev1              # Работа с udev (устройствами)
RUN apt-get install -y lsb-release           # Информация о системе
RUN apt-get install -y usbutils              # Утилиты для работы с USB (lsusb)

# Для графики
RUN apt-get install -y --no-install-recommends xfce4 # Устанавливаем XFCE - базовое рабочее окружение
RUN apt-get install -y --no-install-recommends xfce4-goodies # Устанавливаем дополнительные утилиты и панели XFCE
RUN apt-get install -y --no-install-recommends dbus-x11 # Поддержка D-Bus в графическом режиме
RUN apt-get install -y --no-install-recommends xfonts-base # Базовые X-шрифты
RUN apt-get install -y --no-install-recommends xauth # Авторизация X-сессий (требуется для запуска GUI)
RUN apt-get install -y --no-install-recommends xdg-utils # Утилиты запуска внешних приложений, например xdg-open

# Устанавливаем сервер удалённого рабочего стола (RDP)
RUN apt-get install -y --no-install-recommends xrdp 
RUN apt-get install -y --no-install-recommends xinit
RUN apt-get install -y --no-install-recommends xorgxrdp
RUN apt-get install -y --no-install-recommends xserver-xorg-core

RUN adduser xrdp ssl-cert


# Назначаем XFCE как сессию по умолчанию для всех пользователей
RUN echo "startxfce4" > /etc/skel/.xsession
RUN echo "startxfce4" > /root/.xsession
RUN apt-get install -y --no-install-recommends xserver-xorg

RUN mkdir -p /var/run/xrdp && chown xrdp:xrdp /var/run/xrdp
RUN cp /etc/pam.d/common-session /etc/pam.d/xrdp-sesman

# Обновляем конфигурацию XRDP для запуска XFCE
RUN sed -i 's|^.*exec.*|exec startxfce4|' /etc/xrdp/startwm.sh

RUN apt-get install -y epiphany-browser #Добавим установку лёгкого браузера для подключения к haspd

# Очистка
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*

 
# Остальные части Dockerfile
RUN echo "ru" > /etc/default/keyboard

# Устанавливаем русскую локаль
RUN sed -i 's/# ru_RU.UTF-8/ru_RU.UTF-8/' /etc/locale.gen && \
    locale-gen && update-locale LANG=ru_RU.UTF-8

# Копируем и устанавливаем Sentinel HASP runtime
COPY installer/aksusbd_10.13-1_amd64.deb /tmp/aksusbd.deb
RUN apt-get install -y /tmp/aksusbd.deb && \
    rm /tmp/aksusbd.deb 

# Создаем директории для логов и бинарных файлов
RUN mkdir -p ${LOG_DIR} ${BIN} 
    


# Устанавливаем компоненты, часто необходимые для xrdp-sesman (если нет)
#polkitd — это демон PolicyKit, который:
#позволяет приложениям запрашивать привилегии (например, XFCE хочет доступ к монтированию, настройке сети и т.п.); 
RUN apt-get install -y --no-install-recommends polkitd

 
# Конфигурация supervisord
COPY supervisord.template.conf /etc/supervisord.template.conf

# Настройка entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

 
# Запуск entrypoint
CMD ["/usr/local/bin/entrypoint.sh"]
