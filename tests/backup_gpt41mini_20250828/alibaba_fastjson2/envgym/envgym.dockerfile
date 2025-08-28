FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

WORKDIR /app

RUN mkdir -p /usr/share/man/man1 /usr/lib/jvm

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    git \
    bash \
    unzip \
    tar \
    zip \
    software-properties-common \
    ca-certificates \
    gnupg2 \
    libz-dev \
    libssl-dev \
    libfreetype6 \
    libfreetype6-dev \
    libfontconfig1 \
    libxext6 \
    libxrender1 \
    procps \
    libc6-dev \
    libffi-dev \
    build-essential \
    iputils-ping \
    dnsutils \
    file \
    && rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=noninteractive
ENV GRAALVM_VERSION=22.3.4
ENV GRAALVM_DISTRO=graalvm-ce-java17-linux-amd64-${GRAALVM_VERSION}
ENV GRAALVM_URL=https://github.com/graalvm/graalvm-ce-builds/releases/download/v${GRAALVM_VERSION}/${GRAALVM_DISTRO}.tar.gz
ENV JAVA_HOME=/usr/lib/jvm
ENV PATH=$JAVA_HOME/bin:$PATH

RUN apt-get update && apt-get install -y ca-certificates && update-ca-certificates

RUN if ! command -v ping > /dev/null; then apt-get update && apt-get install -y iputils-ping && rm -rf /var/lib/apt/lists/*; fi

RUN echo "Debug: GRAALVM_URL=$GRAALVM_URL" && \
    ping -c 4 github.com || echo "Ping failed" && \
    nslookup github.com || echo "DNS lookup failed"

# Updated GraalVM version and URL to a valid one
ENV GRAALVM_VERSION=22.3.4
ENV GRAALVM_DISTRO=graalvm-ce-java17-linux-amd64-${GRAALVM_VERSION}
ENV GRAALVM_URL=https://github.com/graalvm/graalvm-ce-builds/releases/download/v${GRAALVM_VERSION}/${GRAALVM_DISTRO}.tar.gz

RUN wget --retry-connrefused --tries=10 --timeout=60 --user-agent="Mozilla/5.0" "$GRAALVM_URL" -O /usr/lib/jvm/graalvm.tar.gz && \
    file /usr/lib/jvm/graalvm.tar.gz | grep gzip || (echo "Downloaded file is not gzip archive" && rm /usr/lib/jvm/graalvm.tar.gz && exit 1)

RUN tar -xzf /usr/lib/jvm/graalvm.tar.gz -C /usr/lib/jvm && \
    rm /usr/lib/jvm/graalvm.tar.gz && \
    mv /usr/lib/jvm/${GRAALVM_DISTRO} /usr/lib/jvm/graalvm

ENV JAVA_HOME=/usr/lib/jvm/graalvm
ENV PATH=$JAVA_HOME/bin:$PATH

RUN $JAVA_HOME/bin/java -version

RUN $JAVA_HOME/bin/gu install native-image

RUN native-image --version

ENV MAVEN_VERSION=3.8.8
ENV MAVEN_HOME=/usr/share/maven
ENV PATH=$MAVEN_HOME/bin:$PATH

RUN wget -q https://downloads.apache.org/maven/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    tar -xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /usr/share && \
    ln -s /usr/share/apache-maven-${MAVEN_VERSION} $MAVEN_HOME && \
    rm apache-maven-${MAVEN_VERSION}-bin.tar.gz

RUN mvn -v

ENV GRADLE_VERSION=7.6
ENV GRADLE_HOME=/opt/gradle
ENV PATH=$GRADLE_HOME/bin:$PATH

RUN wget -q https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    unzip -q gradle-${GRADLE_VERSION}-bin.zip -d /opt && \
    ln -s /opt/gradle-${GRADLE_VERSION} $GRADLE_HOME && \
    rm gradle-${GRADLE_VERSION}-bin.zip

RUN gradle -v

ENV KOTLIN_VERSION=1.8.22
ENV KOTLIN_HOME=/opt/kotlinc
ENV PATH=$KOTLIN_HOME/bin:$PATH

RUN wget -q https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}-linux.zip && \
    unzip -q kotlin-compiler-${KOTLIN_VERSION}-linux.zip -d /opt && \
    rm kotlin-compiler-${KOTLIN_VERSION}-linux.zip && \
    mv /opt/kotlinc $KOTLIN_HOME

RUN kotlinc -version

RUN git --version

RUN echo "export JAVA_HOME=${JAVA_HOME}" > /etc/profile.d/java_home.sh && \
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> /etc/profile.d/java_home.sh

WORKDIR /

RUN if [ -f ./mvnw ]; then chmod +x ./mvnw; fi
RUN if [ -f ./gradlew ]; then chmod +x ./gradlew; fi

CMD ["/bin/bash"]