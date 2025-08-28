FROM python:3.10-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/SEED-GNN

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    bash \
    && rm -rf /var/lib/apt/lists/*

RUN python -m venv /venv_seedgnn

ENV PATH="/venv_seedgnn/bin:$PATH"

RUN pip install --upgrade pip

RUN pip install torch==2.0.0+cpu torchvision==0.15.1+cpu torchaudio==2.0.1+cpu -f https://download.pytorch.org/whl/torch_stable.html

RUN pip install torch-scatter==2.1.1 torch-cluster==1.6.1 torch-spline-conv==1.2.2 torch-sparse==0.6.17 -f https://data.pyg.org/whl/torch-2.0.0+cpu.html

COPY requirements.txt /home/cc/EnvGym/data-gpt-4.1mini/SEED-GNN/requirements.txt

RUN pip install -r requirements.txt

COPY . /home/cc/EnvGym/data-gpt-4.1mini/SEED-GNN

RUN chmod +x scripts/pretrain/seed_gnn/cora.sh scripts/edit/seed_gnn/gcn/cora.sh

CMD ["/bin/bash"]