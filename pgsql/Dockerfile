FROM rockylinux:9
 
# Устанавливаем необходимые локали
RUN dnf install -y glibc-langpack-ru && \
    localedef -i ru_RU -f UTF-8 ru_RU.UTF-8 || true \
    
ENV LANG=ru_RU.UTF-8
ENV LC_ALL=ru_RU.UTF-8

ARG CONF_DIR 
ARG PG_BIN 

ENV CONF_DIR=${CONF_DIR} 
ENV PG_BIN=${PG_BIN} 

# Устанавливаем базовые утилиты
RUN dnf install -y \
    tar \
    gzip \
    bzip2 \
    xz \
    dnf-utils \
    epel-release \
 && dnf clean all

# Включаем CodeReady Builder (CRB) репозиторий — нужен для perl-IPC-Run
RUN dnf config-manager --set-enabled crb \
 && dnf install -y perl-IPC-Run \
 && dnf clean all

# Копируем архивы RPM
COPY postgresql_17.2_4.1C_x86_64_rpm.tar.bz2 /tmp/
COPY postgresql_17.2_4.1C_x86_64_addon_rpm.tar.bz2 /tmp/

# Распаковываем RPM-файлы
RUN mkdir -p /tmp/rpms && \
    tar -xjf /tmp/postgresql_17.2_4.1C_x86_64_rpm.tar.bz2 -C /tmp/rpms && \
    tar -xjf /tmp/postgresql_17.2_4.1C_x86_64_addon_rpm.tar.bz2 -C /tmp/rpms

# Устанавливаем все найденные RPM-пакеты
RUN find /tmp/rpms -name "*.rpm" -exec dnf install -y {} + && \
    rm -rf /tmp/* 


# Копируем наш entrypoint-скрипт в контейнер
COPY entrypoint.sh $PG_BIN/entrypoint.sh
RUN chmod +x $PG_BIN/entrypoint.sh

# Создаём директорию для конфигов PostgreSQL
RUN mkdir -p $CONF_DIR

# Копируем конфиги внутрь контейнера
COPY postgresql.conf $CONF_DIR/postgresql.conf
COPY pg_hba.conf $CONF_DIR/pg_hba.conf

WORKDIR $PG_BIN

ENTRYPOINT ["./entrypoint.sh"]

CMD ["postgres"]
