# Docker — web services

Containerized web services for the Fedora homelab, brought up automatically by [`../setup.sh`](../setup.sh). Inference is **not** containerized — LM Studio runs on the host as a systemd user service (port 1234), and containers reach it via `host.docker.internal`.

| Service | Image | Address | Purpose |
| --- | --- | --- | --- |
| `open-webui` | `ghcr.io/open-webui/open-webui:main` | [http://localhost:8080](http://localhost:8080) | Browser chat, pre-wired to the LM Studio endpoint |
| `glance` | `glanceapp/glance:latest` | [http://localhost:8181](http://localhost:8181) | Homelab dashboard (service health, bookmarks) |
| `speedtest-tracker` | `lscr.io/linuxserver/speedtest-tracker:latest` | [http://localhost:8765](http://localhost:8765) | Hourly internet speed tests with history |
| `adguard` | `adguard/adguardhome:latest` | [http://localhost:3000](http://localhost:3000) (UI) · DNS on tailnet IP `:53` | Network-wide DNS filtering / ad-blocking |
| `caddy` | `caddy:latest` | `https://<machine>.<tailnet>.ts.net` (+ ports) | HTTPS proxy for the tailnet; certs from tailscaled ([`config/Caddyfile`](config/Caddyfile)) |

## Usage

Setup brings the stack up automatically. To manage it directly:

```sh
cd fedora/docker
docker compose --env-file config/.env up -d   # start (env-file supplies TS_IP → adguard's tailnet :53 bind)
docker compose ps          # health
docker compose logs -f     # logs
docker compose down        # stop (volumes preserved)
```

## Configuration

- **Glance** — [`config/glance.yml`](config/glance.yml) is version-controlled here and bind-mounted read-only into the container. Edit it, commit it, then `docker compose restart glance` (or re-run `../setup.sh`). Widget reference: [glance configuration docs](https://github.com/glanceapp/glance/blob/main/docs/configuration.md). Service links use `${TS_DNS_NAME}` (from `config/.env`, written by setup.sh) and point at the Caddy HTTPS ports.
- **Caddy** — [`Caddyfile`](Caddyfile) is version-controlled here with the HTTPS→backend port map (443→glance, 8443→open webui, 9443→hermes, 7443→speedtest, 5443→lm studio, 3443→adguard). It reads `${TS_DNS_NAME}` from the container env and fetches `.ts.net` certificates from the mounted tailscaled socket automatically.
- **Open WebUI** — knobs are inline in [`docker-compose.yml`](docker-compose.yml) (`WEBUI_AUTH`, `OPENAI_API_BASE_URL`). Chat data persists in the `open-webui-data` volume.
- **AdGuard Home** — first boot serves a setup wizard at [http://localhost:3000](http://localhost:3000); during it, set the **Admin Web Interface** port to **3000** so the UI stays there afterward (otherwise it moves to the container's default port 80, which isn't published). DNS binds this machine's **Tailscale IP on port 53** (see Notes) so the tailnet can use AdGuard as its resolver. Config and runtime data persist in the `adguard-conf` / `adguard-work` volumes; reach the UI over the tailnet at `https://<machine>.<tailnet>.ts.net:3443` via Caddy.

## Notes

- Glance publishes host port **8181** (container 8080) because Open WebUI owns host 8080.
- AdGuard's DNS binds this machine's **Tailscale IP on port 53** (`${TS_IP}:53`), not the usual all-interfaces `:53`. Tailscale's DNS feature only queries nameservers on port 53 (there's no port field in the admin console), so this is how the tailnet reaches AdGuard. Binding the *tailnet* IP specifically avoids Fedora's `systemd-resolved`, which owns `127.0.0.53:53` — a different IP, so there's no collision and nothing native is touched. `setup.sh` writes `TS_IP` into `config/.env` after joining the tailnet and passes it to Compose via `--env-file`; the `127.0.0.1` fallback keeps a pre-join or plain `docker compose up` off resolved's IP. To finish wiring it up, add `<tailnet-ip>:53` (from `tailscale ip -4`) as a nameserver at [login.tailscale.com/admin/dns](https://login.tailscale.com/admin/dns) and enable **Override local DNS**. Note: with bridge networking, per-client query stats show the Docker gateway IP rather than real client IPs.
- If `docker` fails with permission denied, your user's `docker` group membership hasn't taken effect yet — log out and back in (setup falls back to `sudo docker` until then).
- The previous Lemonade + OpenHands GPU inference stack that lived in this folder was retired in favor of host-side LM Studio; it's available in git history if needed.
