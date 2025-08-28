FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH=/opt/conda/bin:$PATH
ENV CONDA_DIR=/opt/conda

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    build-essential \
    sudo \
    unzip \
    zip \
    ca-certificates \
    bzip2 \
    libgl1-mesa-glx \
    libgtk-3-0 \
    libdbus-glib-1-2 \
    libxt6 \
    libx11-xcb1 \
    libxcomposite1 \
    libxcursor1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    libxrandr2 \
    libxrender1 \
    libxss1 \
    libxtst6 \
    libnss3 \
    libasound2 \
    libpangocairo-1.0-0 \
    libpango-1.0-0 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libssl3 \
    libffi7 \
    default-jre-headless \
    maven \
    firefox \
    && rm -rf /var/lib/apt/lists/*

RUN GECKODRIVER_VERSION=v0.31.0 && \
    curl -L -o /tmp/geckodriver.tar.gz https://github.com/mozilla/geckodriver/releases/download/$GECKODRIVER_VERSION/geckodriver-$GECKODRIVER_VERSION-linux64.tar.gz && \
    tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/geckodriver && \
    rm /tmp/geckodriver.tar.gz

RUN set -eux; \
    MINIFORGE_URL="https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"; \
    curl -L -o /tmp/miniforge.sh "$MINIFORGE_URL"; \
    chmod +x /tmp/miniforge.sh; \
    /tmp/miniforge.sh -b -p /opt/conda; \
    rm /tmp/miniforge.sh

RUN /opt/conda/bin/conda clean -tipsy; \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh

RUN useradd -m -s /bin/bash itdocker && echo "itdocker ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/itdocker && chmod 0440 /etc/sudoers.d/itdocker

ENV SDKMAN_DIR=/opt/sdkman
ENV JAVA_HOME=$SDKMAN_DIR/candidates/java/current
ENV PATH=$JAVA_HOME/bin:$PATH

RUN curl -s "https://get.sdkman.io" | bash && \
    bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk install java 8.0.302-open && sdk default java 8.0.302-open"

RUN chown -R itdocker:itdocker /opt/sdkman

USER itdocker
WORKDIR /home/itdocker

COPY --chown=itdocker:itdocker . /home/itdocker/exli

RUN ls -l /home/itdocker/exli/python
RUN ls -l /home/itdocker/exli

RUN chmod +x /home/itdocker/exli/python/prepare-conda-env.sh

WORKDIR /home/itdocker/exli/python

RUN /bin/bash -ex -c "source /opt/conda/etc/profile.d/conda.sh && conda init bash && conda activate base && bash ./prepare-conda-env.sh"

RUN /bin/bash -ex -c "source /opt/conda/etc/profile.d/conda.sh && conda activate exli && pip install ."

RUN mkdir -p /home/itdocker/exli/logs /home/itdocker/exli/results /home/itdocker/exli/tests && \
    chown -R itdocker:itdocker /home/itdocker/exli

WORKDIR /home/itdocker/exli

CMD ["/bin/bash"]