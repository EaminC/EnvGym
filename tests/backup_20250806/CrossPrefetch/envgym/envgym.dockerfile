FROM python:3.10-slim

# Set environment variables for non-interactive apt and optimal pip
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Set working directory
WORKDIR /app

# Install development tools and essential system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        vim \
        ca-certificates \
        curl \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# Copy only requirements first to leverage Docker layer caching
COPY requirements.txt /app/

# Install Python dependencies
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code and data
COPY . /app

# Default command (adjust as needed)
CMD ["python", "main.py"]