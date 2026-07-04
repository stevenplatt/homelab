# Homelab

Configuration scripts for my personal homelab: workstation provisioning, local AI stacks, and desktop app deployment. Everything is idempotent — scripts can be re-run safely and skip whatever is already installed.

## Table of Contents

| Project | What it does | Getting started |
| --- | --- | --- |
| [Fedora Setup](fedora/) | Provisions a Fedora workstation: GitHub SSH key, git identity, Homebrew, devops tooling (gcloud, AWS CLI, kubectl, helm, terraform, kind, Docker, Podman Desktop), remote desktop (RDP), a local AI agent stack, and desktop apps | [Fedora](#fedora-setup) |
| [Docker LLM Stack](docker/) | Docker Compose stack for local inference on AMD GPUs: Lemonade Server + Open WebUI + OpenHands | [Docker](#docker-llm-stack) |
| [Windows Setup](windows/) | Bulk app installation for Windows 10/11 via a winget manifest | [Windows](#windows-setup) |

## Fedora Setup

[`fedora/setup.sh`](fedora/setup.sh) orchestrates the scripts in [`fedora/applications/`](fedora/applications/):

- [`homelab.sh`](fedora/applications/homelab.sh) — base system: SSH key, git identity, Homebrew, devops tooling, remote desktop (GNOME RDP on port 3389; prompts once for credentials — the session must be logged in, so enable GNOME auto-login for unattended access)
- [`hermes.sh`](fedora/applications/hermes.sh) — local AI agents: LM Studio (headless, at boot) serving Qwen, with [Hermes](https://hermes-agent.nousresearch.com/) and [pi](https://pi.dev/) pointed at it
- [`desktop.sh`](fedora/applications/desktop.sh) — desktop apps: VS Code and Steam (RPM), Slack, Flatseal, Zotero (Flathub)

```sh
git clone https://github.com/stevenplatt/homelab.git
cd homelab/fedora
./setup.sh
```

When finished it prints your git identity and SSH public key for pasting into [github.com/settings/keys](https://github.com/settings/keys). Log out and back in afterward so the `docker` group membership takes effect.

### Using Hermes

Run `hermes` in a terminal to chat — it's preconfigured to use the local Qwen model via LM Studio. `hermes setup --portal` (optional, one-time) unlocks Nous's hosted tools like web search and image generation. Hermes builds skills and memory across sessions, so it improves with use. See the [Hermes docs](https://hermes-agent.nousresearch.com/docs/) for the full guide.

**Slack:** to talk to Hermes from Slack, create the Slack app once by hand — run `hermes slack manifest --write`, paste the manifest at [api.slack.com/apps](https://api.slack.com/apps) (create new app → from manifest), and install it to your workspace. Then export the tokens and re-run setup:

```sh
export SLACK_BOT_TOKEN=xoxb-...   # bot token from the installed app
export SLACK_APP_TOKEN=xapp-...   # app-level (socket mode) token
export SLACK_ALLOWED_USERS=U...   # your slack member id — required, denies all others
./setup.sh
```

The script stores the tokens in `~/.hermes/.env` and installs the gateway as a service so Slack survives reboots. Invite the bot to a channel or DM it. Full walkthrough: [Hermes Slack setup](https://hermes-agent.nousresearch.com/docs/user-guide/messaging/slack).

## Docker LLM Stack

A compose stack for local LLM inference on AMD GPUs (ROCm bundled, RDNA2–4): [Lemonade Server](https://github.com/lemonade-sdk/lemonade) as an OpenAI-compatible endpoint, Open WebUI for browser chat, and OpenHands for autonomous coding. See the [full documentation](docker/README.md) for GPU notes, model management, and troubleshooting.

```sh
cd homelab/docker
./docker-compose.sh up     # brings up the stack, pulls the model, waits for readiness
./docker-compose.sh down   # tears down, including OpenHands sandbox containers
```

## Windows Setup

A [winget manifest](windows/win11_deploy.json) bulk-installs applications on Windows 10/11. From an administrator PowerShell:

```powershell
winget import -i windows\win11_deploy.json
```

## License

[MIT](LICENSE)
