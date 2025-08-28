FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:/root/.local/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    ca-certificates \
    pkg-config \
    libssl-dev \
    fd-find \
    fzf \
    ripgrep \
    tree \
    parallel \
    rofi \
    make && \
    rm -rf /var/lib/apt/lists/*

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain 1.77.2 && \
    /usr/local/cargo/bin/rustup component add rustfmt

RUN mkdir -p /root/.local/bin

RUN if command -v fdfind >/dev/null 2>&1; then ln -sf $(command -v fdfind) /root/.local/bin/fd; else ln -sf $(command -v fd) /root/.local/bin/fd; fi

WORKDIR /fd

COPY . /fd

RUN touch rustfmt.toml

RUN /usr/local/cargo/bin/cargo install --path .

RUN mkdir -p /root/.config/fd && touch /root/.fdignore /root/.config/fd/ignore

RUN echo "export FZF_DEFAULT_COMMAND='fd --type file'" >> /root/.bashrc && \
    echo "export FZF_CTRL_T_COMMAND=\"\$FZF_DEFAULT_COMMAND\"" >> /root/.bashrc && \
    echo "export FZF_DEFAULT_OPTS='--ansi'" >> /root/.bashrc

RUN echo "alias fd='fdfind'" >> /root/.bashrc && \
    echo "alias as-tree='tree --fromfile'" >> /root/.bashrc

RUN dircolors -p > /root/.dircolors && \
    echo "eval \$(dircolors /root/.dircolors)" >> /root/.bashrc

SHELL ["/bin/bash", "-c"]
CMD ["/bin/bash"]