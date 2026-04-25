# Docker — local LLM stack

A Docker Compose stack that runs AMD's [Lemonade Server](https://github.com/lemonade-sdk/lemonade) for local inference, with Open WebUI for browser chat and a development container that has CrewAI and AgentStack pre-installed.

Lemonade is purpose-built for AMD GPUs/NPUs and ships with ROCm 7 bundled inside the image. RDNA4 (gfx1201, **Radeon AI Pro R9700** and the RX 9070/9060 series) is a first-class supported target — no `HSA_OVERRIDE_GFX_VERSION` games, no host ROCm install.

## Services

| Service | Image / Source | Port | Purpose |
| --- | --- | --- | --- |
| `lemonade` | `ghcr.io/lemonade-sdk/lemonade-server:latest` | `13305` | OpenAI-compatible inference server (`/v1/...`) |
| `open-webui` | `ghcr.io/open-webui/open-webui:main` | `8080` | Browser chat UI, pre-wired to the lemonade endpoint |
| `agent-tools` | `./agent-tools` (built locally) | — | Long-running container with `crewai` + `agentstack` CLIs available; exec into it to write agents |

All three share the compose network; `open-webui` and `agent-tools` reach lemonade at `http://lemonade:13305/v1`.

## Prerequisites

The Ansible playbook ([../ansible/steel_legend.yml](../ansible/steel_legend.yml)) handles the host setup:
- `docker.io` and `docker-compose-v2` installed
- Current user added to `docker`, `render`, `video` groups
- Docker service started and enabled

After running the playbook, **log out and back in** so the new group memberships take effect — otherwise `docker` commands will fail with permission denied.

## Setup

```sh
mkdir -p workspace
docker compose pull
docker compose up -d
```

The `lemonade` container starts with no model loaded. Pull one before first use:

```sh
docker compose exec lemonade ./lemonade pull Gemma-4-31B-it-GGUF
```

That's Gemma 4 31B (dense) at 4-bit — ~20GB VRAM, leaves headroom on a 32GB R9700 for context. Confirm the exact catalog name with `./lemonade list` if the pull errors.

The first pull downloads the weights into the `lemonade-cache` volume. Subsequent restarts reuse them.

## Verifying

```sh
# health
docker compose ps                                 # everything should be 'healthy'
curl -s http://localhost:13305/live               # should return ok

# raw API
curl -s http://localhost:13305/v1/models | jq

# Open WebUI — point a browser at:
#   http://localhost:8080
# the lemonade endpoint is preconfigured; no setup needed if WEBUI_AUTH=False

# enter the agent dev container
docker compose exec agent-tools bash

# inside the container, both CLIs are on PATH
crewai --help
agentstack --help

# OPENAI_API_BASE, OPENAI_API_KEY, OPENAI_MODEL_NAME are already set,
# so any LLM-aware tool (LangChain, CrewAI, AgentStack) hits local lemonade by default
```

Drop your CrewAI / AgentStack project files into the `./workspace` directory on the host — it's bind-mounted into the container at `/workspace`.

## Configuration

All knobs are inlined directly in [docker-compose.yml](docker-compose.yml) — there is no `.env` file. Edit the YAML and `docker compose up -d` to apply.

| Service | Key | Default | What it does |
| --- | --- | --- | --- |
| `agent-tools` | `OPENAI_MODEL_NAME` | `Gemma-4-31B-it-GGUF` | Model name `agent-tools` calls (must match what you've pulled) |
| `open-webui` | `WEBUI_AUTH` | `False` | Toggle Open WebUI login flow |
| `open-webui` / `agent-tools` | `OPENAI_API_BASE_URL` / `OPENAI_API_BASE` | `http://lemonade:13305/v1` | Backend endpoint |

## Models

Lemonade has its own curated model catalog. Common operations from inside the `lemonade` container (or via the API):

```sh
docker compose exec lemonade ./lemonade list                    # available + installed
docker compose exec lemonade ./lemonade pull <model-name>       # download
docker compose exec lemonade ./lemonade rm <model-name>         # delete
```

See the [Lemonade CLI guide](https://lemonade-server.ai/docs/lemonade-cli/) for the full list.

## GPU notes

The compose file passes `/dev/kfd` and `/dev/dri` into the container and joins the host `render`/`video` groups. Lemonade's bundled ROCm 7 handles the rest. Supported architectures (per [llamacpp-rocm releases](https://github.com/lemonade-sdk/llamacpp-rocm/releases)):

| Architecture | Cards |
| --- | --- |
| `gfx120X` (RDNA4) | **Radeon AI Pro R9700**, RX 9070 XT/GRE/9070, RX 9060 XT/9060 |
| `gfx110X` (RDNA3) | PRO W7900/W7800/W7700/W7600, RX 7900 XTX/XT/GRE, RX 7800 XT, RX 7700 XT, RX 7600 XT |
| `gfx103X` (RDNA2) | RX 6800/6900 series, etc. |
| `gfx115X` (Strix Halo / APU) | Ryzen AI MAX |

**NVIDIA users:** Lemonade is AMD-only. If you have an NVIDIA card, swap `lemonade` for the upstream vLLM image:

```yaml
lemonade:
  image: vllm/vllm-openai:latest
  ports: ["8000:8000"]
  # remove devices, group_add
  deploy:
    resources:
      reservations:
        devices:
          - driver: nvidia
            count: all
            capabilities: [gpu]
```

…and update the OpenAI base URLs in the other two services to `http://vllm:8000/v1`.

## Troubleshooting

```sh
docker compose ps                              # service health
docker compose logs --tail=200 lemonade        # lemonade startup / model load
docker compose logs --tail=200 open-webui
docker compose exec lemonade rocminfo | head   # GPU visible inside the container?
```

If `rocminfo` fails inside the container but works on the host, the user isn't in the `render`/`video` groups — log out, log back in, then `docker compose down && up -d`.

## Stopping & cleanup

```sh
docker compose stop                  # stop, keep volumes (model cache persists)
docker compose down                  # stop and remove containers
docker compose down -v               # also wipe volumes (re-downloads models)
```
