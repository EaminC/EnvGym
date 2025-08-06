FROM continuumio/miniconda3:latest

# Set environment variables
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH

# Set working directory as per plan
WORKDIR /home/cc/EnvGym/data/sixthsense

# Update apt and install system packages required for scientific Python
RUN apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
        git \
        build-essential \
        python3-dev \
        libblas-dev \
        liblapack-dev \
        gfortran \
        libopenblas-dev \
        libatlas-base-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements.txt (environment.yml does not exist)
COPY requirements.txt ./

# Install pip requirements directly (no conda env since environment.yml is missing)
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Copy rest of the repo (excluding files/directories in .dockerignore)
COPY . .

# Create required output and data directories with appropriate permissions
RUN mkdir -p plots models results csvs tests && \
    chmod -R 777 plots models results csvs tests

# Set default command to bash, user can override with docker run
CMD ["/bin/bash"]