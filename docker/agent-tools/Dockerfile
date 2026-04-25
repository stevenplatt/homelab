FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:${PATH}"

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        git \
        build-essential \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
        crewai \
        crewai-tools \
        openai

RUN curl -fsSL https://agentstack.beeai.dev/install.sh -o /tmp/agentstack-install.sh \
    && yes | sh /tmp/agentstack-install.sh \
    && rm /tmp/agentstack-install.sh

WORKDIR /workspace

CMD ["bash"]
