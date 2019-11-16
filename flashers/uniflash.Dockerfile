# Compile suid and create_user binary
FROM gcc:8.3.0 AS compiler
COPY create_user.c /tmp/create_user.c
RUN gcc -DHOMEDIR=\'/data/riotbuild\' -DUSERNAME=\'riotbuild\' /tmp/create_user.c -o /tmp/create_user \
    && rm /tmp/create_user.c

FROM ubuntu:bionic

ENV DEBIAN_FRONTEND noninteractive
ARG FLASH_DEPS="make unzip"

ARG UNIFLASH_INSTALL_DEPS="wget ca-certificates"

ARG UNIFLASH_VERSION=4.6.0.2176
ARG UNIFLASH_DEPS="libnotify4 libcanberra0 libpython2.7 libusb-1.0 libudev-dev \
                   libusb-dev libtool libdbus-1-dev libx11-dev libnss3 \
                   libcap-dev libcairo2-dev libgconf2-4 libgtk2.0-dev \
                   libpango-1.0-0 libxtst6"

# Upgrading system packages to the latest available versions
RUN apt-get update && apt-get -y dist-upgrade
# Installing required packages for flashing toolchain
RUN apt-get -y --no-install-recommends install \
        ${UNIFLASH_DEPS} \
        ${UNIFLASH_INSTALL_DEPS} \
        ${FLASH_DEPS} \
    # Cleaning up installation files
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install uniflash
RUN wget --quiet http://software-dl.ti.com/ccs/esd/uniflash/uniflash_sl.${UNIFLASH_VERSION}.run \
    && chmod +x uniflash_sl.${UNIFLASH_VERSION}.run \
    && ./uniflash_sl.${UNIFLASH_VERSION}.run --prefix /opt/ti/uniflash --mode unattended \
    && rm uniflash_sl.${UNIFLASH_VERSION}.run

ENV UNIFLASH_PATH /opt/ti/uniflash

# Copy user binary from previous stage
COPY --from=compiler /tmp/create_user /usr/local/bin/create_user
RUN chown root:root /usr/local/bin/create_user \
    && chmod u=rws,g=x,o=- /usr/local/bin/create_user

# Copy our entry point script (signal wrapper)
COPY run.sh /run.sh
ENTRYPOINT ["/bin/bash", "/run.sh"]

# By default, run a shell when no command is specified on the docker command line
CMD ["/bin/bash"]

WORKDIR /data/riotbuild
