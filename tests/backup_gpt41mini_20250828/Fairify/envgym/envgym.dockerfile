FROM python:3.7-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PATH="/root/fenv/bin:$PATH"

WORKDIR /Fairify

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    git \
    bash \
    build-essential \
    libz3-dev \
    libxml2-dev \
    libxslt1-dev \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/sumonbis/Fairify.git /Fairify

RUN python3 -m venv /root/fenv

RUN /root/fenv/bin/pip install --upgrade pip

RUN /root/fenv/bin/pip install -r /Fairify/requirements.txt

RUN chmod +x /Fairify/src/fairify.sh \
    /Fairify/stress/fairify-stress.sh \
    /Fairify/relaxed/fairify-relaxed.sh \
    /Fairify/targeted/fairify-targeted.sh \
    /Fairify/targeted2/fairify-targeted.sh

CMD ["/bin/bash"]