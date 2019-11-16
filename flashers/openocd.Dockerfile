# Stage 1. Compile suid and create_user binary
FROM gcc:8.3.0 AS builder
COPY create_user.c /tmp/create_user.c
RUN gcc -DHOMEDIR=\'/data/riotbuild\' -DUSERNAME=\'riotbuild\' /tmp/create_user.c -o /tmp/create_user \
    && rm /tmp/create_user.c

FROM ubuntu:bionic

ENV DEBIAN_FRONTEND noninteractive

ARG FLASH_DEPS="make unzip wget"

ARG OPENOCD_INSTALL_DEPS="build-essential git ca-certificates libtool pkg-config autoconf automake texinfo \
                          libhidapi-hidraw0 libhidapi-dev libusb-1.0"
ARG OPENOCD_VERSION=9de7d9c81d91a5cfc16a1476d558d92b08d7e596
ARG OPENOCD_DEPS=""

# Upgrading system packages to the latest available versions
RUN apt-get update && apt-get -y dist-upgrade
# Installing required packages for flashing toolchain
RUN apt-get -y --no-install-recommends install \
        ${OPENOCD_INSTALL_DEPS} \
        ${OPENOCD_DEPS} \
        ${FLASH_DEPS} \
    # Cleaning up installation files
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Build openocd from source
RUN mkdir -p opt \
    && cd /opt \
    && git clone --depth 1 git://git.code.sf.net/p/openocd/code openocd\
    && cd openocd \
    && git checkout -q ${OPENOCD_VERSION} \
    && ./bootstrap \
    && ./configure --enable-stlink --enable-jlink --enable-ftdi --enable-cmsis-dap \
    && make -j"$(nproc)" \
    && make install-strip \
    && cd .. \
    && rm -rf openocd \
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
