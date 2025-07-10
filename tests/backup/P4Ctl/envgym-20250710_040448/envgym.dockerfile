FROM --platform=linux/amd64 ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

ARG SDE_VERSION=9.7.0
ARG PROJECT_ROOT=/home/cc/EnvGym/data/P4Ctl

# Add deadsnakes PPA for Python 3.7
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update

# Install Python 3.7 and dependencies in separate steps to isolate errors
RUN apt-get install -y python3.7 python3.7-venv python3.7-dev python3-pip || \
    (apt-get update && apt-get install -y python3.7 python3.7-venv python3.7-dev python3-pip)

# Install system build tools and utilities (split for debugging)
RUN apt-get install -y build-essential gcc make
RUN apt-get install -y bison flex
RUN apt-get install -y ncat
RUN apt-get install -y git
RUN apt-get install -y tmux screen
RUN apt-get install -y wget curl ca-certificates
RUN apt-get install -y libbpf-dev libelf-dev libz-dev pkg-config cmake libssl-dev libcap-dev python3-setuptools python3-wheel sudo

# bpftool installation omitted due to package install failure

RUN rm -rf /var/lib/apt/lists/*

RUN python3.7 -m pip install --upgrade pip && \
    python3.7 -m pip install scapy==2.4.5 pyroute2 bcc virtualenv

RUN mkdir -p ${PROJECT_ROOT}
WORKDIR ${PROJECT_ROOT}

# Copy project source code into the container
COPY . ${PROJECT_ROOT}

ENV SDE=${HOME}/bf-sde-${SDE_VERSION}/
ENV SDE_INSTALL=${HOME}/bf-sde-${SDE_VERSION}/install
ENV PATH=$SDE_INSTALL/bin:$PATH

RUN echo "export SDE=${HOME}/bf-sde-${SDE_VERSION}/" >> ${HOME}/.bashrc && \
    echo "export SDE_INSTALL=${HOME}/bf-sde-${SDE_VERSION}/install" >> ${HOME}/.bashrc && \
    echo "export PATH=\$SDE_INSTALL/bin:\$PATH" >> ${HOME}/.bashrc

RUN python3.7 -m venv ${PROJECT_ROOT}/venv

# Build NetCL compiler
RUN make -C compiler/ netcl

# Ensure scripts and executables are marked as executable
RUN find ${PROJECT_ROOT} -type f -name "*.sh" -exec chmod +x {} \; || true && \
    find ${PROJECT_ROOT} -type f -name "netcl-compile" -exec chmod +x {} \; || true

EXPOSE 9999

ENTRYPOINT ["/bin/bash"]