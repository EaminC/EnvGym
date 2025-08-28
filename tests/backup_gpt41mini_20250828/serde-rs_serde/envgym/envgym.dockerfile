FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV RUST_BACKTRACE=1
ENV PATH="/root/.cargo/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/serde-rs_serde

COPY . /home/cc/EnvGym/data-gpt-4.1mini/serde-rs_serde

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && rustup default stable \
    && rustup target add x86_64-unknown-linux-gnu

SHELL ["/bin/bash", "-c"]

RUN curl -L https://github.com/rust-lang/rust-analyzer/releases/latest/download/rust-analyzer-linux -o /usr/local/bin/rust-analyzer \
    && chmod +x /usr/local/bin/rust-analyzer

RUN mkdir -p .cargo && \
    echo '[build]\nrustflags = []\n[features]\ndefault = []\n\n[dependencies.serde_derive]\ndefault-features = false\nfeatures = ["proc-macro"]\n\n[dependencies.serde]\ndefault-features = false\nfeatures = ["derive"]\n\n[dependencies.proc-macro2]\ndefault-features = false\nfeatures = ["span-locations"]\n\n[dependencies.quote]\ndefault-features = false\n\n[dependencies.syn]\ndefault-features = false\nfeatures = ["full"]\n\n[dependencies.libc]\ndefault-features = false\n' > .cargo/config.toml

RUN echo 'target/\n**/*.rs.bk\nCargo.lock\n' > .gitignore

RUN echo '# Optional rustfmt config' > rustfmt.toml && \
    echo '# Optional clippy config' > clippy.toml && \
    echo '# crates-io.md placeholder' > crates-io.md

RUN chown -R root:root /home/cc/EnvGym/data-gpt-4.1mini/serde-rs_serde

RUN ls -lah && ls -lah serde && ls -lah serde_derive && ls -lah serde_derive_internals && ls -lah test_suite

RUN test -f Cargo.toml && test -d serde && test -d serde_derive && test -d serde_derive_internals && test -d test_suite

RUN ls -lah serde_derive/build.rs || echo "No build.rs in serde_derive" && \
    ls -lah serde_derive_internals/build.rs || echo "No build.rs in serde_derive_internals"

RUN test -f serde/build.rs

RUN rustc --version && cargo --version

RUN cargo check --workspace --verbose || { echo "Cargo check failed. Showing logs:"; cat target/debug/deps/*.log || true; exit 1; }

RUN cargo clean

RUN cargo build --workspace --jobs $(nproc) --verbose

RUN cargo test --workspace --jobs $(nproc) --verbose

CMD ["/bin/bash"]