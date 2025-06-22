# EnvGym Development Environment Dockerfile
# 支持多种编程语言和开发工具的环境

ARG BASE_IMAGE=python:3.9-slim
FROM ${BASE_IMAGE}

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# 安装系统依赖
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        curl \
        wget \
        vim \
        nano \
        nodejs \
        npm \
        openjdk-11-jdk \
        golang-go \
        rustc \
        cargo \
        cmake \
        make \
        gcc \
        g++ \
        gdb \
        valgrind \
        htop \
        tree \
        jq \
        unzip \
        zip \
        ca-certificates \
        software-properties-common && \
    rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /workspace

# 复制Python依赖文件并安装
COPY python/pyproject.toml ./python/
COPY examples/python/requirements.txt ./examples/python/
COPY test_agent_squad/requirements.txt ./test_agent_squad/

# 安装Python依赖
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -e ./python && \
    pip install --no-cache-dir -r ./examples/python/requirements.txt && \
    pip install --no-cache-dir -r ./test_agent_squad/requirements.txt

# 安装TypeScript/JavaScript依赖
COPY typescript/package.json ./typescript/
COPY docs/package.json ./docs/
RUN cd typescript && npm install && \
    cd ../docs && npm install

# 复制应用代码
COPY . .

# 创建envgym用户
RUN useradd -m -s /bin/bash envgym && \
    chown -R envgym:envgym /workspace

USER envgym

# 暴露端口
EXPOSE 8000 3000 4321

# 默认命令
CMD ["bash"]
