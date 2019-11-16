FROM gcc:8.3.0 AS builder
# Compile suid and create_user binary
COPY create_user.c /tmp/create_user.c
RUN gcc -DHOMEDIR=\'/data/riotbuild\' -DUSERNAME=\'riotbuild\' /tmp/create_user.c -o /tmp/create_user \
    && rm /tmp/create_user.c

FROM ubuntu:bionic

ENV DEBIAN_FRONTEND noninteractive
ARG FLASH_DEPS="make unzip wget"

ARG PYOCD_DEPS="python3 python3-dev python3-pip python3-setuptools"

# Upgrading system packages to the latest available versions
RUN apt-get update && apt-get -y dist-upgrade
# Installing required packages for flashing toolchain
RUN apt-get -y --no-install-recommends install \
        ${PYOCD_DEPS} \
        ${FLASH_DEPS} \
    # Cleaning up installation files
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install esptool
RUN pip3 install --no-cache-dir esptool

# HACK, currently it is using the one in esptoolchain by default, we do not have
# esptoolchain in this image
ENV ESPTOOL esptool.py

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
