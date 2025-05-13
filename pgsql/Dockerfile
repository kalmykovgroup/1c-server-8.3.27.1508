FROM ubuntu:22.04

# Установка основных пакетов и зависимостей
ENV DEBIAN_FRONTEND=noninteractive 

# Получаем ARG'и от docker-compose
ARG POSTGRES_VERSION
ARG PG_DATA_DIR
ARG PG_CONF_DIR
ARG PG_BIN_DIR

# Делаем их ENV внутри контейнера
ENV POSTGRES_VERSION=${POSTGRES_VERSION}
ENV PG_DATA_DIR=${PG_DATA_DIR}
ENV PG_CONF_DIR=${PG_CONF_DIR}
ENV PG_BIN_DIR=${PG_BIN_DIR}
ENV PATH=${PG_BIN_DIR}:$PATH
 
# Устанавливаем необходимые локали
# 1. Установить и сгенерировать локаль ДО PostgreSQL
RUN apt-get update && apt-get install -y locales \
 && sed -i 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen \
 && locale-gen ru_RU.UTF-8 \
 && update-locale LANG=ru_RU.UTF-8

ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_ALL=ru_RU.UTF-8
   
# Установка утилит для анализа и создания локали
RUN apt-get update && apt-get install -y --no-install-recommends \
    bzip2 \
    tar \
    dpkg \
    locales-all \
    ca-certificates \
    gnupg \
    wget \
    curl  \
    libjson-perl \
    ssl-cert \
    ucf \
    tzdata && \
    apt-get clean
    
    
# Копируем архив с PostgreSQL и другие пакеты
COPY installer /tmp/installer

# Установка всех .deb файлов и автоматическая загрузка зависимостей
RUN dpkg -i /tmp/installer/packages/*.deb || (apt-get update && apt-get install -y --fix-broken)

RUN dpkg -i /tmp/installer/postgresql/*.deb || (apt-get update && apt-get install -y --fix-broken)

RUN rm -rf /var/lib/apt/lists/* /tmp/* 
 

#CMD ["tail", "-f", "/dev/null"]

# Копируем entrypoint и конфиги

# Копируем конфиги PostgreSQL
RUN mkdir -p ${PG_CONF_DIR}
COPY ./postgresql.conf ${PG_CONF_DIR}/postgresql.conf
COPY ./pg_hba.conf ${PG_CONF_DIR}/pg_hba.conf
 
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"] 
