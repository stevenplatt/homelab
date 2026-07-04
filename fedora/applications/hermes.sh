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

# sudo is missing on minimal installs — bootstrap it via su if needed
if ! command -v sudo > /dev/null 2>&1; then
    echo "sudo not found — installing it (enter the root password when prompted)"
    su -c "dnf install -y sudo && usermod -aG wheel $USER"
    echo "sudo installed and $USER added to the wheel group."
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
LMS_BIN="$HOME/.lmstudio/bin/lms"
LMS_ENDPOINT="http://localhost:1234/v1"   # lm studio server default port

# ---------------------------------------------------------------
# 1. install lm studio (headless cli + daemon)
# ---------------------------------------------------------------
install_lmstudio() {
    echo "==> installing lm studio (headless)"

    # installer source: https://lmstudio.ai/docs/developer/core/headless_llmster
    if [[ ! -x "$LMS_BIN" ]]; then
        curl -fsSL https://lmstudio.ai/install.sh | bash
    else
        echo "lm studio already installed at $LMS_BIN"
    fi
}

# ---------------------------------------------------------------
# 2. download the qwen model (skipped if already present)
# ---------------------------------------------------------------
download_qwen_model() {
    echo "==> ensuring model ${MODEL_KEY} is downloaded"

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

    # unit layout from: https://lmstudio.ai/docs/developer/core/headless_llmster
    local unit_path="/etc/systemd/system/lmstudio.service"
    local tmp_unit
    tmp_unit="$(mktemp)"

    cat > "$tmp_unit" <<EOF
[Unit]
Description=LM Studio Server
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
User=$USER
Environment="HOME=$HOME"
ExecStartPre=$LMS_BIN daemon up
ExecStartPre=$LMS_BIN load $MODEL_KEY --yes
ExecStart=$LMS_BIN server start
ExecStop=$LMS_BIN daemon down

[Install]
WantedBy=multi-user.target
EOF

    if ! sudo cmp -s "$tmp_unit" "$unit_path" 2>/dev/null; then
        sudo cp "$tmp_unit" "$unit_path"
        sudo systemctl daemon-reload
    fi
    rm -f "$tmp_unit"

    sudo systemctl enable --now lmstudio.service
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

    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
}

configure_hermes() {
    echo "==> pointing hermes at the lm studio endpoint"

    local config="$HOME/.hermes/config.yaml"
    mkdir -p "$HOME/.hermes"

    if [[ -f "$config" ]] && grep -q "$LMS_ENDPOINT" "$config"; then
        echo "hermes already configured for $LMS_ENDPOINT"
        return
    fi

    if [[ -f "$config" ]]; then
        cp "$config" "${config}.bak"
        echo "existing hermes config backed up to ${config}.bak"
    fi

    # config format from: https://hermes-agent.nousresearch.com/docs/integrations/providers
    cat > "$config" <<EOF
model:
  default: $MODEL_KEY
  provider: custom
  base_url: $LMS_ENDPOINT
EOF
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
        jq --arg model "$MODEL_KEY" \
            '.defaultProvider = "lmstudio" | .defaultModel = $model' \
            "$settings" > "$tmp_settings"
        mv "$tmp_settings" "$settings"
    else
        cat > "$settings" <<EOF
{
  "defaultProvider": "lmstudio",
  "defaultModel": "$MODEL_KEY"
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
    configure_hermes_slack
    install_pi
    configure_pi

    echo "==> hermes stack ready — endpoint: $LMS_ENDPOINT (model: $MODEL_KEY)"
}

main "$@"
