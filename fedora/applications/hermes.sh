#!/usr/bin/env bash
#
# hermes.sh — local ai agent stack (fedora)
#
# installs lm studio headless (llmster), downloads the qwen model, runs the
# lm studio openai-compatible endpoint at boot, then installs the hermes
# agent and the pi coding agent — both pointed at the local qwen endpoint.
#
# safe to re-run: every step checks before it installs/downloads.
# run as your normal user; sudo is used where root is required.

set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
    echo "error: run this script as your normal user, not root." >&2
    exit 1
fi

# resolve the invoking user from the session, not the environment
CURRENT_USER="$(whoami)"

# sudo is missing on minimal installs — bootstrap it via su if needed
if ! command -v sudo > /dev/null 2>&1; then
    echo "sudo not found — installing it (enter the root password when prompted)"
    su -c "dnf install -y sudo && usermod -aG wheel $CURRENT_USER"
    echo "sudo installed and $CURRENT_USER added to the wheel group."
    echo "log out and back in, then re-run this script."
    exit 1
fi

# ask for sudo once up front and keep the ticket fresh for the whole run
# (no-op prompt when already primed by setup.sh). individual commands still
# elevate one at a time — nothing runs as root between sudo calls.
request_sudo() {
    sudo -v
    ( while kill -0 "$$" 2>/dev/null; do sudo -n -v 2>/dev/null; sleep 60; done ) &
    SUDO_KEEPALIVE_PID=$!
    trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null' EXIT
}

MODEL_KEY="qwen/qwen3.6-35b-a3b"          # https://lmstudio.ai/models/qwen/qwen3.6-35b-a3b
MODEL_ALIAS="homelab-qwen3.6"             # id served on the api — what open webui/hermes/pi display and request
LMS_BIN="$HOME/.lmstudio/bin/lms"
LMS_ENDPOINT="http://localhost:1234/v1"   # lm studio server default port

# ---------------------------------------------------------------
# 1. install lm studio (headless cli + daemon)
# ---------------------------------------------------------------
# true only when the lms cli can reach a working daemon
lms_daemon_ready() {
    "$LMS_BIN" daemon up > /dev/null 2>&1 && "$LMS_BIN" ls > /dev/null 2>&1
}

# the desktop app runs its own built-in daemon that blocks standalone
# llmster from starting and rejects the standalone cli's key. match gui
# processes but not the headless daemon/cli living under ~/.lmstudio/
lmstudio_gui_pids() {
    pgrep -fa '[Ll][Mm][-_ ]?[Ss]tudio' 2>/dev/null \
        | grep -v -e llmster -e '\.lmstudio/' \
        | awk '{print $1}'
}

lmstudio_gui_running() {
    [[ -n "$(lmstudio_gui_pids)" ]]
}

# force quit the desktop app so the headless daemon can start
stop_lmstudio_gui() {
    lmstudio_gui_running || return 0

    echo "lm studio desktop app is running — force quitting it (its built-in"
    echo "daemon conflicts with the headless one)"

    # graceful first, then force whatever survives
    lmstudio_gui_pids | xargs -r kill 2>/dev/null || true
    local i
    for i in 1 2 3 4 5; do
        lmstudio_gui_running || return 0
        sleep 1
    done
    lmstudio_gui_pids | xargs -r kill -9 2>/dev/null || true
    sleep 1
}

install_lmstudio() {
    echo "==> installing lm studio (headless)"

    stop_lmstudio_gui

    # a manual gui/appimage install also provides $LMS_BIN but ships without
    # the headless daemon (llmster), so the binary existing is not enough —
    # verify the daemon responds, and (re)run the headless installer if not.
    # installer source: https://lmstudio.ai/docs/developer/core/headless_llmster
    if [[ -x "$LMS_BIN" ]] && lms_daemon_ready; then
        echo "lm studio already installed and daemon responding"
        return
    fi

    curl -fsSL https://lmstudio.ai/install.sh | bash
}

# ---------------------------------------------------------------
# 2. download the qwen model (skipped if already present)
# ---------------------------------------------------------------
download_qwen_model() {
    echo "==> ensuring model ${MODEL_KEY} is downloaded"

    # the lms cli talks to the lm studio daemon — start it first, or every
    # lms command fails with ENOENT on .lmstudio/.internal/lms-key-* (the
    # daemon creates that key file on its first startup)
    "$LMS_BIN" daemon up || true

    local attempt
    for attempt in 1 2 3 4 5; do
        if "$LMS_BIN" ls > /dev/null 2>&1; then
            break
        fi
        echo "waiting for lm studio daemon (attempt $attempt/5)..."
        sleep 2
        "$LMS_BIN" daemon up > /dev/null 2>&1 || true
    done

    if ! "$LMS_BIN" ls > /dev/null 2>&1; then
        echo "error: lm studio daemon is not responding." >&2
        if lmstudio_gui_running; then
            echo "the lm studio desktop app is running — its built-in daemon blocks" >&2
            echo "the headless one. quit the app (check the tray) and re-run setup." >&2
        else
            echo "try reinstalling the headless daemon:" >&2
            echo "  curl -fsSL https://lmstudio.ai/install.sh | bash" >&2
        fi
        exit 1
    fi

    if "$LMS_BIN" ls 2>/dev/null | grep -q "qwen3.6-35b-a3b"; then
        echo "model already downloaded — skipping"
        return
    fi

    # `lms get` renders a live progress bar in the terminal for the download
    "$LMS_BIN" get "$MODEL_KEY" --yes
}

# ---------------------------------------------------------------
# 3. lm studio daemon + endpoint at boot
# ---------------------------------------------------------------
setup_lmstudio_service() {
    echo "==> configuring lm studio systemd service"

    # a system unit can't exec binaries under \$HOME on fedora (selinux denies
    # init_t → user_home_t, failing with 203/EXEC), so run a systemd *user*
    # service instead; lingering makes it start at boot without a login.
    # unit layout from: https://lmstudio.ai/docs/developer/core/headless_llmster
    local unit_dir="$HOME/.config/systemd/user"
    local unit_path="$unit_dir/lmstudio.service"
    local tmp_unit
    tmp_unit="$(mktemp)"

    # drop the old (broken) system-level unit if a previous run created it
    if [[ -f /etc/systemd/system/lmstudio.service ]]; then
        sudo systemctl disable --now lmstudio.service 2>/dev/null || true
        sudo rm -f /etc/systemd/system/lmstudio.service
        sudo systemctl daemon-reload
    fi

    mkdir -p "$unit_dir"

    cat > "$tmp_unit" <<EOF
[Unit]
Description=LM Studio Server

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=$LMS_BIN daemon up
ExecStartPre=/bin/bash -c '$LMS_BIN ps | grep -q "$MODEL_ALIAS" || $LMS_BIN load $MODEL_KEY --identifier $MODEL_ALIAS --yes'
ExecStart=$LMS_BIN server start --bind 0.0.0.0
ExecStop=$LMS_BIN daemon down

[Install]
WantedBy=default.target
EOF

    # --bind 0.0.0.0: docker containers (open-webui, glance) reach the
    # endpoint via host.docker.internal, which arrives on the docker bridge —
    # a 127.0.0.1 bind refuses those connections. loopback clients
    # (hermes, pi) are unaffected. note this also exposes the port on the
    # lan; fedora workstation's default firewall zone permits it.
    local unit_changed=0
    if ! cmp -s "$tmp_unit" "$unit_path" 2>/dev/null; then
        cp "$tmp_unit" "$unit_path"
        systemctl --user daemon-reload
        unit_changed=1
    fi
    rm -f "$tmp_unit"

    systemctl --user enable --now lmstudio.service

    # enable --now does not restart an already-running service, so apply
    # unit changes explicitly
    if [[ "$unit_changed" -eq 1 ]]; then
        systemctl --user restart lmstudio.service
    fi

    # start the user service at boot without waiting for a login
    sudo loginctl enable-linger "$CURRENT_USER"
}

# ---------------------------------------------------------------
# 4. install hermes agent
# ---------------------------------------------------------------
install_hermes() {
    echo "==> installing hermes agent"

    # installer source: https://hermes-agent.nousresearch.com/docs/getting-started/quickstart
    if command -v hermes > /dev/null 2>&1 || [[ -x "$HOME/.local/bin/hermes" ]]; then
        echo "hermes already installed"
        return
    fi

    # --skip-setup: the installer otherwise launches an interactive wizard
    # that would hang invisibly behind the setup.sh tui. everything runs
    # locally against lm studio — no nous portal account is used.
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-setup
}

configure_hermes() {
    echo "==> pointing hermes at the lm studio endpoint"

    local hermes_bin
    hermes_bin="$(command -v hermes || echo "$HOME/.local/bin/hermes")"

    # lm studio is a first-class hermes provider (defaults to
    # http://127.0.0.1:1234/v1) — see the model section of ~/.hermes/config.yaml.
    # the alias matches the --identifier the systemd unit loads the model with
    "$hermes_bin" config set model.provider lmstudio
    "$hermes_bin" config set model.default "$MODEL_ALIAS"
}

# the dashboard's basic-auth provider is required for any non-loopback bind
# (hermes fails closed without it). generates credentials once into
# ~/.hermes/.env; env var names from:
# https://hermes-agent.nousresearch.com/docs/user-guide/features/web-dashboard
ensure_dashboard_auth() {
    local env_file="$HOME/.hermes/.env"
    mkdir -p "$HOME/.hermes"

    if ! grep -q '^HERMES_DASHBOARD_BASIC_AUTH_USERNAME=' "$env_file" 2>/dev/null; then
        {
            echo "HERMES_DASHBOARD_BASIC_AUTH_USERNAME=admin"
            echo "HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=$(openssl rand -base64 16)"
            echo "HERMES_DASHBOARD_BASIC_AUTH_SECRET=$(openssl rand -base64 32)"
        } >> "$env_file"
        chmod 600 "$env_file"
        echo "dashboard basic-auth credentials generated in $env_file"
    fi
}

setup_hermes_dashboard_service() {
    echo "==> configuring hermes dashboard service (no browser auto-open)"

    local hermes_bin
    hermes_bin="$(command -v hermes || echo "$HOME/.local/bin/hermes")"

    # hermes rejects requests whose Host header differs from the bound host
    # (dns-rebinding defence — no allowlist exists), so proxying it through
    # `tailscale serve` cannot work. instead bind the tailnet dns name
    # directly when joined; that requires the basic-auth provider.
    local dash_host="127.0.0.1" ts_name=""
    if command -v tailscale > /dev/null 2>&1 && tailscale status > /dev/null 2>&1; then
        ts_name="$(tailscale status --json | jq -r '.Self.DNSName' | sed 's/\.$//')"
    fi
    if [[ -n "$ts_name" ]]; then
        dash_host="$ts_name"
        ensure_dashboard_auth
        echo "dashboard will bind the tailnet dns name: http://${dash_host}:9119"
    fi

    # systemd user service (same selinux reasoning as the lm studio unit);
    # lingering — enabled in setup_lmstudio_service — starts it at boot.
    # Restart/RestartSec also cover boot ordering: the bind fails until
    # tailscaled is up, then succeeds on retry.
    local unit_dir="$HOME/.config/systemd/user"
    local unit_path="$unit_dir/hermes-dashboard.service"
    local tmp_unit
    tmp_unit="$(mktemp)"

    mkdir -p "$unit_dir"

    cat > "$tmp_unit" <<EOF
[Unit]
Description=Hermes Agent Dashboard

[Service]
EnvironmentFile=-%h/.hermes/.env
ExecStart=$hermes_bin dashboard --no-open --host $dash_host
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
EOF

    local unit_changed=0
    if ! cmp -s "$tmp_unit" "$unit_path" 2>/dev/null; then
        cp "$tmp_unit" "$unit_path"
        systemctl --user daemon-reload
        unit_changed=1
    fi
    rm -f "$tmp_unit"

    systemctl --user enable --now hermes-dashboard.service
    if [[ "$unit_changed" -eq 1 ]]; then
        systemctl --user restart hermes-dashboard.service
    fi
}

configure_hermes_slack() {
    echo "==> configuring hermes slack gateway"

    # slack setup guide: https://hermes-agent.nousresearch.com/docs/user-guide/messaging/slack
    # the slack app itself must be created once by hand (slack has no api for
    # this): run `hermes slack manifest --write`, paste the manifest at
    # https://api.slack.com/apps (create new app → from manifest), install it
    # to the workspace, then export SLACK_BOT_TOKEN / SLACK_APP_TOKEN /
    # SLACK_ALLOWED_USERS and re-run this script.
    if [[ -z "${SLACK_BOT_TOKEN:-}" || -z "${SLACK_APP_TOKEN:-}" ]]; then
        echo "SLACK_BOT_TOKEN / SLACK_APP_TOKEN not set — skipping slack gateway"
        return
    fi

    local env_file="$HOME/.hermes/.env"
    mkdir -p "$HOME/.hermes"

    if [[ -f "$env_file" ]] && grep -q "^SLACK_BOT_TOKEN=" "$env_file"; then
        echo "slack tokens already configured in $env_file"
    else
        {
            echo "SLACK_BOT_TOKEN=$SLACK_BOT_TOKEN"
            echo "SLACK_APP_TOKEN=$SLACK_APP_TOKEN"
            echo "SLACK_ALLOWED_USERS=${SLACK_ALLOWED_USERS:-}"
        } >> "$env_file"
        chmod 600 "$env_file"
    fi

    # register the gateway as a service so slack keeps working after reboot
    local hermes_bin
    hermes_bin="$(command -v hermes || echo "$HOME/.local/bin/hermes")"
    "$hermes_bin" gateway install
}

# ---------------------------------------------------------------
# 5. install pi coding agent
# ---------------------------------------------------------------
install_pi() {
    echo "==> installing pi coding agent"

    if ! command -v npm > /dev/null 2>&1; then
        sudo dnf install -y nodejs npm
    fi

    # install command from: https://pi.dev/
    if ! command -v pi > /dev/null 2>&1; then
        sudo npm install -g --ignore-scripts @earendil-works/pi-coding-agent
    else
        echo "pi already installed"
    fi
}

configure_pi() {
    echo "==> pointing pi at the lm studio endpoint"

    local ext_dir="$HOME/.pi/agent/extensions"
    local ext_file="$ext_dir/lmstudio.js"
    local settings="$HOME/.pi/agent/settings.json"

    mkdir -p "$ext_dir"

    if [[ ! -f "$ext_file" ]]; then
        cat > "$ext_file" <<EOF
// registers the local lm studio endpoint as a pi provider.
// pattern from: https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/docs/custom-provider.md
export default async function (pi) {
  const response = await fetch("$LMS_ENDPOINT/models");
  const payload = await response.json();

  pi.registerProvider("lmstudio", {
    baseUrl: "$LMS_ENDPOINT",
    apiKey: "lm-studio",
    api: "openai-completions",
    models: payload.data.map((model) => ({
      id: model.id,
      name: model.name ?? model.id,
      reasoning: false,
      input: ["text"],
      cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
      contextWindow: model.context_window ?? 128000,
      maxTokens: model.max_tokens ?? 4096,
    })),
  });
}
EOF
    else
        echo "pi lmstudio extension already present"
    fi

    # settings keys from: https://github.com/badlogic/pi-mono/blob/main/packages/coding-agent/docs/settings.md
    if [[ -f "$settings" ]]; then
        command -v jq > /dev/null 2>&1 || sudo dnf install -y jq
        local tmp_settings
        tmp_settings="$(mktemp)"
        jq --arg model "$MODEL_ALIAS" \
            '.defaultProvider = "lmstudio" | .defaultModel = $model' \
            "$settings" > "$tmp_settings"
        mv "$tmp_settings" "$settings"
    else
        cat > "$settings" <<EOF
{
  "defaultProvider": "lmstudio",
  "defaultModel": "$MODEL_ALIAS"
}
EOF
    fi
}

# ---------------------------------------------------------------
# main
# ---------------------------------------------------------------
main() {
    request_sudo
    install_lmstudio
    download_qwen_model
    setup_lmstudio_service
    install_hermes
    configure_hermes
    setup_hermes_dashboard_service
    configure_hermes_slack
    install_pi
    configure_pi

    echo "==> hermes stack ready — endpoint: $LMS_ENDPOINT (model: $MODEL_ALIAS)"
}

# `hermes.sh dashboard-service` re-runs only the dashboard unit setup —
# used by setup.sh to rebind the dashboard right after the tailnet is joined
if [[ "${1:-}" == "dashboard-service" ]]; then
    setup_hermes_dashboard_service
else
    main "$@"
fi
