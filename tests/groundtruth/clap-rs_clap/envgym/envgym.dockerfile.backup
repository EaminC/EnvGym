FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=$CARGO_HOME/bin:$PATH

WORKDIR /home/cc/EnvGym/data/clap-rs_clap

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl \
      ca-certificates \
      build-essential \
      pkg-config \
      libssl-dev \
      libsqlite3-dev \
      libgit2-dev \
      python3 \
      python3-pip \
      git \
      bash \
      zsh \
      fish \
      groff \
      man \
      locales \
      sudo && \
    rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN curl -sSfL https://github.com/nushell/nushell/releases/download/0.93.1/nu-0.93.1-x86_64-unknown-linux-gnu.tar.gz | \
      tar xz --strip-components=1 -C /usr/local/bin nu && \
    chmod +x /usr/local/bin/nu || true

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.74.0 && \
    $CARGO_HOME/bin/rustup component add rustfmt clippy

RUN $CARGO_HOME/bin/rustup target add x86_64-unknown-linux-gnu

RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install pre-commit committed

COPY . /home/cc/EnvGym/data/clap-rs_clap

RUN $CARGO_HOME/bin/cargo --version
RUN $CARGO_HOME/bin/cargo install --list
RUN echo $PATH
RUN ls -l $CARGO_HOME/bin

RUN apt-get update && apt-get install -y pkg-config libssl-dev libgit2-dev

RUN $CARGO_HOME/bin/cargo search cargo-deny

# Attempt to install cargo-deny with --locked; if it fails, try a pinned older version, capturing error logs
RUN $CARGO_HOME/bin/cargo install cargo-deny --locked -v || \
    $CARGO_HOME/bin/cargo install cargo-deny --version 0.14.19 --locked -v

# Attempt to install typos-cli with --locked and fallback to a pinned older version if needed
RUN $CARGO_HOME/bin/cargo install typos-cli --locked -v || \
    $CARGO_HOME/bin/cargo install typos-cli --version 1.16.7 --locked -v

# Attempt to install cargo-release with --locked; if it fails, try a pinned older version
RUN $CARGO_HOME/bin/cargo install cargo-release --locked -v || \
    $CARGO_HOME/bin/cargo install cargo-release --version 0.24.8 --locked -v

RUN $CARGO_HOME/bin/cargo search cargo-tarpaulin

# Attempt to install cargo-tarpaulin with --locked and fallback to a pinned older version if needed
RUN $CARGO_HOME/bin/cargo install cargo-tarpaulin --locked -v || \
    $CARGO_HOME/bin/cargo install cargo-tarpaulin --version 0.27.3 --locked -v

RUN git config --global core.filemode true

CMD ["/bin/bash", "-c", "rustc --version && cargo --version && python3 --version && git --version && echo 'Container ready. Use bash to enter.' && bash"]