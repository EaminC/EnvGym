FROM node:20-bullseye

# Set working directory inside the container
WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/iamkun_dayjs

# Install git, curl, and browsers (chrome and firefox) for testing/debugging
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    wget \
    gnupg2 \
    lsb-release \
    firefox-esr \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome (stable) for Linux x86_64
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-linux-signing-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-linux-signing-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y --no-install-recommends google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# Copy project files (assumes Docker build context is the project root)
COPY . .

# Ensure all shell scripts have executable permissions and correct shebangs if any
RUN find . -type f -name "*.sh" -exec chmod +x {} +

# Install npm dependencies with clean install
RUN npm ci

# Set environment variables for Linux shell usage (can be overridden)
ENV NODE_ENV=development

# Expose environment variables placeholders for Sauce Labs (can be set at runtime)
ENV SAUCE_USERNAME=""
ENV SAUCE_ACCESS_KEY=""

# Default to bash shell at container start
CMD ["/bin/bash"]