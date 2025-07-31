FROM openjdk:17-jdk-slim

LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="x86_64/amd64 fastjson2 Java development environment with Maven, Git, and optional GraalVM Native Image (no GPU/CUDA)."

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    MAVEN_VERSION=3.9.6 \
    MAVEN_HOME=/opt/maven \
    PATH=/opt/maven/bin:$PATH

# Install git, curl, unzip, and other essentials
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        unzip \
        ca-certificates \
        bash \
        build-essential \
        libz-dev \
        && rm -rf /var/lib/apt/lists/*

# Install Maven (official binary, x86_64)
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
        -o /tmp/maven.tar.gz && \
    mkdir -p /opt && \
    tar -xzvf /tmp/maven.tar.gz -C /opt && \
    mv /opt/apache-maven-${MAVEN_VERSION} $MAVEN_HOME && \
    rm /tmp/maven.tar.gz

# (Optional) Install GraalVM Community Edition (x86_64, Java 17)
# Uncomment the following section if you need GraalVM Native Image support

# ENV GRAALVM_VERSION=22.3.3 \
#     GRAALVM_HOME=/opt/graalvm
# RUN curl -fsSL https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-${GRAALVM_VERSION}/graalvm-community-jdk-17_linux-x64_bin.tar.gz \
#         -o /tmp/graalvm.tar.gz && \
#     mkdir -p /opt && \
#     tar -xzvf /tmp/graalvm.tar.gz -C /opt && \
#     mv /opt/graalvm-community-jdk-17* $GRAALVM_HOME && \
#     rm /tmp/graalvm.tar.gz && \
#     $GRAALVM_HOME/bin/gu install native-image && \
#     ln -sf $GRAALVM_HOME/bin/native-image /usr/local/bin/native-image
# ENV JAVA_HOME=$GRAALVM_HOME
# ENV PATH=$GRAALVM_HOME/bin:$PATH

# Set JAVA_HOME for the stock OpenJDK
ENV JAVA_HOME=/usr/local/openjdk-17

# (Optional) Install Kotlin compiler if needed
# RUN curl -fsSL https://github.com/JetBrains/kotlin/releases/download/v1.9.23/kotlin-compiler-1.9.23.zip -o /tmp/kotlin.zip && \
#     unzip /tmp/kotlin.zip -d /opt && \
#     ln -sf /opt/kotlinc/bin/kotlinc /usr/local/bin/kotlinc && \
#     rm /tmp/kotlin.zip

# Create app directory
WORKDIR /workspace

# Clone fastjson2 repository (or mount as volume in CI/CD)
# RUN git clone https://github.com/alibaba/fastjson2.git

# Copy project files (for build context usage)
# COPY . /workspace

# Default command (override as needed)
CMD ["/bin/bash"]

# Notes:
# - This image is tailored for x86_64/amd64 Linux with OpenJDK 17, Maven, and Git.
# - No CUDA, NVIDIA, or GPU-specific tools are installed.
# - GraalVM and Kotlin installation blocks are provided but commented out; enable as needed.
# - For building, use: mvn -T 1C clean install (multi-core build).
# - All paths are case-sensitive; no ARM/ARM64 binaries.
# - For IDEs or Android SDK, install as needed in your local environment, not in this image.