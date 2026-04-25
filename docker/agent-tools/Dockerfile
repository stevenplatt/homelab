FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        git \
        build-essential \
        ca-certificates \
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

RUN curl -fsSL https://agentstack.beeai.dev/install.sh -o /tmp/agentstack-install.sh \
    && yes | sh /tmp/agentstack-install.sh \
    && rm /tmp/agentstack-install.sh

WORKDIR /workspace

CMD ["bash"]
