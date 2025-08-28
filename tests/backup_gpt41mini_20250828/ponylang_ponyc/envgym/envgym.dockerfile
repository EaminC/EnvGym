FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      clang \
      cmake \
      git \
      make \
      xz-utils \
      zlib1g-dev \
      python3-pip \
      bash \
      lldb && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1001 -s /bin/bash pony

WORKDIR /repo

COPY . /repo

RUN chown -R pony:pony /repo

USER pony

ENV PATH="/home/pony/.local/bin:/home/pony/.pony/bin:${PATH}"
ENV PONY_HOME="/home/pony/.pony"
ENV PONYC="$PONY_HOME/bin/ponyc"

SHELL ["/bin/bash", "-c"]

CMD ["bash"]