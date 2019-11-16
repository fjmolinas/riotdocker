# Compile suid and create_user binary
FROM gcc:8.3.0 AS compiler
COPY create_user.c /tmp/create_user.c
RUN gcc -DHOMEDIR=\'/data/riotbuild\' -DUSERNAME=\'riotbuild\' /tmp/create_user.c -o /tmp/create_user \
    && rm /tmp/create_user.c

FROM ubuntu:bionic

ENV DEBIAN_FRONTEND noninteractive
ARG FLASH_DEPS="make unzip"

ARG EDBG_INSTALL_DEPS="wget ca-certificates"

ARG JLINK_VERSION=654c
ARG JLINK_DEPS=""

# Upgrading system packages to the latest available versions
RUN apt-get update && apt-get -y dist-upgrade
# Installing required packages for flashing toolchain
RUN apt-get -y --no-install-recommends install \
        ${JLINK_DEPS} \
        ${EDBG_INSTALL_DEPS} \
        ${FLASH_DEPS} \
    # Cleaning up installation files
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Jlink
RUN wget --post-data 'accept_license_agreement=accepted&non_emb_ctr=confirmed&submit="Download software"'\
    https://www.segger.com/downloads/jlink/JLink_Linux_V${JLINK_VERSION}_x86_64.deb \
    && dpkg --install JLink_Linux_V${JLINK_VERSION}_x86_64.deb \
    && rm JLink_Linux_V${JLINK_VERSION}_x86_64.deb

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
