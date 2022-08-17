FROM ubuntu:22.04 AS builder

WORKDIR build_slats
RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install curl git build-essential && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --default-toolchain 1.63.0 -y && \
    export PATH=$PATH:$HOME/.cargo/bin && \
    bash $HOME/.cargo/env
RUN mkdir git && \
    cd git && \
    git clone https://github.com/broadinstitute/slats.git && \
    cd slats && \
    git checkout v0.1.0  && \
    export PATH=$PATH:$HOME/.cargo/bin && \
    cargo install --path . --root /usr/local && \
    cd ../..  && \
    rm -r git

FROM ubuntu:22.04

RUN apt-get -y update && \
    apt-get -y upgrade && \
    rm -rf /var/lib/apt/lists/*
COPY --from=builder /usr/local/bin/slats /usr/local/bin/slats
