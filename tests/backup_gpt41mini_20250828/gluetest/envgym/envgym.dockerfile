FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV SDKMAN_DIR=/root/.sdkman
ENV JAVA_HOME=/root/.sdkman/candidates/java/current
ENV MAVEN_HOME=/opt/maven
ENV PATH=$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH

WORKDIR /gluetest

# Install prerequisites
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    zip \
    tar \
    git \
    bash \
    ca-certificates \
    python3.11 \
    python3.11-venv \
    python3.11-distutils \
    wget \
    maven \
    && rm -rf /var/lib/apt/lists/*

# Install pip for python3.11 explicitly
RUN wget https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py && \
    python3.11 /tmp/get-pip.py && \
    rm /tmp/get-pip.py

# Install SDKMAN! and GraalVM Java 17 (17.0.7-graal) in one step
RUN curl -s "https://get.sdkman.io" | bash && \
    bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk install java 17.0.7-graal && sdk use java 17.0.7-graal" 

# Install GraalPython component with proper environment
RUN bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && $JAVA_HOME/bin/gu install python"

# Verify Maven installation
RUN mvn -version

# Create python3 alias and upgrade pip, install pytest globally using python3.11 explicitly
RUN ln -sf /usr/bin/python3.11 /usr/bin/python && \
    python3.11 -m pip install --upgrade pip setuptools wheel && \
    python3.11 -m pip install pytest

# Set up Python virtual environment in project root
RUN python3.11 -m venv /gluetest/venv

# Update .bashrc to add GraalVM, Maven, JAVA_HOME and activate python venv on shell start
RUN echo "export SDKMAN_DIR=$SDKMAN_DIR" >> /root/.bashrc && \
    echo "source $SDKMAN_DIR/bin/sdkman-init.sh" >> /root/.bashrc && \
    echo "export JAVA_HOME=$JAVA_HOME" >> /root/.bashrc && \
    echo "export MAVEN_HOME=$MAVEN_HOME" >> /root/.bashrc && \
    echo "export PATH=\$JAVA_HOME/bin:\$MAVEN_HOME/bin:\$PATH" >> /root/.bashrc && \
    echo "source /gluetest/venv/bin/activate" >> /root/.bashrc

# Ensure working directory exists
RUN mkdir -p /gluetest

# Set default shell to bash and start at working directory
CMD ["/bin/bash"]