FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV USER=cc
ENV HOME=/home/cc

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        build-essential \
        pkg-config \
        musl-tools \
        libpcre2-dev \
        binutils \
        python3 \
        dpkg-dev \
        grep \
        silversearcher-ag \
        sift \
        ugrep \
        bash-completion \
        zsh \
        fish \
        sudo \
        locales \
        cmake \
        libssl-dev \
        pkg-config \
        openssl \
    && rm -rf /var/lib/apt/lists/*

RUN ARCH=amd64 && \
    PT_VERSION=2.2.0 && \
    curl -sSL -o /tmp/pt_linux.tar.gz https://github.com/monochromegane/the_platinum_searcher/releases/download/v${PT_VERSION}/pt_linux_${ARCH}.tar.gz && \
    tar -xzf /tmp/pt_linux.tar.gz -C /tmp && \
    sudo mv /tmp/pt_linux_${ARCH}/pt /usr/local/bin/pt && \
    sudo chmod +x /usr/local/bin/pt && \
    rm -rf /tmp/pt_linux*

RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8

RUN useradd -ms /bin/bash $USER && \
    usermod -aG sudo $USER && \
    echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ENV RUSTUP_HOME=$HOME/.rustup
ENV CARGO_HOME=$HOME/.cargo
ENV PATH=$CARGO_HOME/bin:$PATH

USER $USER
WORKDIR $HOME

# Install Rust as user cc
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable && \
    $HOME/.cargo/bin/rustup update stable && \
    $HOME/.cargo/bin/rustup toolchain install 1.72.0 && \
    $HOME/.cargo/bin/rustup default 1.72.0 && \
    $HOME/.cargo/bin/rustup component add rustfmt

RUN mkdir -p $HOME/.cargo
RUN if [ ! -f $HOME/.cargo/config.toml ]; then \
        echo '[target.x86_64-unknown-linux-musl]' >> $HOME/.cargo/config.toml && \
        echo 'rustflags = ["-C", "target-feature=-crt-static"]' >> $HOME/.cargo/config.toml; \
    fi

RUN $HOME/.cargo/bin/rustup update && $HOME/.cargo/bin/cargo --version

ENV PKG_CONFIG_PATH=/usr/lib/x86_64-linux-gnu/pkgconfig

RUN which cargo && cargo --version

COPY --chown=cc:cc . $HOME/ripgrep

WORKDIR $HOME/ripgrep

# Debug: Check cargo environment before install
RUN which cargo && cargo --version
RUN cat $HOME/.cargo/env
RUN echo $PATH

# Try source if cargo is not found; show log if cargo-deb install fails
RUN source $HOME/.cargo/env && cargo install cargo-deb -v || cat $HOME/.cargo/.cargo-deb-install-log || true

RUN mkdir -p $HOME/.config/ripgrep && \
    echo '# Example ripgrep config' > $HOME/.config/ripgrep/config

RUN cargo build --release && \
    mkdir -p /usr/share/bash-completion/completions && \
    mkdir -p /usr/share/zsh/vendor-completions && \
    mkdir -p /usr/share/fish/vendor_completions.d && \
    ./target/release/rg --completion bash > /usr/share/bash-completion/completions/rg && \
    ./target/release/rg --completion zsh > /usr/share/zsh/vendor-completions/_rg && \
    ./target/release/rg --completion fish > /usr/share/fish/vendor_completions.d/rg.fish || true

WORKDIR $HOME/ripgrep

CMD ["/bin/bash"]