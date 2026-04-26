FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        git \
        build-essential \
        ca-certificates \
        qemu-system-x86 \
        qemu-utils \
    && rm -rf /var/lib/apt/lists/*

# match the typical first-user uid/gid on a desktop Ubuntu host so
# bind-mounted ./workspace has matching ownership.
RUN groupadd -g 1000 agent && useradd -m -u 1000 -g 1000 -s /bin/bash agent

USER agent
WORKDIR /home/agent
ENV PATH="/home/agent/.local/bin:${PATH}"

RUN pip install --user --no-cache-dir \
        crewai \
        crewai-tools \
        openai

# install uv (manages its own Python toolchain) and use it to install the
# agentstack CLI on a uv-managed Python 3.14. we skip the upstream install
# script because it ends with `agentstack self install`, which tries to
# bootstrap a docker/QEMU platform from inside the container and fails.
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && /home/agent/.local/bin/uv python install 3.14 \
    && /home/agent/.local/bin/uv tool install \
        --python=3.14 \
        --with agentstack-sdk \
        agentstack-cli

WORKDIR /workspace

CMD ["bash"]
