FROM --platform=linux/amd64 openjdk:17-jdk-slim as base

ENV DEBIAN_FRONTEND=noninteractive
ENV MAVEN_VERSION=3.9.6
ENV MAVEN_HOME=/opt/maven
ENV GRADLE_VERSION=7.6.4
ENV GRADLE_HOME=/opt/gradle
ENV PATH=$MAVEN_HOME/bin:$GRADLE_HOME/bin:$PATH

WORKDIR /home/cc/EnvGym/data/alibaba_fastjson2

# Install essential packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        unzip \
        ca-certificates \
        bash \
        build-essential \
        libz-dev \
        python3 \
        python3-pip \
        python3-venv \
        docker.io \
    && rm -rf /var/lib/apt/lists/*

# Install Maven (amd64 only)
RUN curl -fSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz -o /tmp/maven.tar.gz && \
    mkdir -p $MAVEN_HOME && \
    tar -xzf /tmp/maven.tar.gz -C $MAVEN_HOME --strip-components=1 && \
    rm /tmp/maven.tar.gz

# Install Gradle (amd64 only, optional)
RUN curl -fsSL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o /tmp/gradle.zip && \
    mkdir -p $GRADLE_HOME && \
    unzip -q /tmp/gradle.zip -d /opt && \
    mv /opt/gradle-${GRADLE_VERSION}/* $GRADLE_HOME/ && \
    rm -rf /opt/gradle-${GRADLE_VERSION} /tmp/gradle.zip

# Optional: Install GraalVM CE (amd64 only, optional block)
# ENV GRAALVM_VERSION=22.3.3
# ENV GRAALVM_HOME=/opt/graalvm
# RUN curl -fsSL https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-${GRAALVM_VERSION}/graalvm-community-jdk-${GRAALVM_VERSION}_linux-x64_bin.tar.gz -o /tmp/graalvm.tar.gz && \
#     mkdir -p $GRAALVM_HOME && \
#     tar -xzf /tmp/graalvm.tar.gz -C $GRAALVM_HOME --strip-components=1 && \
#     rm /tmp/graalvm.tar.gz && \
#     $GRAALVM_HOME/bin/gu install native-image
# ENV PATH=$GRAALVM_HOME/bin:$PATH

# Optional: Install Kotlin compiler (amd64 only, optional block)
# ENV KOTLIN_VERSION=1.9.24
# RUN curl -fsSL https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip -o /tmp/kotlinc.zip && \
#     unzip -q /tmp/kotlinc.zip -d /opt && \
#     rm /tmp/kotlinc.zip
# ENV PATH=/opt/kotlinc/bin:$PATH

# Optional: Install Docker Compose (amd64 only)
RUN curl -fsSL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Optional: Install ProGuard (amd64 only, optional block)
# ENV PROGUARD_VERSION=7.4.2
# RUN curl -fsSL https://github.com/Guardsquare/proguard/releases/download/v${PROGUARD_VERSION}/proguard-${PROGUARD_VERSION}.zip -o /tmp/proguard.zip && \
#     unzip -q /tmp/proguard.zip -d /opt && \
#     rm /tmp/proguard.zip
# ENV PATH=/opt/proguard/bin:$PATH

# Optional: Install codecov CLI (amd64 only, optional block)
# RUN curl -fsSL https://uploader.codecov.io/latest/linux/codecov -o /usr/local/bin/codecov && \
#     chmod +x /usr/local/bin/codecov

# Clean up pip cache
RUN python3 -m pip install --upgrade pip && rm -rf /root/.cache/pip

# Copy the entire repository into the image
COPY . /home/cc/EnvGym/data/alibaba_fastjson2

# Prepare entrypoint at repository root
WORKDIR /home/cc/EnvGym/data/alibaba_fastjson2

CMD ["/bin/bash"]