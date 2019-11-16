# Stage 1. Compile suid and create_user binary
FROM gcc:8.3.0 AS builder
COPY create_user.c /tmp/create_user.c
RUN gcc -DHOMEDIR=\'/data/riotbuild\' -DUSERNAME=\'riotbuild\' /tmp/create_user.c -o /tmp/create_user \
    && rm /tmp/create_user.c

FROM ubuntu:bionic

ENV DEBIAN_FRONTEND noninteractive

ARG FLASH_DEPS="make unzip wget"

ARG MSPDEBUG_INSTALL_DEPS="build-essential git ca-certificates"
ARG MSPDEBUG_VERSION=b506542094de19a0a11e638a7e34e0bc4adf8d7c
ARG MSPDEBUG_DEPS="libusb-1.0 libusb-dev libreadline-dev"

# Upgrading system packages to the latest available versions
RUN apt-get update && apt-get -y dist-upgrade
# Installing required packages for flashing toolchain
RUN apt-get -y --no-install-recommends install \
        ${MSPDEBUG_INSTALL_DEPS} \
        ${MSPDEBUG_DEPS} \
        ${FLASH_DEPS} \
    # Cleaning up installation files
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Building mspdebug from source
RUN mkdir -p opt \
    && cd /opt \
    && git clone --depth 1 https://github.com/dlbeer/mspdebug \
    && cd mspdebug \
    && git checkout -q ${MSPDEBUG_VERSION} \
    && make -j"$(nproc)" \
    && make install \
    && cd .. \
    && rm -rf mspdebug \
    && rm -rf /var/lib/apt/lists/*

# Copy user binary from previous stage
COPY --from=builder /tmp/create_user /usr/local/bin/create_user
RUN chown root:root /usr/local/bin/create_user \
    && chmod u=rws,g=x,o=- /usr/local/bin/create_user

# Copy our entry point script (signal wrapper)
COPY run.sh /run.sh
ENTRYPOINT ["/bin/bash", "/run.sh"]

# By default, run a shell when no command is specified on the docker command line
CMD ["/bin/bash"]

WORKDIR /data/riotbuild
