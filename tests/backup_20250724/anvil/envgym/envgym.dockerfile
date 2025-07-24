FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

WORKDIR /home/cc/EnvGym/data/anvil

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        build-essential \
        git \
        pkg-config \
        libssl-dev \
        python3 \
        python3-pip \
        bash \
        wget \
        unzip \
        software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl (amd64)
RUN curl -fsSL -o /usr/local/bin/kubectl https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Install Minikube (amd64)
RUN curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
    install minikube /usr/local/bin/ && \
    rm minikube

# Install Rustup (and toolchain 1.88.0, x86_64)
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --profile minimal --default-toolchain 1.88.0 && \
    chmod -R a+w $CARGO_HOME $RUSTUP_HOME

# Ensure correct toolchain is installed and available
RUN rustup default 1.88.0 && \
    rustup target add x86_64-unknown-linux-gnu && \
    rustc --version && cargo --version

# Install Python dependencies
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install tabulate

# (Optional) Copy project files
# COPY . /home/cc/EnvGym/data/anvil

# Set default shell
SHELL ["/bin/bash", "-c"]

# Set environment variable for locale if needed
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# Verus Installation (assume sources are in /home/cc/EnvGym/data/verus/source)
# Adjust the following lines according to the Verus installation instructions
# (If Verus must be installed globally, uncomment and adjust these lines)
# RUN git clone https://github.com/verus-lang/verus.git /home/cc/EnvGym/data/verus/source
# RUN cd /home/cc/EnvGym/data/verus/source && \
#     cargo build --release

# Entrypoint
CMD ["/bin/bash"]