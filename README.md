# Homelab

Configuration scripts for my personal homelab: workstation provisioning, local AI stacks, and desktop app deployment. Everything is idempotent — scripts can be re-run safely and skip whatever is already installed.

## Table of Contents

| Project | What it does | Getting started |
| --- | --- | --- |
| [Fedora Setup](fedora/) | Provisions a Fedora workstation: GitHub SSH key, git identity, Homebrew, devops tooling (gcloud, AWS CLI, kubectl, helm, terraform, kind, Docker, Podman Desktop), remote desktop (RDP), Tailscale, a fully local AI agent stack, desktop apps, and containerized web services (Open WebUI, Glance) | [Fedora](#fedora-setup) |
| [Windows Setup](windows/) | Bulk app installation for Windows 10/11 via a winget manifest | [Windows](#windows-setup) |

## Fedora Setup

[`fedora/setup.sh`](fedora/setup.sh) orchestrates the scripts in [`fedora/applications/`](fedora/applications/):

- [`homelab.sh`](fedora/applications/homelab.sh) — base system: SSH key, git identity, Homebrew, devops tooling, remote desktop (GNOME RDP on port 3389; prompts once for credentials — the session must be logged in, so enable GNOME auto-login for unattended access), and [Tailscale](https://tailscale.com/) (at boot)
- [`hermes.sh`](fedora/applications/hermes.sh) — fully local AI agents, no cloud accounts: LM Studio (headless, at boot) serving Qwen, with [Hermes](https://hermes-agent.nousresearch.com/) and [pi](https://pi.dev/) pointed at it; the Hermes web dashboard runs at boot
- [`desktop.sh`](fedora/applications/desktop.sh) — desktop apps: VS Code and Steam (RPM), Slack, Flatseal, Zotero (Flathub)
- [`docker/docker-compose.yml`](fedora/docker/docker-compose.yml) — containerized web services: [Open WebUI](https://github.com/open-webui/open-webui) (browser chat against the LM Studio endpoint) and the [Glance](https://github.com/glanceapp/glance) dashboard, whose config is version-controlled at [`docker/glance.yml`](fedora/docker/glance.yml)

### Web services

After setup, these are reachable in a browser (localhost, or over your tailnet via `tailscale serve`):

| Service | Address | Login | What it's for |
| --- | --- | --- | --- |
| Glance | [http://localhost:8181](http://localhost:8181) | none | Homelab dashboard: service health, bookmarks |
| Open WebUI | [http://localhost:8080](http://localhost:8080) | none (auth disabled) | Browser chat with the local Qwen model |
| Hermes dashboard | [http://localhost:9119](http://localhost:9119) | none | Hermes config, API keys, sessions |
| Speedtest Tracker | [http://localhost:8765](http://localhost:8765) | `admin@example.com` / `password` — change it | Hourly internet speed tests with history graphs |
| LM Studio API | [http://localhost:1234/v1](http://localhost:1234/v1) | none | OpenAI-compatible inference endpoint (API, not a UI) |

Speedtest Tracker ships with the default login above; change the password under Settings → Profile after first sign-in.

```sh
git clone https://github.com/stevenplatt/homelab.git
cd homelab/fedora
./setup.sh
```

When finished it prints your git identity and SSH public key for pasting into [github.com/settings/keys](https://github.com/settings/keys). Log out and back in afterward so the `docker` group membership takes effect.

### First-run configuration

Two things need a one-time manual step after `setup.sh` finishes.

**Tailscale** — setup.sh handles this at the end of its run: it runs `sudo tailscale up` (which prints a login URL — open it in a browser to authenticate, first run only), then uses Tailscale Serve to publish every homelab service over HTTPS to your tailnet, and prints the resulting URLs. Services stay bound to localhost — nothing is exposed publicly. From any device on your tailnet:

| Service | Tailnet address |
| --- | --- |
| Glance | `https://<machine>.<tailnet>.ts.net/` |
| Open WebUI | `https://<machine>.<tailnet>.ts.net:8080/` |
| Hermes dashboard | `https://<machine>.<tailnet>.ts.net:9119/` |
| Speedtest Tracker | `https://<machine>.<tailnet>.ts.net:8765/` |
| LM Studio API | `https://<machine>.<tailnet>.ts.net:1234/v1` |

setup.sh prints these with your machine's actual MagicDNS name filled in. Requires [MagicDNS and HTTPS enabled](https://tailscale.com/kb/1153/enabling-https) on your tailnet (Tailscale admin console → DNS) — certificates are then provisioned automatically.

**Hermes ↔ Slack** uses Slack Socket Mode — an outbound connection from the machine, so no Tailscale, ports, or Nous account are involved. Create the Slack app once by hand: run `hermes slack manifest --write`, paste the manifest at [api.slack.com/apps](https://api.slack.com/apps) (create new app → from manifest), and install it to your workspace. Then export the tokens and re-run setup:

```sh
export SLACK_BOT_TOKEN=xoxb-...   # bot token from the installed app
export SLACK_APP_TOKEN=xapp-...   # app-level (socket mode) token
export SLACK_ALLOWED_USERS=U...   # your slack member id — required, denies all others
./setup.sh
```

The script stores the tokens in `~/.hermes/.env` and installs the gateway as a service so Slack survives reboots. Invite the bot to a channel (`/invite @Hermes`) or just DM it. Full walkthrough: [Hermes Slack setup](https://hermes-agent.nousresearch.com/docs/user-guide/messaging/slack).

### Using Hermes

Everything runs locally: the Qwen model via LM Studio, no cloud accounts. Run `hermes` in a terminal to chat, or message it on Slack once the gateway is connected. The web dashboard at [localhost:9119](http://localhost:9119) manages config and sessions. Hermes builds skills and memory across sessions, so it improves with use — see the [Hermes docs](https://hermes-agent.nousresearch.com/docs/) for the full guide.

Some first requests to try (terminal or Slack):

> summarize the hardware in this machine and how much disk space is free

> watch the file ~/Desktop/homelab.log and tell me if any service failed

> clone github.com/glanceapp/glance, read the widget docs, and suggest three widgets for fedora/docker/glance.yml in my homelab repo

> every weekday at 8am, check my kind cluster is healthy and message me on slack if not

The last one exercises Hermes' cron + gateway features; the others exercise shell, file, and coding tools. Note that hosted tools (web search, image generation) are disabled in this local-only setup — Hermes will say so if a request needs them.

## Windows Setup

A [winget manifest](windows/win11_deploy.json) bulk-installs applications on Windows 10/11. From an administrator PowerShell:

```powershell
winget import -i windows\win11_deploy.json
```

## License

[MIT](LICENSE)
