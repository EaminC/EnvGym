# syntax=docker/dockerfile:1.8

FROM --platform=linux/amd64 ubuntu:22.04

LABEL maintainer="cc"
LABEL org.opencontainers.image.source="/home/cc/EnvGym/data/elastic_logstash"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PROJECT_ROOT=/home/cc/EnvGym/data/elastic_logstash \
    JAVA_VERSION=17 \
    JDK_DIR=/usr/lib/jvm/adoptium-temurin-17-jdk-amd64 \
    JRUBY_VERSION=9.4.7.0 \
    JRUBY_HOME=/opt/jruby \
    GEM_HOME=/usr/local/bundle \
    GEM_PATH=/usr/local/bundle \
    PATH="/opt/jruby/bin:/usr/lib/jvm/adoptium-temurin-17-jdk-amd64/bin:$PATH" \
    GRADLE_USER_HOME=/home/cc/.gradle

# Install OS dependencies
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && \
    apt-get install -y \
      wget \
      curl \
      git \
      unzip \
      perl \
      build-essential \
      libssl-dev \
      zlib1g-dev \
      libreadline-dev \
      libyaml-dev \
      libsqlite3-dev \
      sqlite3 \
      libxml2-dev \
      libxslt1-dev \
      libffi-dev \
      libgdbm-dev \
      libncurses5-dev \
      libtool \
      bison \
      openjdk-8-jdk-headless \
      openjdk-11-jdk-headless \
      ca-certificates \
      python3 \
      python3-pip \
      jq \
      lsb-release \
      && rm -rf /var/lib/apt/lists/*

# Install Adoptium Temurin JDK 17 (x86_64)
RUN mkdir -p /tmp/jdk && \
    wget -qO /tmp/jdk.tar.gz https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.10+7/OpenJDK17U-jdk_x64_linux_hotspot_17.0.10_7.tar.gz && \
    tar -xzf /tmp/jdk.tar.gz -C /tmp/jdk --strip-components=1 && \
    mkdir -p $JDK_DIR && \
    mv /tmp/jdk/* $JDK_DIR && \
    rm -rf /tmp/jdk.tar.gz /tmp/jdk

ENV JAVA_HOME=$JDK_DIR
ENV BUILD_JAVA_HOME=$JDK_DIR

# Install Gradle (latest 8.x LTS, x86_64)
RUN wget -qO /tmp/gradle.zip https://services.gradle.org/distributions/gradle-8.7-bin.zip && \
    unzip -d /opt /tmp/gradle.zip && \
    ln -s /opt/gradle-8.7/bin/gradle /usr/local/bin/gradle && \
    rm /tmp/gradle.zip

# Install JRuby (Linux x86_64 tarball)
RUN wget -qO /tmp/jruby.tar.gz https://repo1.maven.org/maven2/org/jruby/jruby-dist/9.4.7.0/jruby-dist-9.4.7.0-bin.tar.gz && \
    tar -xzf /tmp/jruby.tar.gz -C /opt && \
    mv /opt/jruby-9.4.7.0 $JRUBY_HOME && \
    ln -s $JRUBY_HOME/bin/jruby /usr/local/bin/jruby && \
    rm /tmp/jruby.tar.gz

# --- Debug JRuby/Gem install issues: check JRuby works and split gem installs ---
RUN jruby -v && jruby -S gem -v

# Skip update_rubygems (known to break on JRuby 9.2.x)
# Install Bundler and other gems directly with current RubyGems
RUN jruby -S gem install bundler:2.2.33 --no-document --verbose
RUN jruby -S gem install rake --no-document --verbose
RUN jruby -S gem install rspec --no-document --verbose
RUN jruby -S gem install dotenv -v 2.8.1 --no-document --verbose && \
    jruby -S gem install fpm -v 1.11.0 --no-document --verbose

# Install Drip (x86_64 only, optional; allow build to continue if not available)
RUN wget -qO /usr/local/bin/drip https://github.com/ninjudd/drip/releases/download/0.4.5/drip-0.4.5-linux-x86_64 || echo "Drip not available, skipping" && \
    [ ! -f /usr/local/bin/drip ] || chmod +x /usr/local/bin/drip

# Install Elasticsearch (OSS build, x86_64)
RUN wget -qO /tmp/elasticsearch.tar.gz https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.13.4-linux-x86_64.tar.gz && \
    mkdir -p /opt/elasticsearch && \
    tar -xzf /tmp/elasticsearch.tar.gz -C /opt/elasticsearch --strip-components=1 && \
    rm /tmp/elasticsearch.tar.gz

ENV ES_HOME=/opt/elasticsearch

# Install Vault (HashiCorp, x86_64)
RUN VAULT_VERSION=1.15.5 && \
    wget -qO /tmp/vault.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip && \
    unzip /tmp/vault.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/vault && \
    rm /tmp/vault.zip

# Create project root and subdirs
RUN mkdir -p $PROJECT_ROOT && chown -R 1000:1000 $PROJECT_ROOT

# Create and set permissions for cc user home and gradle cache before switching user
RUN useradd -m -u 1000 cc && \
    mkdir -p /home/cc/.gradle && \
    chown -R cc:cc /home/cc && \
    echo "org.gradle.daemon=true" > /home/cc/.gradle/gradle.properties && \
    echo "org.gradle.jvmargs=-Xmx2g -XX:MaxMetaspaceSize=1g" >> /home/cc/.gradle/gradle.properties

WORKDIR $PROJECT_ROOT

# Copy the .ruby-version file if present in local context
# (Uncomment the following line in your own Docker build context)
# COPY .ruby-version .ruby-version

# Set permissions for the project directory
RUN chown -R 1000:1000 $PROJECT_ROOT

# Set up environment variables for user
RUN echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile.d/envgym_java.sh && \
    echo "export BUILD_JAVA_HOME=$BUILD_JAVA_HOME" >> /etc/profile.d/envgym_java.sh && \
    echo "export JRUBY_HOME=$JRUBY_HOME" >> /etc/profile.d/envgym_java.sh && \
    echo "export GEM_HOME=$GEM_HOME" >> /etc/profile.d/envgym_java.sh && \
    echo "export GEM_PATH=$GEM_PATH" >> /etc/profile.d/envgym_java.sh && \
    echo "export PATH=$PATH" >> /etc/profile.d/envgym_java.sh

USER cc

ENV HOME=/home/cc

WORKDIR $PROJECT_ROOT

# Optionally, clone the repository if needed (uncomment and set REPO_URL as build arg)
# ARG REPO_URL
# RUN if [ -n "$REPO_URL" ]; then git clone $REPO_URL $PROJECT_ROOT; fi

# Set up Gradle cache for faster builds
# (already created /home/cc/.gradle above as root with correct ownership)

# Default entrypoint
ENTRYPOINT ["/bin/bash"]