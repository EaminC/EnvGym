FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    git \
    curl \
    ca-certificates \
    build-essential \
    cmake \
    python3 \
    python3-venv \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    && rm -rf /var/lib/apt/lists/*

# Create a symlink for python to python3 if not exists
RUN ln -sf /usr/bin/python3 /usr/bin/python

RUN python3 --version && python --version

RUN python3 -m pip install --upgrade pip setuptools wheel

WORKDIR /nlohmann_json

# Create requirements files as per plan

# /tools/serve_header/requirements.txt
RUN mkdir -p tools/serve_header && echo "PyYAML==6.0.2\nwatchdog==6.0.0" > tools/serve_header/requirements.txt

# /tools/generate_natvis/requirements.txt
RUN mkdir -p tools/generate_natvis && echo "jinja2==3.1.6" > tools/generate_natvis/requirements.txt

# /tools/astyle/requirements.txt
RUN mkdir -p tools/astyle && echo "astyle==3.4.13" > tools/astyle/requirements.txt

# /docs/mkdocs/requirements.txt with exact pinned versions
RUN mkdir -p docs/mkdocs && echo "mkdocs==1.6.1\nmkdocs-git-revision-date-localized-plugin==1.4.7\nmkdocs-material==9.6.18\nmkdocs-material-extensions==1.3.1\nmkdocs-minify-plugin==0.8.0\nmkdocs-redirects==1.2.2\nmkdocs-htmlproofer-plugin==1.3.0\nPyYAML==6.0.2\nwheel==0.45.1" > docs/mkdocs/requirements.txt

# /cmake/requirements directory placeholder (assuming cmake is installed via apt)
RUN mkdir -p cmake/requirements

# Create virtual environments and install dependencies for each pip environment

SHELL ["/bin/bash", "-c"]

RUN set -ex; \
    for dir in docs/mkdocs tools/astyle tools/generate_natvis tools/serve_header; do \
        python3 -m venv "$dir/venv"; \
        source "$dir/venv/bin/activate"; \
        pip install --upgrade pip; \
        pip install -r "$dir/requirements.txt"; \
        deactivate; \
    done

# Install GitHub CLI latest stable
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/*

ENV PATH="/nlohmann_json/docs/mkdocs/venv/bin:/nlohmann_json/tools/astyle/venv/bin:/nlohmann_json/tools/generate_natvis/venv/bin:/nlohmann_json/tools/serve_header/venv/bin:${PATH}"

CMD ["/bin/bash"]