ARG DOCKERHUB_USERNAME="riot"
FROM ${DOCKERHUB_USERNAME}/riotdocker-base
LABEL maintainer="francois-xavie.molina@inria.fr"

# Dependencies to install gcc-arm-none-eabi
ARG ARM_INSTALL_DEPS="curl bzip2"
# Dependencies to compile gcc-arm-none-eabi
ARG ARM_BUILD_DEPS="make unzip"

# Upgrading system packages to the latest available versions
RUN apt-get update && apt-get -y dist-upgrade
# Installing required packages for flashing toolchain
RUN apt-get -y --no-install-recommends install \
        ${ARM_INSTALL_DEPS} \
        ${ARM_BUILD_DEPS} \
    # Cleaning up installation files
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install ARM GNU embedded toolchain
# For updates, see https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads
ARG ARM_VESION=gcc-arm-none-eabi-9-2019-q4-major
ARG ARM_URLBASE=https://developer.arm.com/-/media/Files/downloads/gnu-rm
ARG ARM_URL=${ARM_URLBASE}/9-2019q4/${ARM_VESION}-\$\{ARCH\}-linux.tar.bz2
ARG TARGETPLATFORM
ENV TARGETPLATFORM=${TARGETPLATFORM:-linux/amd64}
RUN echo 'Installing arm-none-eabi toolchain from arm.com' >&2 && \
    if [ "${TARGETPLATFORM}" = "linux/amd64" ] ; \
        then export ARCH="x86_64"; export ARM_MD5=fe0029de4f4ec43cf7008944e34ff8cc; \
    elif [ "${TARGETPLATFORM}" = "linux/arm64" ] ; \
        then export ARCH="aarch64"; export ARM_MD5=0dfa059aae18fcf7d842e30c525076a4;  \
    fi && \
    mkdir -p /opt/gcc-arm-none-eabi && \
    curl -L -o /opt/gcc-arm-none-eabi.tar.bz2 ${ARM_URLBASE}/9-2019q4/${ARM_VESION}-${ARCH}-linux.tar.bz2 && \
    echo "${ARM_MD5} /opt/gcc-arm-none-eabi.tar.bz2" | md5sum -c && \
    tar -C /opt/gcc-arm-none-eabi -jxf /opt/gcc-arm-none-eabi.tar.bz2 --strip-components=1 && \
    rm -f /opt/gcc-arm-none-eabi.tar.bz2 && \
    echo 'Removing documentation' >&2 && \
    ls -la /opt/gcc-arm-none-eabi/ && \
    rm -rf /opt/gcc-arm-none-eabi/share/doc
    # No need to dedup, the ARM toolchain is already using hard links for the duplicated files

ENV PATH ${PATH}:/opt/gcc-arm-none-eabi/bin
