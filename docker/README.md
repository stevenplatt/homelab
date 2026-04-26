# Docker — local LLM stack

A Docker Compose stack that runs AMD's [Lemonade Server](https://github.com/lemonade-sdk/lemonade) for local inference, with Open WebUI for browser chat and OpenHands for autonomous coding tasks.

Lemonade is purpose-built for AMD GPUs/NPUs and ships with ROCm 7 bundled inside the image. RDNA4 (gfx1201, **Radeon AI Pro R9700** and the RX 9070/9060 series) is a first-class supported target — no `HSA_OVERRIDE_GFX_VERSION` games, no host ROCm install.

## Services

| Service | Image | Port | Purpose |
| --- | --- | --- | --- |
| `lemonade` | `ghcr.io/lemonade-sdk/lemonade-server:latest` | `13305` | OpenAI-compatible inference server (`/v1/...`) |
| `open-webui` | `ghcr.io/open-webui/open-webui:main` | `8080` | Browser chat UI, pre-wired to the lemonade endpoint |
| `openhands` | `docker.openhands.dev/openhands/openhands:1.6` | `3000` | Autonomous coding agent — give it a task and it drives a sandbox to completion |

All three share the compose network; `open-webui` and `openhands` reach lemonade at `http://lemonade:13305/v1`.

## Prerequisites

The Ansible playbook ([../ansible/steel_legend.yml](../ansible/steel_legend.yml)) handles the host setup:
- `docker.io` and `docker-compose-v2` installed
- Current user added to `docker`, `render`, `video` groups
- Docker service started and enabled

After running the playbook, **log out and back in** so the new group memberships take effect — otherwise `docker` commands will fail with permission denied.

## Setup

Use the wrapper script — it brings the stack up, polls each service for readiness with progress messages, *and* on `down` cleans up the per-task sandbox containers OpenHands spawns outside the compose project:

```sh
./docker-compose.sh up
```

To tear everything down (including OpenHands's sandbox containers):

```sh
./docker-compose.sh down
```

If you'd rather drive `docker compose` directly, that still works — but you'll have to find and remove the OpenHands runtime containers by hand after each `down`.

The `lemonade` container starts with no model loaded. Pull one before first use:

```sh
docker compose exec lemonade ./lemonade pull Qwen3-Coder-30B-A3B-Instruct-GGUF
```

That's Qwen3 Coder 30B-A3B-Instruct (MoE) at 4-bit — ~16GB of weights with only ~3B parameters active per token, post-trained specifically on agentic coding traces (multi-step `read → patch → run → revise` loops). Fast on the R9700 and leaves ~16GB for KV cache (32K+ context). Confirm the exact catalog name with `./lemonade list` if the pull errors.

## Verifying

```sh
# health
docker compose ps                                 # everything should be 'healthy'
curl -s http://localhost:13305/live               # should return ok

# raw API
curl -s http://localhost:13305/v1/models | jq

# Open WebUI:
#   http://localhost:8080
# the lemonade endpoint is preconfigured; no setup needed if WEBUI_AUTH=False

# OpenHands UI:
#   http://localhost:3000
# the LLM is preconfigured via env vars; first launch may show settings,
# just confirm the model and click save.
```

### Using OpenHands

OpenHands is the autonomous-agent surface: you give it a task, it spawns its own sandbox container (via the host docker socket) and drives it to completion — reading code, running shells, browsing the web. The compose file pre-points it at the local lemonade endpoint via `LLM_BASE_URL`, `LLM_API_KEY`, and `LLM_MODEL` (with the `openai/` prefix LiteLLM requires for generic OpenAI-compatible servers).

> ⚠️ **Trust boundary:** the `openhands` service bind-mounts `/var/run/docker.sock`, which gives it root-equivalent access to the host's docker daemon. It needs this to spawn agent-server sandbox containers. Only run this on a workstation you trust; don't expose port 3000 outside localhost.

A 26B+ model is roughly the practical floor for OpenHands to be useful — smaller models often loop or fail to follow the agent's tool-use protocol. Qwen3-Coder-30B-A3B-Instruct (the default in this stack) is purpose-built for agentic coding: post-trained on multi-step coding-agent traces, with strong tool-call format adherence and SWE-bench-leading numbers in this size class. For harder reasoning-heavy tasks, DeepSeek-R1-Distill-Qwen-32B is the usual fallback at the cost of some context headroom.

## Configuration

All knobs are inlined directly in [docker-compose.yml](docker-compose.yml) — there is no `.env` file. Edit the YAML and `./docker-compose.sh up` to apply.

| Service | Key | Default | What it does |
| --- | --- | --- | --- |
| `open-webui` | `WEBUI_AUTH` | `False` | Toggle Open WebUI login flow |
| `open-webui` | `OPENAI_API_BASE_URL` | `http://lemonade:13305/v1` | Backend endpoint |
| `openhands` | `LLM_MODEL` | `openai/Qwen3-Coder-30B-A3B-Instruct-GGUF` | LiteLLM model id; **keep the `openai/` prefix** when talking to a generic OpenAI-compatible server |
| `openhands` | `AGENT_SERVER_IMAGE_TAG` | `1.15.0-python` | Sandbox runtime tag OpenHands spawns for each task |

The wrapper script also exports two dynamically-detected env vars consumed by the compose file:

| Variable | Source | Used by |
| --- | --- | --- |
| `VIDEO_GID` | `getent group video` (default `44`) | `lemonade.group_add` |
| `RENDER_GID` | `getent group render` (default `110`) | `lemonade.group_add` |

## Models

Lemonade has its own curated model catalog. Common operations from inside the `lemonade` container (or via the API):

```sh
docker compose exec lemonade ./lemonade list                    # available + installed
docker compose exec lemonade ./lemonade pull <model-name>       # download
docker compose exec lemonade ./lemonade rm <model-name>         # delete
```

See the [Lemonade CLI guide](https://lemonade-server.ai/docs/lemonade-cli/) for the full list.

## GPU notes

The compose file passes `/dev/kfd` and `/dev/dri` into the lemonade container and joins the host `render`/`video` groups via numeric GIDs (docker resolves group *names* against the container's `/etc/group`, not the host's, so names always fail with `unable to find group: no matching entries in group file`). The wrapper script reads the host GIDs at runtime, so there's nothing hardcoded.

```sh
getent group video  | cut -d: -f3   # almost always 44
getent group render | cut -d: -f3   # varies — 109, 110, 992, etc.
```

Supported architectures (per [llamacpp-rocm releases](https://github.com/lemonade-sdk/llamacpp-rocm/releases)):

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
docker compose logs --tail=200 openhands
docker compose exec lemonade rocminfo | head   # GPU visible inside the container?
```

If `rocminfo` fails inside the container but works on the host, the user isn't in the `render`/`video` groups — log out, log back in, then `./docker-compose.sh down && ./docker-compose.sh up`.

## Stopping & cleanup

```sh
./docker-compose.sh down             # stop the stack AND remove orphan agent containers
docker compose stop                  # stop, keep volumes (model cache persists)
docker compose down -v               # wipe volumes too (re-downloads models)
```

The wrapper's `down` mode targets:
- OpenHands runtime sandbox containers (`openhands/agent-server*` images, `openhands-*` names)

If the agent containers ever pile up because you ran plain `docker compose down`, run `./docker-compose.sh down` again to sweep them up — it's idempotent.
