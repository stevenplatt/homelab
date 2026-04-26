# Docker — local LLM stack

A Docker Compose stack that runs AMD's [Lemonade Server](https://github.com/lemonade-sdk/lemonade) for local inference, with Open WebUI for browser chat, OpenHands for autonomous coding tasks, CrewAI Studio for visually designing multi-agent crews, and a development container with CrewAI and AgentStack pre-installed for code-first work.

Lemonade is purpose-built for AMD GPUs/NPUs and ships with ROCm 7 bundled inside the image. RDNA4 (gfx1201, **Radeon AI Pro R9700** and the RX 9070/9060 series) is a first-class supported target — no `HSA_OVERRIDE_GFX_VERSION` games, no host ROCm install.

## Services

| Service | Image / Source | Port | Purpose |
| --- | --- | --- | --- |
| `lemonade` | `ghcr.io/lemonade-sdk/lemonade-server:latest` | `13305` | OpenAI-compatible inference server (`/v1/...`) |
| `open-webui` | `ghcr.io/open-webui/open-webui:main` | `8080` | Browser chat UI, pre-wired to the lemonade endpoint |
| `openhands` | `docker.openhands.dev/openhands/openhands:1.6` | `3000` | Autonomous coding agent — give it a task and it drives a sandbox to completion |
| `crewai-studio` | built from `strnad/CrewAI-Studio` | `8501` | Streamlit GUI for designing and running CrewAI crews (no-code) |
| `crewai-db` | `postgres:15` | — | Postgres backing store for crewai-studio (internal only) |
| `agent-tools` | `./agent-tools` (built locally) | — | Long-running container with `crewai` + `agentstack` CLIs available; exec into it to write agents |

The services share the compose network; `open-webui`, `openhands`, `crewai-studio`, and `agent-tools` all reach lemonade at `http://lemonade:13305/v1`.

## Prerequisites

The Ansible playbook ([../ansible/steel_legend.yml](../ansible/steel_legend.yml)) handles the host setup:
- `docker.io` and `docker-compose-v2` installed
- Current user added to `docker`, `render`, `video` groups
- Docker service started and enabled

After running the playbook, **log out and back in** so the new group memberships take effect — otherwise `docker` commands will fail with permission denied.

## Setup

Use the wrapper script — it brings the stack up *and* cleans up the orphan containers OpenHands and AgentStack spawn outside the compose project on `down`:

```sh
mkdir -p workspace
./docker-compose.sh up
```

To tear everything down (including the agent-spawned sandbox containers):

```sh
./docker-compose.sh down
```

If you'd rather drive `docker compose` directly, that still works — but you'll have to find and remove the OpenHands runtime containers and the AgentStack/BeeAI kind-cluster nodes by hand after each `down`.

### Bootstrap AgentStack platform (one-time)

The `agent-tools` container has the AgentStack CLI installed but the *platform* (the runtime that backs the web UI) needs a one-time bootstrap that uses the host docker socket to spin up its own backing containers. After the first `up`:

```sh
docker compose exec agent-tools agentstack self install
docker compose exec agent-tools agentstack ui --host 0.0.0.0
```

Then browse to `http://localhost:8333`. The bootstrap state lives in the `agent-tools-home` volume so subsequent `up`s don't redo it. If `agentstack ui` reports a different port, update the `ports:` block on the `agent-tools` service in [docker-compose.yml](docker-compose.yml) accordingly.

> ⚠️ **Trust boundary:** `agent-tools` now bind-mounts `/var/run/docker.sock` (same pattern as `openhands`). It can spawn arbitrary containers on the host docker daemon. The `docker-compose.sh down` command sweeps up the agent-spawned containers it created.

The `lemonade` container starts with no model loaded. Pull one before first use:

```sh
docker compose exec lemonade ./lemonade pull Gemma-4-26B-A4B-it-GGUF
```

That's Gemma 4 26B-A4B (MoE) at 4-bit — ~14GB of weights with only ~4B parameters active per token, so it's fast on the R9700 and leaves plenty of VRAM for KV cache (~16GB free for context, easily 32K+ tokens). Confirm the exact catalog name with `./lemonade list` if the pull errors.

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

# OpenHands UI:
#   http://localhost:3000
# the LLM is preconfigured via env vars; first launch may show settings,
# just confirm the model and click save.

# CrewAI Studio UI:
#   http://localhost:8501
# in the model dropdown pick the OpenAI provider; the local lemonade endpoint
# and Gemma-4-26B-A4B-it-GGUF model are pre-wired via env vars.
```

Drop your CrewAI / AgentStack project files into the `./workspace` directory on the host — it's bind-mounted into the container at `/workspace`.

### Using OpenHands

OpenHands is the autonomous-agent surface: you give it a task, it spawns its own sandbox container (via the host docker socket) and drives it to completion — reading code, running shells, browsing the web. The compose file pre-points it at the local lemonade endpoint via `LLM_BASE_URL`, `LLM_API_KEY`, and `LLM_MODEL` (with the `openai/` prefix LiteLLM requires for generic OpenAI-compatible servers).

> ⚠️ **Trust boundary:** the `openhands` service bind-mounts `/var/run/docker.sock`, which gives it root-equivalent access to the host's docker daemon. It needs this to spawn agent-server sandbox containers. Only run this on a workstation you trust; don't expose port 3000 outside localhost.

A 26B+ model is roughly the practical floor for OpenHands to be useful — smaller models often loop or fail to follow the agent's tool-use protocol. Gemma 4 26B-A4B (the default in this stack) works for most tasks and benefits from large context windows; for harder multi-step problems, switching to a reasoning-tuned model like DeepSeek-R1-Distill-Qwen-32B is worth the trade-off in context room.

### Using CrewAI Studio

CrewAI Studio gives you a no-code Streamlit UI for assembling multi-agent crews — define agents, tasks, tools, and run a crew end-to-end — and persists everything in the `crewai-db` postgres. It's the visual counterpart to the code-first workflow inside `agent-tools`. The local lemonade endpoint is pre-wired via `OPENAI_API_BASE` / `OPENAI_API_KEY`, and `OPENAI_PROXY_MODELS` controls which model names show up in the dropdown.

Because the upstream project doesn't publish a pre-built image, the service builds from the [strnad/CrewAI-Studio](https://github.com/strnad/CrewAI-Studio) git repo on first `docker compose up`. The first build pulls a few hundred MB of Python deps and takes a couple of minutes; subsequent ups reuse the layer cache.

Crews and agent definitions live in the `crewai-db-data` volume — surviving `docker compose down` but wiped by `docker compose down -v`.

## Configuration

All knobs are inlined directly in [docker-compose.yml](docker-compose.yml) — there is no `.env` file. Edit the YAML and `docker compose up -d` to apply.

| Service | Key | Default | What it does |
| --- | --- | --- | --- |
| `agent-tools` | `OPENAI_MODEL_NAME` | `Gemma-4-26B-A4B-it-GGUF` | Model name `agent-tools` calls (must match what you've pulled) |
| `open-webui` | `WEBUI_AUTH` | `False` | Toggle Open WebUI login flow |
| `open-webui` / `agent-tools` | `OPENAI_API_BASE_URL` / `OPENAI_API_BASE` | `http://lemonade:13305/v1` | Backend endpoint |
| `openhands` | `LLM_MODEL` | `openai/Gemma-4-26B-A4B-it-GGUF` | LiteLLM model id; **keep the `openai/` prefix** when talking to a generic OpenAI-compatible server |
| `openhands` | `AGENT_SERVER_IMAGE_TAG` | `1.15.0-python` | Sandbox runtime tag OpenHands spawns for each task |
| `crewai-studio` | `OPENAI_PROXY_MODELS` | `Gemma-4-26B-A4B-it-GGUF` | Comma-separated list of model names shown in Studio's dropdown |
| `crewai-db` | `POSTGRES_USER`/`PASSWORD`/`DB` | `crewai`/`crewai`/`crewai` | Internal-only Postgres credentials |

## Models

Lemonade has its own curated model catalog. Common operations from inside the `lemonade` container (or via the API):

```sh
docker compose exec lemonade ./lemonade list                    # available + installed
docker compose exec lemonade ./lemonade pull <model-name>       # download
docker compose exec lemonade ./lemonade rm <model-name>         # delete
```

See the [Lemonade CLI guide](https://lemonade-server.ai/docs/lemonade-cli/) for the full list.

## GPU notes

The compose file passes `/dev/kfd` and `/dev/dri` into the container and joins the host `render`/`video` groups via numeric GIDs (docker resolves group *names* against the container's `/etc/group`, not the host's, so names always fail with `unable to find group: no matching entries in group file`). Confirm the GIDs on your host:

```sh
getent group video  | cut -d: -f3   # almost always 44
getent group render | cut -d: -f3   # varies — 109, 110, 992, etc.
```

If yours differ from `44` / `110`, edit `group_add` in [docker-compose.yml](docker-compose.yml) accordingly.
 Lemonade's bundled ROCm 7 handles the rest. Supported architectures (per [llamacpp-rocm releases](https://github.com/lemonade-sdk/llamacpp-rocm/releases)):

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
./docker-compose.sh down             # stop the stack AND remove orphan agent containers
docker compose stop                  # stop, keep volumes (model cache persists)
docker compose down -v               # wipe volumes too (re-downloads models)
```

The wrapper's `down` mode targets:
- OpenHands runtime sandbox containers (`openhands/agent-server*` images, `openhands-*` names)
- AgentStack/BeeAI kind cluster nodes (containers with the `io.x-k8s.kind.cluster` label)
- AgentStack/BeeAI platform containers (by name match)

If the agent containers ever pile up because you ran plain `docker compose down`, you can run `./docker-compose.sh down` again to sweep them up — it's idempotent.
