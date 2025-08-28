FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=$CARGO_HOME/bin:$PATH
ENV BAT_CONFIG_DIR=/etc/bat
ENV BAT_USER_CONFIG_DIR=/root/.config/bat

RUN dpkg --add-architecture amd64 && apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    less \
    xclip \
    fzf \
    ripgrep \
    fd-find \
    pkg-config \
    build-essential \
    libssl-dev \
    cmake \
    && ln -s "$(which fdfind)" /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain 1.74.0 \
    && rustup component add rustfmt

RUN apt-get update && apt-get install -y --no-install-recommends bat \
    && rm -rf /var/lib/apt/lists/*

# Verify bat version >= 0.25.0; if default apt package is older, install latest .deb from github releases
RUN BAT_VERSION=$(bat --version | awk '{print $2}') && \
    dpkg --compare-versions "$BAT_VERSION" "ge" "0.25.0" || ( \
    curl -Lo /tmp/bat.deb https://github.com/sharkdp/bat/releases/download/v0.25.0/bat_0.25.0_amd64.deb && \
    apt-get update && apt-get install -y /tmp/bat.deb && rm -rf /var/lib/apt/lists/* /tmp/bat.deb )

WORKDIR /app

COPY Cargo.toml Cargo.lock /app/
COPY rustfmt.toml /app/
COPY tests/syntax-tests/source/TOML/Cargo.toml /app/tests/syntax-tests/source/TOML/
COPY . .

RUN cargo build --release
RUN ./target/release/bat cache --build

# Create system-wide bat config directory and default config with pager settings
RUN mkdir -p $BAT_CONFIG_DIR && echo "pager = \"less\"" > $BAT_CONFIG_DIR/config

# Create default user config directory and config file
RUN mkdir -p $BAT_USER_CONFIG_DIR && echo "[bat]\npager = \"less\"" > $BAT_USER_CONFIG_DIR/config

ENV RUST_BACKTRACE=1

CMD ["/bin/bash"]