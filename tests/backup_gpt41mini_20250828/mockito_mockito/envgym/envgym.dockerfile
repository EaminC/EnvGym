FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH
ENV GRADLE_USER_HOME=/home/cc/.gradle

RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-11-jdk-headless \
    git \
    curl \
    unzip \
    bash \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash cc

USER cc
WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/mockito_mockito

RUN git clone https://github.com/mockito/mockito.git . && \
    echo "org.gradle.jvmargs=-Xmx8g" > gradle.properties && \
    echo "org.gradle.parallel=true" >> gradle.properties && \
    echo ".gradle/" > .gitignore && \
    echo "build/" >> .gitignore && \
    echo "*.iml" >> .gitignore && \
    echo ".idea/" >> .gitignore && \
    if [ ! -f settings.gradle ]; then echo "rootProject.name = 'mockito'" > settings.gradle; fi

RUN chmod +x ./gradlew && ./gradlew --version

CMD ["/bin/bash"]