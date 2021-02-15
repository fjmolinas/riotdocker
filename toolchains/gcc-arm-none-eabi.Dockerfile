ARG DOCKERHUB_USERNAME="riot"
FROM ${DOCKERHUB_USERNAME}/gcc-arm-none-eabi-lite as gcc-arm-none-eabi
FROM ${DOCKERHUB_USERNAME}/riotbuild-essentials

LABEL maintainer="francois-xavie.molina@inria.fr"

# Install ARM GNU embedded toolchain
ARG ARM_FOLDER=gcc-arm-none-eabi
RUN mkdir -p /opt/${ARM_FOLDER}
COPY --from=gcc-arm-none-eabi /opt/${ARM_FOLDER} /opt/${ARM_FOLDER}
# Add to PATH
ENV PATH ${PATH}:/opt/${ARM_FOLDER}/bin

RUN echo 'Building and Installing PicoLIBC for arm' >&2 &&  \
    cd /usr/src/picolibc && \
    mkdir build-arm && \
    cd build-arm && \
    sh ../do-arm-configure && \
    ninja && ninja install && \
    rm -rf /usr/src/picolibc
