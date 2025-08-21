FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=cc
ENV HOME=/home/${USER}
ENV PATH=$HOME/.cargo/bin:$PATH
WORKDIR /home/cc/EnvGym/data/sharkdp_bat

# Install system dependencies and tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      git \
      less \
      fzf \
      xclip \
      ripgrep \
      fd-find \
      ninja-build \
      libonig-dev \
      libgit2-dev \
      build-essential \
      pkg-config \
      libz-dev \
      clang \
      coreutils \
      zsh \
      fish \
      sudo \
      locales \
      bash-completion \
      gcc \
      libssl-dev \
      python3 \
      python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Set UTF-8 locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create non-root user and set ownership
RUN useradd -m -u 1000 ${USER} && \
    usermod -aG sudo ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Ensure HOME is set correctly and ownership is correct
RUN chown -R ${USER}:${USER} /home/${USER}

USER ${USER}

ENV HOME=/home/cc
WORKDIR /home/cc

# Debug: check home directory ownership and permissions before rustup install
RUN echo $HOME && ls -ld $HOME && ls -l $HOME

# Install Rust toolchain with rustup (fix install method, ensure environment, set CARGO_HOME and RUSTUP_HOME)
ENV CARGO_HOME=$HOME/.cargo
ENV RUSTUP_HOME=$HOME/.rustup
RUN curl -v --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path

# Ensure $HOME/.cargo/bin is in PATH for this RUN and subsequent commands
ENV PATH=$HOME/.cargo/bin:$PATH

# Install cargo-based developer tools (split to identify which fails)
RUN $HOME/.cargo/bin/cargo install --locked cargo-audit
# Removed problematic cargo install nix step

# Clone bat repository with submodules
RUN git clone --recursive https://github.com/sharkdp/bat $HOME/bat

WORKDIR $HOME/bat

# Ensure build/main.rs exists (noop if present)
RUN mkdir -p build && touch build/main.rs

# Build the project and run tests
RUN $HOME/.cargo/bin/cargo build --bins --locked
RUN $HOME/.cargo/bin/cargo test --locked

# Install binary locally for user
RUN $HOME/.cargo/bin/cargo install --path . --locked

# Generate default bat config
RUN mkdir -p $HOME/.config/bat && \
    $HOME/.cargo/bin/bat --generate-config-file || true

# Add shell aliases (example for bash/zsh/fish)
RUN echo 'alias bat="batcat"' >> $HOME/.bashrc && \
    echo 'alias bat="batcat"' >> $HOME/.zshrc && \
    mkdir -p $HOME/.config/fish && \
    echo 'alias bat "batcat"' >> $HOME/.config/fish/config.fish

# Set BAT environment variables in bashrc/zshrc/fish config (optional)
RUN echo 'export BAT_THEME="TwoDark"' >> $HOME/.bashrc && \
    echo 'export BAT_STYLE="numbers,changes,header"' >> $HOME/.bashrc && \
    echo 'export BAT_PAGER="less -RF"' >> $HOME/.bashrc && \
    echo 'export BAT_THEME="TwoDark"' >> $HOME/.zshrc && \
    echo 'export BAT_STYLE="numbers,changes,header"' >> $HOME/.zshrc && \
    echo 'export BAT_PAGER="less -RF"' >> $HOME/.zshrc && \
    echo 'set -x BAT_THEME "TwoDark"' >> $HOME/.config/fish/config.fish && \
    echo 'set -x BAT_STYLE "numbers,changes,header"' >> $HOME/.config/fish/config.fish && \
    echo 'set -x BAT_PAGER "less -RF"' >> $HOME/.config/fish/config.fish

WORKDIR /home/cc/EnvGym/data/sharkdp_bat

CMD ["/bin/bash"]