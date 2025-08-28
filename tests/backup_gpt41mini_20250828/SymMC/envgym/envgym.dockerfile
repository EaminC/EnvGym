FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

WORKDIR /SymMC

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      software-properties-common \
      pkg-config \
      libboost-dev \
      libc++-dev \
      libreadline-dev \
      libncurses-dev \
      gcc \
      g++ \
      openjdk-8-jdk \
      ant \
      build-essential \
      cmake \
      git \
      bash \
      wget \
      ca-certificates \
      unzip \
      libtinfo-dev \
      libncurses5-dev \
      libssl-dev \
      zlib1g-dev \
      libboost-system-dev \
      libboost-filesystem-dev \
      libboost-thread-dev \
      libboost-chrono-dev \
      libz-dev \
      libgmp-dev \
      pkg-config \
      libstdc++-10-dev \
      libboost-all-dev \
      ninja-build && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

RUN git clone https://github.com/niklasso/minisat.git /tmp/minisat && \
    cd /tmp/minisat && \
    git fetch --all && \
    git checkout 2e6f5f2d0b1c2e6a0f9a3a6bc9d9d8fa9b1e1a3d || git checkout master && \
    mkdir -p build && \
    cd build && \
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=11 .. && \
    ninja && \
    test -f minisat && \
    cp minisat /usr/local/bin/ && \
    rm -rf /tmp/minisat

RUN minisat --version || true

RUN mkdir -p Enhanced_Kodkod && \
    echo '#!/bin/bash\nant compile' > Enhanced_Kodkod/build.sh && \
    chmod +x Enhanced_Kodkod/build.sh && \
    echo '#!/bin/bash\n\ncurrentdir="$(dirname "$(realpath $0)")"\n\nspecfile=$1\nsatfile=$2\nsymfile=$3\n\njava -cp "$currentdir/src:$currentdir/bin:$currentdir/lib/org.alloytools.alloy.dist.jar" edu.mit.csail.sdg.alloy4whole.ExampleUsingTheCompiler "$specfile" "$satfile" "$symfile"' > Enhanced_Kodkod/run.sh && \
    chmod +x Enhanced_Kodkod/run.sh

RUN mkdir -p Enumerator_Estimator && \
    echo '#!/bin/bash\nmkdir -p cmake-build-release && cd cmake-build-release && cmake .. && make' > Enumerator_Estimator/build.sh && \
    chmod +x Enumerator_Estimator/build.sh

RUN echo "Enumerator_Estimator/cmake-build-release/\nEnhanced_Kodkod/bin/\n**/.idea/\n# .project\n# .classpath\n# .settings/" > .gitignore

RUN echo '#!/bin/bash\n\nexport JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64\nexport PATH=$JAVA_HOME/bin:$PATH\n# Ant installed via package manager, bin already in PATH\n# MiniSat binary installed to /usr/local/bin, already in PATH\n' > env_setup.sh && \
    chmod +x env_setup.sh

WORKDIR /SymMC

CMD ["/bin/bash"]