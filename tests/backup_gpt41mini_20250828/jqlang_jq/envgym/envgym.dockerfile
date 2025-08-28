FROM --platform=linux/amd64 debian:12-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8 LANG=C.UTF-8

WORKDIR /src

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    autoconf \
    automake \
    libtool \
    git \
    pkg-config \
    ca-certificates \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Clone jq repository and update submodules
RUN git clone https://github.com/jqlang/jq.git . && \
    git submodule update --init

# Prepare build system
RUN autoreconf -i

# Configure with required options
RUN ./configure --disable-docs --with-oniguruma=builtin --enable-static --enable-all-static --prefix=/usr/local

# Build with parallel jobs equal to available CPU cores
RUN make -j$(nproc)

# Run tests with verbose output
RUN make check VERBOSE=yes

# Install stripped binary and metadata files
RUN make install-strip

FROM scratch AS final

COPY --from=builder /usr/local/bin/jq /jq
COPY --from=builder /src/AUTHORS /AUTHORS
COPY --from=builder /src/COPYING /COPYING

ENTRYPOINT ["/jq"]
CMD ["--version"]