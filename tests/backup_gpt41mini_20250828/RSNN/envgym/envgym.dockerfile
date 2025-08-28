FROM python:3.10.12-slim

# Set environment variables to avoid Python buffering and warnings
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:$PATH

# Set working directory to repository root
WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/RSNN

# Install system dependencies for build and git plus additional build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    ca-certificates \
    python3-dev \
    libffi-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python3 -m venv $VIRTUAL_ENV

# Upgrade pip inside the virtual environment
RUN pip install --upgrade pip

# Copy requirements.txt early for caching
COPY requirements.txt ./requirements.txt

# Install requirements from requirements.txt without stork
RUN sed '/git+https:\/\/github.com\/fmi-basel\/stork.git/d' requirements.txt > tmp_requirements.txt && \
    pip install --no-cache-dir -r tmp_requirements.txt && rm tmp_requirements.txt

# Install stork editable from specific commit with explicit #egg=stork
RUN pip install --no-cache-dir -e git+https://github.com/fmi-basel/stork.git@40c68fe#egg=stork

# Install randman directly from GitHub with specific commit without editable flag
RUN pip install --no-cache-dir git+https://github.com/fmi-basel/randman.git@7f1a7a8#egg=randman

# Copy the entire repository contents to working directory
COPY . .

# Ensure scripts are executable if needed (optional)
RUN find . -type f -name "*.sh" -exec chmod +x {} +

# Default command to bash shell at repo root with virtualenv activated
CMD ["/bin/bash", "-c", "source /opt/venv/bin/activate && exec /bin/bash"]