# syntax=docker/dockerfile:1.6

#########################
# BUILD STAGE
#########################
FROM --platform=linux/amd64 ubuntu:22.04 AS build

ARG DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libtool \
        autoconf \
        automake \
        git \
        flex \
        bison \
        python3 \
        python3-pip \
        pipenv \
        ca-certificates \
        wget \
        curl && \
    rm -rf /var/lib/apt/lists/*

# Set consistent working directory
WORKDIR /home/cc/EnvGym/data/jqlang_jq

# Clone jq source (latest)
RUN git clone --depth=1 https://github.com/jqlang/jq.git . && \
    git submodule update --init

# (Optional) Set up Python env for docs if needed (commented out)
# WORKDIR /home/cc/EnvGym/data/jqlang_jq/docs
# RUN pipenv install --deploy --ignore-pipfile

WORKDIR /home/cc/EnvGym/data/jqlang_jq

# Generate build system (autoreconf) if building from git
RUN autoreconf -i

# Configure for static build with builtin oniguruma, disable docs
RUN ./configure \
    --with-oniguruma=builtin \
    --enable-static \
    --enable-all-static \
    --prefix=/usr/local \
    --disable-docs

# Build (multi-core), log build output
RUN make -j$(nproc) | tee build.log
RUN cat build.log

# Test, log test output
RUN make check VERBOSE=yes | tee test.log
RUN cat test.log

# Install to staging directory
RUN make install-strip

#########################
# FINAL MINIMAL IMAGE
#########################
FROM --platform=linux/amd64 scratch AS final

# Copy jq binary and licenses from build stage
COPY --from=build /usr/local/bin/jq /jq
COPY --from=build /home/cc/EnvGym/data/jqlang_jq/AUTHORS /AUTHORS
COPY --from=build /home/cc/EnvGym/data/jqlang_jq/COPYING /COPYING

# Set working directory for consistency (though not really needed in scratch)
WORKDIR /home/cc/EnvGym/data/jqlang_jq

# Set entrypoint
ENTRYPOINT ["/jq"]

# Default to showing version if no args
CMD ["--version"]