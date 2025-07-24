FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN set -ex && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        g++ \
        gcc \
        cmake \
        git \
        python3.10 \
        python3.10-venv \
        python3-pip \
        pkg-config \
        make \
        valgrind \
        lcov \
        cppcheck \
        gdb \
        wget \
        unzip \
        zeal \
        ca-certificates \
        libssl-dev \
        locales \
        libffi-dev \
        curl \
        zip && \
    ln -sf /usr/bin/python3.10 /usr/local/bin/python3 && \
    python3 -m pip install --upgrade pip && \
    rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN mkdir -p /home/cc/EnvGym/data/nlohmann_json
WORKDIR /home/cc/EnvGym/data/nlohmann_json

RUN set -ex && \
    wget -O /tmp/mkcert https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64 && \
    chmod +x /tmp/mkcert && \
    mv /tmp/mkcert /usr/local/bin/mkcert && \
    mkcert -install

# Install vcpkg (clone and bootstrap) and conan, with additional diagnostics
RUN set -ex && \
    git clone --depth 1 https://github.com/microsoft/vcpkg.git /opt/vcpkg && \
    ls -l /opt/vcpkg/ && \
    test -x /opt/vcpkg/bootstrap-vcpkg.sh && \
    /opt/vcpkg/bootstrap-vcpkg.sh || (ls -l /opt/vcpkg/; cat /opt/vcpkg/bootstrap*.log || true; exit 1)
RUN python3 -m pip install conan

ENV PATH="/opt/vcpkg:${PATH}"

RUN set -ex && /opt/vcpkg/vcpkg install doctest

RUN set -ex && /opt/vcpkg/vcpkg install nlohmann-json

RUN python3 -m pip install meson && \
    git clone --depth 1 https://github.com/spack/spack.git /opt/spack

RUN python3 -m pip install mkdocs mkdocs-material

RUN python3 -m pip install PyYAML watchdog

RUN mkdir -p /root/.gdbinit.d

WORKDIR /home/cc/EnvGym/data/nlohmann_json

ENTRYPOINT ["/bin/bash"]