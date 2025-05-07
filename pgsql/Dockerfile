FROM ubuntu:22.04

ARG CONF_DIR
ARG PGSQL_INSTALLER_NAME

ENV CONF_DIR=${CONF_DIR}
ENV PGSQL_INSTALLER_NAME=${PGSQL_INSTALLER_NAME}
 

ENV LANG=ru_RU.UTF-8
ENV LANGUAGE=ru_RU:ru
ENV LC_ALL=ru_RU.UTF-8

# Установка основных пакетов и зависимостей
ENV DEBIAN_FRONTEND=noninteractive
 
   
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
    

# Установка русской локали
RUN apt-get update && apt-get install -y locales && \
    sed -i 's/# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen ru_RU.UTF-8 
    
# Копируем архив с PostgreSQL и другие пакеты
COPY installer /tmp/installer

# Установка всех .deb файлов и автоматическая загрузка зависимостей
RUN dpkg -i /tmp/installer/packages/*.deb || (apt-get update && apt-get install -y --fix-broken)

RUN dpkg -i /tmp/installer/postgresql/*.deb || (apt-get update && apt-get install -y --fix-broken)

RUN rm -rf /var/lib/apt/lists/* /tmp/* 
 
RUN mkdir -p $CONF_DIR
COPY postgresql.conf $CONF_DIR/postgresql.conf
COPY pg_hba.conf $CONF_DIR/pg_hba.conf
COPY pg_ident.conf $CONF_DIR/pg_ident


COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"] 
