# 简单的开发环境 Dockerfile
FROM python:3.9-slim

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# 设置工作目录
WORKDIR /app

# 安装基本的系统工具
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        curl \
        wget \
        vim \
        nano \
        tree \
        htop \
        unzip \
        zip \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# 升级pip
RUN pip install --no-cache-dir --upgrade pip

# 复制requirements.txt文件
COPY ../requirements.txt /app/requirements.txt

# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt

# 创建一个测试文件
RUN echo "Hello from Docker!" > /app/hello.txt

# 暴露端口
EXPOSE 8000

# 设置默认命令
CMD ["python", "-c", "print('Docker container is running!'); import time; time.sleep(30); print('Container finished')"]
