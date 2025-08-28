FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 \
    OSS=true \
    LOGSTASH_SOURCE=1 \
    LOGSTASH_HOME=/home/elastic_logstash \
    RVM_PATH=/usr/local/rvm \
    PATH=/usr/local/rvm/bin:/usr/local/rvm/gems/jruby-9.2.19.0/bin:/usr/local/rvm/gems/jruby-9.2.19.0@global/bin:/usr/local/rvm/rubies/jruby-9.2.19.0/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin

WORKDIR /home

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    dirmngr \
    software-properties-common \
    build-essential \
    git \
    openjdk-11-jdk-headless \
    procps \
    ca-certificates \
    libssl-dev \
    libreadline-dev \
    zlib1g \
    zlib1g-dev \
    locales \
    bash-completion \
    libncurses5 \
    libncurses5-dev \
    ruby-dev \
    gcc \
    make \
    pkg-config \
    libsqlite3-dev \
    libgmp-dev \
    libxml2 \
    libxml2-dev \
    libxslt1.1 \
    libxslt-dev \
    gnupg2 \
    libgdbm-dev \
    libdb-dev \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8

RUN curl -fsSL https://rvm.io/mpapis.asc | gpg --import && \
    curl -fsSL https://rvm.io/pkuczynski.asc | gpg --import

RUN curl -fsSL https://get.rvm.io | bash -s stable

ENV RVM_PATH=/usr/local/rvm
ENV PATH=$RVM_PATH/bin:$PATH

SHELL ["/bin/bash", "-c"]

RUN bash -c "source $RVM_PATH/scripts/rvm && \
    rvm install jruby-9.2.19.0 && \
    rvm use jruby-9.2.19.0 --default && \
    gem install rake -v 13.0.6 --no-document && \
    gem install bundler -v 2.3.27 --no-document"

RUN git clone https://github.com/elastic/logstash.git elastic_logstash

WORKDIR /home/elastic_logstash

RUN echo "jruby-9.2.19.0" > .ruby-version

RUN echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64" >> /root/.bashrc && \
    echo "export OSS=true" >> /root/.bashrc && \
    echo "export LOGSTASH_SOURCE=1" >> /root/.bashrc && \
    echo "export LOGSTASH_HOME=/home/elastic_logstash" >> /root/.bashrc && \
    echo "source $RVM_PATH/scripts/rvm" >> /root/.bashrc && \
    echo "rvm use jruby-9.2.19.0" >> /root/.bashrc

RUN chmod +x ./gradlew

RUN bash -c "source $RVM_PATH/scripts/rvm && \
    rvm use jruby-9.2.19.0 && \
    ./gradlew clean"

RUN bash -c "source $RVM_PATH/scripts/rvm && \
    rvm use jruby-9.2.19.0 && \
    ./gradlew --no-daemon --stacktrace --info installDevelopmentGems"

RUN bash -c "source $RVM_PATH/scripts/rvm && \
    rvm use jruby-9.2.19.0 && \
    ./gradlew --no-daemon --stacktrace --info installDefaultGems"

WORKDIR /home

CMD ["/bin/bash", "-l"]