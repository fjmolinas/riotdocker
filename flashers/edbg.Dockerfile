FROM ubuntu:bionic AS builder

ARG EDBG_INSTALL_DEPS="git ca-certificates build-essential libudev-dev"
ARG EDBG_VERSION=a5dd7c78473c0f9035c974a846752e3a1c51116c

# Upgrading system packages to the latest available versions
RUN apt-get update && apt-get -y dist-upgrade
# Installing required packages for flashing toolchain
RUN apt-get -y --no-install-recommends install \
        ${EDBG_INSTALL_DEPS} \
    # Cleaning up installation files
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Compile suid and create_user binary
COPY create_user.c /tmp/create_user.c
RUN gcc -DHOMEDIR=\'/data/riotbuild\' -DUSERNAME=\'riotbuild\' /tmp/create_user.c -o /tmp/create_user \
    && rm /tmp/create_user.c

# Compile edbg binary
RUN mkdir -p opt \
    && cd /opt \
    && git clone --depth 1 https://github.com/ataradov/edbg \
    && cd edbg \
    && git checkout -q ${EDBG_VERSION} \
    && make -j"$(nproc)" \
    && make all

FROM ubuntu:bionic

ENV DEBIAN_FRONTEND noninteractive
ARG FLASH_DEPS="make unzip wget"

ARG EDBG_DEPS=""

# Upgrading system packages to the latest available versions
RUN apt-get update && apt-get -y dist-upgrade
# Installing required packages for flashing toolchain
RUN apt-get -y --no-install-recommends install \
        ${EDBG_DEPS} \
        ${FLASH_DEPS} \
    # Cleaning up installation files
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy edbg binary from previous stage
COPY --from=builder /opt/edbg/edbg /usr/local/bin/edbg

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
