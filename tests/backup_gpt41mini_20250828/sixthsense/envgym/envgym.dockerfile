FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies: wget, git, curl, bzip2, build-essential, etc.
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    git \
    curl \
    bzip2 \
    ca-certificates \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set Miniconda version and installation path
ENV MINICONDA_VERSION=py38_4.12.0
ENV MINICONDA_INSTALLER=Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh
ENV CONDA_DIR=/opt/conda
ENV PATH=${CONDA_DIR}/bin:$PATH

# Install Miniconda
RUN wget --quiet https://repo.anaconda.com/miniconda/${MINICONDA_INSTALLER} -O /tmp/miniconda.sh && \
    /bin/bash /tmp/miniconda.sh -b -p ${CONDA_DIR} && \
    rm /tmp/miniconda.sh && \
    ${CONDA_DIR}/bin/conda clean -tipsy && \
    ln -s ${CONDA_DIR}/etc/profile.d/conda.sh /etc/profile.d/conda.sh

# Create project root directory and set as working directory
ENV PROJECT_ROOT=/home/cc/EnvGym/data-gpt-4.1mini/sixthsense
RUN mkdir -p ${PROJECT_ROOT}
WORKDIR ${PROJECT_ROOT}

# Copy requirements.txt and sixthsense_env.yml if you have them locally.
# Since the plan specifies contents, create them here.

# Create requirements.txt
RUN echo "scikit-learn\nnumpy\nmatplotlib\npandas\njsonpickle\nnearpy\ntreeinterpreter\ncleanlab" > requirements.txt

# Create sixthsense_env.yml
RUN echo "name: sixthsense\nchannels:\n  - defaults\ndependencies:\n  - python=3.8\n  - pip\n  - pip:\n    - -r requirements.txt" > sixthsense_env.yml

# Create required directories
RUN mkdir -p plots models results csvs subcategories

# Create conda env from yaml and install pip packages
RUN conda init bash && \
    /bin/bash -c "source /opt/conda/etc/profile.d/conda.sh && conda create -y -n sixthsense python=3.8 && conda activate sixthsense && pip install -r requirements.txt"

# Set environment variables for conda environment activation
SHELL ["/bin/bash", "-c"]
RUN echo "source /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc
RUN echo "conda activate sixthsense" >> ~/.bashrc

ENV CONDA_DEFAULT_ENV=sixthsense
ENV PATH=/opt/conda/envs/sixthsense/bin:$PATH

# Clone the SixthSense repository into the working directory if repository URL is known
# Placeholder: You need to replace [repository_url] with actual URL or mount code externally.
# Example (commented out):
# RUN git clone [repository_url] ${PROJECT_ROOT}

# Set working directory to project root (redundant but explicit)
WORKDIR ${PROJECT_ROOT}

# Default command to run bash shell
CMD ["/bin/bash"]