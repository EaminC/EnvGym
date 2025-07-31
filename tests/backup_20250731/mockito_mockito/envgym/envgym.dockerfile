FROM --platform=linux/amd64 ubuntu:22.04

# Set noninteractive for apt
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /home/cc/EnvGym/data/mockito_mockito

# Install core tools and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        wget \
        unzip \
        git \
        ca-certificates \
        gnupg \
        software-properties-common \
        apt-transport-https \
        build-essential \
        openjdk-11-jdk \
        openjdk-17-jdk \
        openjdk-21-jdk \
        zip \
        python3 \
        python3-pip \
        libvirt-daemon-system \
        qemu-kvm \
        libvirt-clients \
        bridge-utils \
        libgl1-mesa-dev \
        libpulse0 \
        libnss3 \
        libx11-6 \
        libx11-xcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxi6 \
        libxrandr2 \
        libxtst6 \
        libxss1 \
        libglib2.0-0 \
        libsm6 \
        libdbus-1-3 \
        libfontconfig1 \
        xvfb \
        && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME variables for each JDK
ENV JAVA11_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV JAVA17_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV JAVA21_HOME=/usr/lib/jvm/java-21-openjdk-amd64

# Set default JAVA_HOME to JDK 17
ENV JAVA_HOME=${JAVA17_HOME}
ENV PATH=$JAVA_HOME/bin:$PATH

# Install Gradle dependencies (project is assumed to use Gradle Wrapper)
# No extra installation needed for Gradle itself

# Install Android Command Line Tools (latest)
ENV ANDROID_SDK_ROOT=/home/cc/EnvGym/data/mockito_mockito/.android-sdk
ENV ANDROID_HOME=${ANDROID_SDK_ROOT}
ENV PATH=${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/emulator

RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    cd /tmp && \
    wget --progress=dot:giga https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O commandlinetools.zip && \
    unzip commandlinetools.zip && \
    rm commandlinetools.zip && \
    mv cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest

# Accept Android SDK licenses and install required packages
RUN yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses

# Install Android SDK components (platform-tools, build-tools, platforms, emulator, system-images)
RUN sdkmanager --sdk_root=${ANDROID_SDK_ROOT} \
    "platform-tools" \
    "emulator" \
    "build-tools;34.0.0" \
    "platforms;android-34" \
    "system-images;android-34;google_apis;x86_64"

# (Optional) Create local.properties for Android SDK location
RUN echo "sdk.dir=${ANDROID_SDK_ROOT}" > /home/cc/EnvGym/data/mockito_mockito/local.properties

# Set permissions for the workspace
RUN chown -R root:root /home/cc/EnvGym/data/mockito_mockito && \
    chmod -R 755 /home/cc/EnvGym/data/mockito_mockito

# Set environment for Android emulator to use software rendering (no GPU)
ENV ANDROID_EMULATOR_USE_SYSTEM_LIBS=1
ENV QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb

# Configure git (global, non-user specific)
RUN git config --system core.autocrlf input

# Set default shell to bash
SHELL ["/bin/bash", "-c"]

# Expose common ports for emulator or debugging if needed
EXPOSE 5554 5555 5037

# Entrypoint (override as needed)
CMD ["/bin/bash"]