FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-venv python3-pip python3-distutils \
    git bash curl ca-certificates build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY . /app

RUN chmod +x /app/install.sh

RUN /bin/bash /app/install.sh || true

RUN python3 -m venv /app/venv

ENV PATH="/app/venv/bin:${PATH}"
ENV PYTHONPATH=/app

RUN pip install --upgrade pip setuptools wheel

RUN pip install numpy scipy pandas matplotlib \
    pystan tensorflow-cpu tensorflow-probability \
    torch --extra-index-url https://download.pytorch.org/whl/cpu \
    edward2 pyro-ppl

RUN mkdir -p /app/output && chown -R root:root /app/output

CMD ["/bin/bash"]