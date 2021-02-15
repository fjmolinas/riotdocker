ARG DOCKERHUB_USERNAME="riot"
FROM ${DOCKERHUB_USERNAME}/static-test-tools

LABEL maintainer="francois-xavier.molina@inria.fr"

RUN \
    echo 'Update the package index files to latest available versions' >&2 && \
    apt-get update && \
    echo 'Installing riot-build-essentials' >&2 && \
    apt-get -y --no-install-recommends install \
        # required by RIOT build system
        unzip \
        curl \
        # for building many packades
        g++ \
        # required for hexdump
        bsdmainutils \
         # required for xxd
        vim-common \
        cmake \
        patch \
        # To install python packages (next two)
        python3-setuptools \
        python3-wheel \
        # For nanopb
        protobuf-compiler \
        # For picolibc
        ninja-build \
        && \
    echo 'Cleaning up installation files' >&2 && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install required Python packages
COPY requirements.txt /tmp/requirements.txt
# numpy must be already installed before installing other requirements
RUN pip3 install --no-cache-dir numpy==1.17.4
RUN echo 'Installing python3 packages' >&2 && \
    pip3 install --no-cache-dir -r /tmp/requirements.txt && \
    rm -f /tmp/requirements.txt

ARG PICOLIBC_REPO=https://github.com/keith-packard/picolibc
ARG PICOLIBC_TAG=1.4.6
ARG PICOLIBC_URL=${PICOLIBC_REPO}/archive/${PICOLIBC_TAG}.tar.gz
ARG PICOLIBC_ARCHIVE=${PICOLIBC_TAG}.tar.gz

# Bootstrap PicoLIBC, configuratoin will happen for each toolchain
RUN echo 'Bootstraping PicoLIBC' >&2 && \
    pip3 install --no-cache-dir meson && \
    mkdir -p /usr/src/picolibc && \
    cd /usr/src/picolibc/ &&\
    curl -L -o ${PICOLIBC_ARCHIVE} ${PICOLIBC_URL} && \
    tar -xf ${PICOLIBC_ARCHIVE} --strip-components=1
