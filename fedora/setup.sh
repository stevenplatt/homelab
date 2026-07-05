#!/usr/bin/env bash
#
# setup.sh — fedora setup orchestrator (tui)
#
# runs the installation scripts under applications/ behind a small tui:
# each script's full output is hidden and appended to homelab.log on the
# desktop, while the tui shows one status line per script with a spinner
# and the current task (parsed from the scripts' `==>` markers).
#
#   1. applications/homelab.sh — base system (ssh key, git identity,
#      homebrew, devops tooling, remote desktop)
#   2. applications/hermes.sh  — local ai agent stack (lm studio + qwen +
#      hermes + pi)
#   3. applications/desktop.sh — desktop applications (vscode, steam, slack,
#      flatseal, zotero)
#   4. docker/docker-compose.yml — web services (open-webui, glance)
#
# interactive answers (git identity, remote desktop credentials, sudo) are
# collected up front so the install steps can run unattended behind the tui.
#
# finishes by printing the github configuration (user, email, public key)
# so the key can be pasted into https://github.com/settings/keys.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# full logs land on the desktop (xdg dir when available)
DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
LOG_FILE="$DESKTOP_DIR/homelab.log"

if [[ "$(id -u)" -eq 0 ]]; then
    echo "error: run this script as your normal user, not root." >&2
    exit 1
fi

# ask for sudo once up front and keep the ticket fresh for the whole run.
# individual commands still elevate one at a time — nothing runs as root
# between sudo calls.
request_sudo() {
    echo "==> requesting sudo access (asked once, kept alive for this run)"
    sudo -v
    ( while kill -0 "$$" 2>/dev/null; do sudo -n -v 2>/dev/null; sleep 60; done ) &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT
}

# gather every interactive answer before the tui starts — prompts inside the
# install scripts would be invisible once their output is redirected to the
# log. answers are passed down via env vars the scripts prefer over prompting.
collect_inputs() {
    if [[ -z "$(git config --global --get user.name || true)" ]]; then
        read -r -p "enter git user.name: " GIT_USER_NAME
        export GIT_USER_NAME
    fi

    if [[ -z "$(git config --global --get user.email || true)" ]]; then
        read -r -p "enter git user.email: " GIT_USER_EMAIL
        export GIT_USER_EMAIL
    fi

    if ! { command -v grdctl > /dev/null 2>&1 \
            && grdctl status 2>/dev/null | grep -A2 'RDP' | grep -q 'enabled'; }; then
        read -r -p "enter remote desktop username: " RDP_USER
        read -r -s -p "enter remote desktop password: " RDP_PASS
        echo
        export RDP_USER RDP_PASS
    fi
}

# run one command with its output hidden in $LOG_FILE, showing a spinner and
# the command's most recent `==>` marker as a live status line.
run_step() {
    local label="$1" cmd="$2"
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0 offset current pid

    offset="$(wc -l < "$LOG_FILE")"
    bash -c "$cmd" >> "$LOG_FILE" 2>&1 &
    pid=$!

    if [[ -t 1 ]]; then
        while kill -0 "$pid" 2>/dev/null; do
            current="$(tail -n +"$((offset + 1))" "$LOG_FILE" \
                | grep '^==>' | tail -n 1 | cut -c5- || true)"
            printf '\r\033[K [%s] %s%s' \
                "${frames[i++ % 10]}" "$label" "${current:+ — $current}"
            sleep 0.2
        done
    fi

    if wait "$pid"; then
        printf '\r\033[K [✔] %s\n' "$label"
    else
        printf '\r\033[K [✘] %s — failed\n' "$label"
        echo
        echo "last lines of $LOG_FILE:" >&2
        tail -n 20 "$LOG_FILE" >&2
        exit 1
    fi
}

# join the tailnet and expose the homelab services over it. runs after the
# tui because first-time auth prints a login url the user must open.
setup_tailnet() {
    if ! command -v tailscale > /dev/null 2>&1; then
        echo "tailscale not installed — skipping tailnet setup"
        return 0
    fi

    if ! tailscale status > /dev/null 2>&1; then
        echo "==> joining the tailnet — open the login url below in a browser"
        sudo tailscale up
    fi

    local ts_name
    ts_name="$(tailscale status --json | jq -r '.Self.DNSName' | sed 's/\.$//')"

    # rebind the hermes dashboard to the tailnet dns name (it validates the
    # Host header, so it cannot sit behind `tailscale serve` — see hermes.sh)
    bash "$SCRIPT_DIR/applications/hermes.sh" dashboard-service

    # services bind 0.0.0.0, so they are directly reachable on the tailnet
    # over plain http (wireguard encrypts transport). `tailscale serve` is
    # NOT used: its https proxies lose to the direct plaintext listeners on
    # the same ports and its state breaks on machine renames — clear any
    # entries left over from previous setups
    sudo tailscale serve reset > /dev/null 2>&1 || true

    # point the glance links and caddy https proxy at the tailnet dns name
    # (read from docker/config/.env, git-ignored) and apply. caddy fetches
    # .ts.net certs from tailscaled — requires magicdns + https enabled on
    # the tailnet: https://tailscale.com/kb/1153/enabling-https
    local docker_env="$SCRIPT_DIR/docker/config/.env"
    touch "$docker_env"
    sed -i '/^TS_DNS_NAME=/d;/^TS_SCHEME=/d;/^SPEEDTEST_APP_URL=/d;/^APP_URL=/d' "$docker_env"
    printf 'TS_DNS_NAME=%s\nAPP_URL=https://%s:7443\n' "$ts_name" "$ts_name" >> "$docker_env"
    if docker info > /dev/null 2>&1; then
        docker compose -f "$SCRIPT_DIR/docker/docker-compose.yml" up -d > /dev/null 2>&1
    else
        sudo docker compose -f "$SCRIPT_DIR/docker/docker-compose.yml" up -d > /dev/null 2>&1
    fi

    echo "================================================================"
    echo "homelab services — reachable from any device on your tailnet"
    echo "(https via caddy; plain-http fallbacks stay on the original ports)"
    echo "----------------------------------------------------------------"
    echo "glance dashboard:   https://${ts_name}/"
    echo "open webui (chat):  https://${ts_name}:8443/"
    echo "hermes dashboard:   https://${ts_name}:9443/"
    echo "                    (login: HERMES_DASHBOARD_BASIC_AUTH_* in ~/.hermes/.env)"
    echo "speedtest tracker:  https://${ts_name}:7443/"
    echo "lm studio api:      https://${ts_name}:5443/v1"
    echo "================================================================"
}

confirm_github_config() {
    echo "================================================================"
    echo "github configuration"
    echo "----------------------------------------------------------------"
    echo "git user.name:  $(git config --global --get user.name || echo '<not set>')"
    echo "git user.email: $(git config --global --get user.email || echo '<not set>')"
    echo ""
    echo "copy the following public key into your github account:"
    echo "https://github.com/settings/keys"
    echo "----------------------------------------------------------------"
    cat "$HOME/.ssh/id_ed25519.pub"
    echo "================================================================"
}

main() {
    request_sudo
    collect_inputs

    mkdir -p "$DESKTOP_DIR"
    echo "homelab setup — $(date)" > "$LOG_FILE"

    # clear stale tailscale serve state BEFORE services start — leftover
    # https proxies hold ports (e.g. 1234) and block the lm studio bind.
    # setup_tailnet also resets at the end; this covers re-runs.
    if command -v tailscale > /dev/null 2>&1; then
        sudo tailscale serve reset > /dev/null 2>&1 || true
    fi

    echo
    echo "homelab setup"
    echo "full install logs: $LOG_FILE"
    echo "----------------------------------------------------------------"
    run_step "base system (homelab.sh)" "bash $SCRIPT_DIR/applications/homelab.sh"
    run_step "ai agent stack (hermes.sh)" "bash $SCRIPT_DIR/applications/hermes.sh"
    run_step "desktop applications (desktop.sh)" "bash $SCRIPT_DIR/applications/desktop.sh"
    # docker group membership needs a re-login; fall back to sudo until then.
    # seed config/.env so the containers start with localhost urls before
    # the tailnet step rewrites it with the real dns name
    run_step "web services (docker compose)" "\
        echo '==> starting web services (open-webui, glance, speedtest, caddy)'; \
        [ -f $SCRIPT_DIR/docker/config/.env ] || printf 'TS_DNS_NAME=localhost\n' > $SCRIPT_DIR/docker/config/.env; \
        if docker info > /dev/null 2>&1; then \
            docker compose -f $SCRIPT_DIR/docker/docker-compose.yml up -d; \
        else \
            sudo docker compose -f $SCRIPT_DIR/docker/docker-compose.yml up -d; \
        fi"
    echo "----------------------------------------------------------------"
    setup_tailnet
    echo "==> setup complete"
    echo
    confirm_github_config
}

main "$@"
