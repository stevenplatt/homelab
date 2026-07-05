#!/usr/bin/env bash
#
# homelab.sh — fedora base system setup
# converted from ansible/steel_legend.yml for fedora (dnf-based) systems.
# called by setup.sh, the orchestrator.
#
# steps:
#   1. ensure github ssh key exists
#   2. configure git user identity
#   3. install linux homebrew
#   4. install devops tooling (gcloud, aws cli, helm, terraform, kubectl,
#      kind, podman desktop, docker daemon, docker compose)
#   5. enable remote desktop access (gnome rdp, port 3389)
#   6. install tailscale (started at boot; auth with `sudo tailscale up`)
#
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

# ---------------------------------------------------------------
# 1. ensure github ssh key exists
# ---------------------------------------------------------------
ensure_github_ssh_key() {
    echo "==> ensuring github ssh key exists"

    local ssh_key_path="$HOME/.ssh/id_ed25519"

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if [[ ! -f "$ssh_key_path" ]]; then
        ssh-keygen -t ed25519 -f "$ssh_key_path" -N "" -C "$(whoami)@$(hostname)"
    else
        echo "ssh key already exists at $ssh_key_path"
    fi

    # add key to running ssh-agent (best effort — requires SSH_AUTH_SOCK)
    ssh-add "$ssh_key_path" 2>/dev/null || true
}

# ---------------------------------------------------------------
# 2. configure git user identity
# ---------------------------------------------------------------
configure_git_identity() {
    echo "==> configuring git user identity"

    local git_name git_email

    # GIT_USER_NAME / GIT_USER_EMAIL are pre-collected by setup.sh so this
    # step stays unattended behind the tui; prompt only when run standalone
    git_name="$(git config --global --get user.name || true)"
    if [[ -z "${git_name// /}" ]]; then
        git_name="${GIT_USER_NAME:-}"
        if [[ -z "${git_name// /}" ]]; then
            read -r -p "enter git user.name: " git_name
        fi
        if [[ -n "${git_name// /}" ]]; then
            git config --global user.name "$git_name"
        fi
    else
        echo "git user.name already set: $git_name"
    fi

    git_email="$(git config --global --get user.email || true)"
    if [[ -z "${git_email// /}" ]]; then
        git_email="${GIT_USER_EMAIL:-}"
        if [[ -z "${git_email// /}" ]]; then
            read -r -p "enter git user.email: " git_email
        fi
        if [[ -n "${git_email// /}" ]]; then
            git config --global user.email "$git_email"
        fi
    else
        echo "git user.email already set: $git_email"
    fi
}

# ---------------------------------------------------------------
# 3. install linux homebrew
# ---------------------------------------------------------------
install_homebrew() {
    echo "==> installing linux homebrew"

    local brew_bin="/home/linuxbrew/.linuxbrew/bin/brew"

    if [[ ! -x "$brew_bin" ]]; then
        sudo dnf install -y @development-tools procps-ng curl file git
        NONINTERACTIVE=1 /bin/bash -c \
            "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "homebrew already installed at $brew_bin"
    fi

    local shellenv_line='eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
    if ! grep -qxF "$shellenv_line" "$HOME/.bashrc" 2>/dev/null; then
        echo "$shellenv_line" >> "$HOME/.bashrc"
    fi
}

# ---------------------------------------------------------------
# 4. install devops tooling
# ---------------------------------------------------------------
add_devops_repos() {
    echo "==> adding third party rpm repositories"

    # google cloud cli
    if [[ ! -f /etc/yum.repos.d/google-cloud-sdk.repo ]]; then
        sudo tee /etc/yum.repos.d/google-cloud-sdk.repo > /dev/null <<'EOF'
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el9-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
    fi

    # hashicorp (terraform)
    if [[ ! -f /etc/yum.repos.d/hashicorp.repo ]]; then
        sudo curl -fsSL -o /etc/yum.repos.d/hashicorp.repo \
            https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
    fi

    # kubernetes (kubectl) — track the latest stable minor release
    local k8s_stream
    k8s_stream="$(curl -fsSL https://dl.k8s.io/release/stable.txt | grep -oE '^v[0-9]+\.[0-9]+')"
    if ! grep -q "stable:/${k8s_stream}/" /etc/yum.repos.d/kubernetes.repo 2>/dev/null; then
        sudo tee /etc/yum.repos.d/kubernetes.repo > /dev/null <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/${k8s_stream}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/${k8s_stream}/rpm/repodata/repomd.xml.key
EOF
    fi

    # docker ce (daemon + compose plugin)
    if [[ ! -f /etc/yum.repos.d/docker-ce.repo ]]; then
        sudo curl -fsSL -o /etc/yum.repos.d/docker-ce.repo \
            https://download.docker.com/linux/fedora/docker-ce.repo
    fi
}

install_devops_packages() {
    echo "==> installing devops packages via dnf"

    sudo dnf install -y \
        curl \
        jq \
        unzip \
        tmux \
        flatpak \
        google-cloud-cli \
        terraform \
        kubectl \
        helm \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
}

install_aws_cli() {
    echo "==> installing aws cli v2"

    if command -v aws > /dev/null 2>&1; then
        echo "aws cli already installed: $(aws --version)"
        return
    fi

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    curl -fsSL -o "$tmp_dir/awscliv2.zip" \
        https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
    unzip -q "$tmp_dir/awscliv2.zip" -d "$tmp_dir"
    sudo "$tmp_dir/aws/install"
    rm -rf "$tmp_dir"
}

install_kind() {
    echo "==> installing kind"

    local kind_version="v0.25.0"

    if [[ ! -x /usr/local/bin/kind ]]; then
        sudo curl -fsSL -o /usr/local/bin/kind \
            "https://kind.sigs.k8s.io/dl/${kind_version}/kind-linux-amd64"
        sudo chmod 0755 /usr/local/bin/kind
    else
        echo "kind already installed"
    fi
}

setup_kind_service() {
    echo "==> configuring kind cluster to start at boot"

    local unit_path="/etc/systemd/system/kind-cluster.service"
    local tmp_unit
    tmp_unit="$(mktemp)"

    cat > "$tmp_unit" <<EOF
[Unit]
Description=kind homelab cluster
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=$CURRENT_USER
Environment="HOME=$HOME"
ExecStart=/bin/bash -c '/usr/local/bin/kind get clusters | grep -qx homelab || /usr/local/bin/kind create cluster --name homelab'

[Install]
WantedBy=multi-user.target
EOF

    if ! sudo cmp -s "$tmp_unit" "$unit_path" 2>/dev/null; then
        sudo cp "$tmp_unit" "$unit_path"
        sudo systemctl daemon-reload
    fi
    rm -f "$tmp_unit"

    sudo systemctl enable --now kind-cluster.service
}

install_podman_desktop() {
    echo "==> installing podman desktop via flatpak"

    if ! flatpak remotes --columns=name | grep -qx flathub; then
        sudo flatpak remote-add --if-not-exists flathub \
            https://flathub.org/repo/flathub.flatpakrepo
    fi

    flatpak install -y --noninteractive flathub io.podman_desktop.PodmanDesktop
}

configure_docker_daemon() {
    echo "==> enabling docker daemon"

    sudo systemctl enable --now containerd.service
    sudo systemctl enable --now docker.socket
    sudo systemctl enable --now docker.service

    if ! id -nG "$CURRENT_USER" | grep -qw docker; then
        sudo usermod -aG docker "$CURRENT_USER"
        echo "added $CURRENT_USER to docker group — log out and back in for it to take effect"
    fi
}

install_devops_tooling() {
    add_devops_repos
    install_devops_packages
    install_aws_cli
    install_kind
    install_podman_desktop
    configure_docker_daemon
    setup_kind_service
}

# ---------------------------------------------------------------
# 5. enable remote desktop access (gnome rdp)
# ---------------------------------------------------------------
setup_remote_desktop() {
    echo "==> enabling remote desktop (rdp via gnome-remote-desktop)"

    # ships with fedora workstation, but make sure
    if ! rpm -q gnome-remote-desktop > /dev/null 2>&1; then
        sudo dnf install -y gnome-remote-desktop
    fi

    # rdp needs a tls key pair; generate a self-signed one if missing
    # (same layout gnome settings creates)
    local grd_dir="$HOME/.local/share/gnome-remote-desktop"
    mkdir -p "$grd_dir"
    if [[ ! -f "$grd_dir/rdp-tls.crt" || ! -f "$grd_dir/rdp-tls.key" ]]; then
        openssl req -new -newkey rsa:4096 -days 720 -nodes -x509 \
            -subj "/C=US/ST=NONE/L=NONE/O=GNOME/CN=$(hostname)" \
            -out "$grd_dir/rdp-tls.crt" -keyout "$grd_dir/rdp-tls.key"
        chmod 600 "$grd_dir/rdp-tls.key"
    fi
    grdctl rdp set-tls-cert "$grd_dir/rdp-tls.crt"
    grdctl rdp set-tls-key "$grd_dir/rdp-tls.key"

    # set credentials only when rdp isn't configured yet. RDP_USER / RDP_PASS
    # are pre-collected by setup.sh so this stays unattended behind the tui;
    # prompt only when run standalone
    if ! grdctl status 2>/dev/null | grep -A2 'RDP' | grep -q 'enabled'; then
        local rdp_user="${RDP_USER:-}" rdp_pass="${RDP_PASS:-}"
        if [[ -z "$rdp_user" ]]; then
            read -r -p "enter remote desktop username: " rdp_user
            read -r -s -p "enter remote desktop password: " rdp_pass
            echo
        fi
        grdctl rdp set-credentials "$rdp_user" "$rdp_pass"
    else
        echo "rdp already enabled — keeping existing credentials"
    fi

    grdctl rdp disable-view-only
    grdctl rdp enable

    # start the per-user service now and at every login
    systemctl --user enable --now gnome-remote-desktop.service

    # open the firewall for rdp (3389/tcp)
    if ! sudo firewall-cmd --query-service=rdp > /dev/null 2>&1; then
        sudo firewall-cmd --permanent --add-service=rdp > /dev/null 2>&1 \
            || sudo firewall-cmd --permanent --add-port=3389/tcp > /dev/null
        sudo firewall-cmd --reload > /dev/null
    fi

    echo "rdp enabled on port 3389 — note: the session must be logged in"
    echo "(enable gnome auto-login for unattended access after reboot)"
}

# ---------------------------------------------------------------
# 6. install tailscale
# ---------------------------------------------------------------
install_tailscale() {
    echo "==> installing tailscale"

    # repo setup from: https://tailscale.com/download/linux/fedora
    if [[ ! -f /etc/yum.repos.d/tailscale.repo ]]; then
        sudo curl -fsSL -o /etc/yum.repos.d/tailscale.repo \
            https://pkgs.tailscale.com/stable/fedora/tailscale.repo
    fi

    if ! rpm -q tailscale > /dev/null 2>&1; then
        sudo dnf install -y tailscale
    else
        echo "tailscale already installed — skipping"
    fi

    sudo systemctl enable --now tailscaled

    # trust the tailnet interface in firewalld — the default workstation
    # zone rejects ports below 1025 (e.g. caddy's 443) from other devices.
    # the tailnet itself is the auth boundary; lan/wifi rules are untouched
    if [[ "$(sudo firewall-cmd --get-zone-of-interface=tailscale0 2>/dev/null)" != "trusted" ]]; then
        sudo firewall-cmd --permanent --zone=trusted --add-interface=tailscale0
        sudo firewall-cmd --reload
    fi

    # joining the tailnet needs a one-time browser login — see the readme
    if ! tailscale status > /dev/null 2>&1; then
        echo "tailscale installed but not authenticated — run: sudo tailscale up"
    fi
}

# ---------------------------------------------------------------
# main
# ---------------------------------------------------------------
main() {
    request_sudo
    ensure_github_ssh_key
    configure_git_identity
    install_homebrew
    install_devops_tooling
    setup_remote_desktop
    install_tailscale

    echo "==> base system setup complete"
}

main "$@"
