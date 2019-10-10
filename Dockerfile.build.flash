FROM riot/riotbuild:latest

# TODO
#       - Do not show messages of stages in errors
#       - List dependencies by toolchain with a variable

# Common tools
RUN echo 'Upgrading system packages to the latest available versions' >&2 && \
    apt-get update && apt-get -y dist-upgrade \
    && echo 'Installing required packages for flashing toolchain' >&2 && \
    apt-get -y --no-install-recommends install \
        automake \
        autoconf \
        ca-certificates \
        cmake \
        curl \
        git \
        libhidapi-hidraw0 \
        libhidapi-dev \
        libreadline-dev \
        libtool \
        libusb-1.0 \
        libudev-dev \
        libusb-dev \
        make \
        pkg-config \
        python \
        python3 \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python-serial \
        p7zip \
        socat \
        usbutils \
        unzip \
        wget \
    && echo 'Installing avrdude' >&2 && \
    apt-get -y --no-install-recommends install \
        avrdude \
    # Installing uniflash dependenices
    && apt-get -y --no-install-recommends install \
        libnotify4 \
        libcanberra0 \
        libpython2.7 \
    && echo 'Cleaning up installation files' >&2 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Build openocd from source
RUN echo 'Building openocd from source' >&2\
    && mkdir -p opt \
    && cd /opt \
    && git clone --depth 1 git://git.code.sf.net/p/openocd/code openocd\
    && cd openocd \
    && ./bootstrap \
    && ./configure --enable-stlink --enable-jlink --enable-ftdi --enable-cmsis-dap \
    && make -j"$(nproc)" \
    && make install-strip \
    && cd .. \
    && rm -rf openocd \
    && rm -rf /var/lib/apt/lists/*

# Build mspdebug
RUN echo 'Building mspdebug from source' >&2\
    && mkdir -p opt \
    && cd /opt \
    && git clone --depth 1 https://github.com/dlbeer/mspdebug \
    && cd mspdebug \
    && make -j"$(nproc)" \
    && make install \
    && cd .. \
    && rm -rf mspdebug \
    && rm -rf /var/lib/apt/lists/*

# Install pyocd
RUN echo 'Installing pyocd packages' >&2 \
    && pip3 install --no-cache-dir pyocd

# Install esptool
RUN echo 'Installing esptool packages' >&2 \
    && pip3 install --no-cache-dir esptool

# HACK, currently it is using the one in esptoolchain by default, we do not
# esptoolchain in this image
ENV ESPTOOL esptool.py

# Install edbg
RUN echo 'Building edbg from source' >&2\
    && mkdir -p opt \
    && cd /opt \
    && git clone --depth 1 https://github.com/ataradov/edbg \
    && cd edbg \
    && make -j"$(nproc)" \
    && make all \
    && cp edbg /usr/local/bin/edbg \
    && cd .. \
    && rm -rf edbg \
    && rm -rf /var/lib/apt/lists/*

# Install jlink
# It should be queried with a 'POST' that accepts the ULA
RUN echo 'Installing Jlink' >&2\
    && wget --quiet --post-data 'accept_license_agreement=accepted&non_emb_ctr=confirmed&submit="Download software"'\
        https://www.segger.com/downloads/jlink/JLink_Linux_V650b_x86_64.deb \
    && dpkg --install JLink_Linux_V650b_x86_64.deb \
    && rm JLink_Linux_V650b_x86_64.deb

# Install uniflash
RUN echo 'Installing uniflash' >&2 \
    && wget --quiet http://software-dl.ti.com/ccs/esd/uniflash/uniflash_sl.4.6.0.2176.run \
    && chmod +x uniflash_sl.4.6.0.2176.run \
    && ./uniflash_sl.4.6.0.2176.run --prefix /opt/ti/uniflash --mode unattended \
    && rm uniflash_sl.4.6.0.2176.run

ENV UNIFLASH_PATH /opt/ti/uniflash


# Set a global system-wide git user and email address
RUN git config --system user.name "riot" && \
    git config --system user.email "riot@example.com"

# compile suid create_user binary
COPY create_user.c /tmp/create_user.c
RUN gcc -DHOMEDIR=\"/data/riotbuild\" -DUSERNAME=\"riotbuild\" /tmp/create_user.c -o /usr/local/bin/create_user \
    && chown root:root /usr/local/bin/create_user \
    && chmod u=rws,g=x,o=- /usr/local/bin/create_user \
    && rm /tmp/create_user.c

# Copy our entry point script (signal wrapper)
COPY run.sh /run.sh
ENTRYPOINT ["/bin/bash", "/run.sh"]

# By default, run a shell when no command is specified on the docker command line
CMD ["/bin/bash"]

WORKDIR /data/riotbuild
