FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      openjdk-8-jdk \
      ant \
      cmake \
      build-essential \
      git \
      python3 \
      wget \
      unzip \
      ca-certificates \
      libz-dev \
      g++ \
      make && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:/usr/bin/ant:$PATH"

RUN useradd -ms /bin/bash cc
RUN mkdir -p /home/cc/EnvGym/data/SymMC
RUN chown -R cc:cc /home/cc

USER cc
WORKDIR /home/cc/EnvGym/data/SymMC

RUN git clone https://github.com/niklasso/minisat.git /home/cc/minisat && \
    cd /home/cc/minisat && \
    git submodule update --init --recursive || true && \
    ls -l && \
    (cat README.md || true) && \
    make clean || true && \
    make -j$(nproc) > minisat_build.log 2>&1 || ( \
        echo "MiniSat build failed. Directory listing:"; ls -l; \
        echo "Makefile contents:"; cat Makefile || true; \
        echo "README.md:"; cat README.md || true; \
        echo "Last 50 lines of minisat_build.log:"; tail -n 50 minisat_build.log || true; \
        cat minisat_build.log || true; \
        exit 1) && \
    cat minisat_build.log || true

RUN if [ -f /home/cc/minisat/build/release/bin/minisat ]; then \
      ln -sf /home/cc/minisat/build/release/bin/minisat /home/cc/minisat/minisat-bin; \
    elif [ -f /home/cc/minisat/minisat ]; then \
      ln -sf /home/cc/minisat/minisat /home/cc/minisat/minisat-bin; \
    fi
ENV PATH="/home/cc/minisat/build/release/bin:/home/cc/minisat:${PATH}"

COPY --chown=cc:cc . /home/cc/EnvGym/data/SymMC

RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> /home/cc/.profile && \
    echo "export PATH=\$JAVA_HOME/bin:/usr/bin/ant:\$PATH" >> /home/cc/.profile && \
    echo "export PATH=/home/cc/minisat/build/release/bin:/home/cc/minisat:\$PATH" >> /home/cc/.profile

RUN mkdir -p /home/cc/EnvGym/data/SymMC/test

SHELL ["/bin/bash", "-c"]
WORKDIR /home/cc/EnvGym/data/SymMC

RUN echo "=== Directory listing for Enhanced_Kodkod (parent) ===" && \
    ls -l && \
    echo "=== Directory listing for Enhanced_Kodkod ===" && \
    ls -l Enhanced_Kodkod && \
    echo "=== build.sh contents ===" && \
    cat Enhanced_Kodkod/build.sh || true && \
    chmod +x Enhanced_Kodkod/build.sh

RUN echo "=== Directory listing inside Enhanced_Kodkod ===" && ls -l Enhanced_Kodkod && \
    echo "=== Listing of Enhanced_Kodkod/src ===" && ls -l Enhanced_Kodkod/src || true && \
    echo "=== Listing of Enhanced_Kodkod/lib ===" && ls -l Enhanced_Kodkod/lib || true && \
    echo "=== Listing of Enhanced_Kodkod/util ===" && ls -l Enhanced_Kodkod/util || true && \
    echo "=== Listing of Enhanced_Kodkod/build.xml ===" && (cat Enhanced_Kodkod/build.xml || true)

RUN if [ ! -f Enhanced_Kodkod/build.sh ]; then \
      echo "build.sh missing in Enhanced_Kodkod!"; \
      ls -l Enhanced_Kodkod || true; \
      exit 1; \
    fi && \
    if [ ! -f Enhanced_Kodkod/build.xml ]; then \
      echo "build.xml missing in Enhanced_Kodkod!"; \
      ls -l Enhanced_Kodkod || true; \
      exit 1; \
    fi && \
    if [ ! -d Enhanced_Kodkod/src ]; then \
      echo "src directory missing in Enhanced_Kodkod!"; \
      ls -l Enhanced_Kodkod || true; \
      exit 1; \
    fi && \
    if [ ! -d Enhanced_Kodkod/lib ]; then \
      echo "lib directory missing in Enhanced_Kodkod!"; \
      ls -l Enhanced_Kodkod || true; \
      exit 1; \
    fi && \
    if [ ! -d Enhanced_Kodkod/util ]; then \
      echo "util directory missing in Enhanced_Kodkod!"; \
      ls -l Enhanced_Kodkod || true; \
      exit 1; \
    fi && \
    echo "All required files present in Enhanced_Kodkod." && \
    cd Enhanced_Kodkod && ./build.sh > build_sh_output.log 2>&1; \
    status=$?; \
    echo '=== Last 50 lines of build_sh_output.log ==='; \
    tail -n 50 build_sh_output.log || true; \
    cat build_sh_output.log || true; \
    if [ $status -ne 0 ]; then \
      echo '=== Enhanced_Kodkod build failed! ==='; \
      exit $status; \
    fi

RUN cd Enumerator_Estimator && ./build.sh > build_sh_output.log 2>&1 || ( \
      echo '=== Enumerator_Estimator build failed! ==='; \
      echo '=== Last 50 lines of build_sh_output.log ==='; \
      tail -n 50 build_sh_output.log || true; \
      cat build_sh_output.log || true; \
      exit 1)

RUN cat Enumerator_Estimator/build_sh_output.log || true

ENTRYPOINT ["/bin/bash"]