# Docker — web services

Containerized web services for the Fedora homelab, brought up automatically by [`../setup.sh`](../setup.sh). Inference is **not** containerized — LM Studio runs on the host as a systemd user service (port 1234), and containers reach it via `host.docker.internal`.

| Service | Image | Address | Purpose |
| --- | --- | --- | --- |
| `open-webui` | `ghcr.io/open-webui/open-webui:main` | [http://localhost:8080](http://localhost:8080) | Browser chat, pre-wired to the LM Studio endpoint |
| `glance` | `glanceapp/glance:latest` | [http://localhost:8181](http://localhost:8181) | Homelab dashboard (service health, bookmarks) |
| `speedtest-tracker` | `lscr.io/linuxserver/speedtest-tracker:latest` | [http://localhost:8765](http://localhost:8765) | Hourly internet speed tests with history |
| `caddy` | `caddy:latest` | `https://<machine>.<tailnet>.ts.net` (+ ports) | HTTPS proxy for the tailnet; certs from tailscaled ([`config/Caddyfile`](config/Caddyfile)) |

## Usage

Setup brings the stack up automatically. To manage it directly:

```sh
cd fedora/docker
docker compose up -d       # start
docker compose ps          # health
docker compose logs -f     # logs
docker compose down        # stop (volumes preserved)
```

## Configuration

- **Glance** — [`config/glance.yml`](config/glance.yml) is version-controlled here and bind-mounted read-only into the container. Edit it, commit it, then `docker compose restart glance` (or re-run `../setup.sh`). Widget reference: [glance configuration docs](https://github.com/glanceapp/glance/blob/main/docs/configuration.md). Service links use `${TS_DNS_NAME}` (from `config/.env`, written by setup.sh) and point at the Caddy HTTPS ports.
- **Caddy** — [`Caddyfile`](Caddyfile) is version-controlled here with the HTTPS→backend port map (443→glance, 8443→open webui, 9443→hermes, 7443→speedtest, 5443→lm studio). It reads `${TS_DNS_NAME}` from the container env and fetches `.ts.net` certificates from the mounted tailscaled socket automatically.
- **Open WebUI** — knobs are inline in [`docker-compose.yml`](docker-compose.yml) (`WEBUI_AUTH`, `OPENAI_API_BASE_URL`). Chat data persists in the `open-webui-data` volume.

## Notes

- Glance publishes host port **8181** (container 8080) because Open WebUI owns host 8080.
- If `docker` fails with permission denied, your user's `docker` group membership hasn't taken effect yet — log out and back in (setup falls back to `sudo docker` until then).
- The previous Lemonade + OpenHands GPU inference stack that lived in this folder was retired in favor of host-side LM Studio; it's available in git history if needed.
