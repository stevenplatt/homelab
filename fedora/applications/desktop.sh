#!/usr/bin/env bash
#
# desktop.sh — desktop applications (fedora)
#
# installs desktop applications:
#   rpm:     vscode (microsoft repo), steam (rpm fusion nonfree — unsandboxed,
#            full system access)
#   flathub: slack, flatseal, zotero
#
# safe to re-run: apps already installed are skipped.
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

# flathub app ids — https://flathub.org
FLATPAK_APPS=(
    com.slack.Slack             # slack
    com.github.tchx84.Flatseal  # flatseal
    org.zotero.Zotero           # zotero
)

ensure_flathub() {
    echo "==> ensuring flatpak and the flathub remote are available"

    if ! command -v flatpak > /dev/null 2>&1; then
        sudo dnf install -y flatpak
    fi

    if ! flatpak remotes --columns=name | grep -qx flathub; then
        sudo flatpak remote-add --if-not-exists flathub \
            https://flathub.org/repo/flathub.flatpakrepo
    fi
}

install_flatpak_apps() {
    echo "==> installing desktop applications from flathub"

    local app
    for app in "${FLATPAK_APPS[@]}"; do
        if flatpak info "$app" > /dev/null 2>&1; then
            echo "$app already installed — skipping"
        else
            flatpak install -y --noninteractive flathub "$app"
        fi
    done
}

install_vscode_rpm() {
    echo "==> installing vscode (rpm build)"

    # repo setup from: https://code.visualstudio.com/docs/setup/linux
    if [[ ! -f /etc/yum.repos.d/vscode.repo ]]; then
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sudo tee /etc/yum.repos.d/vscode.repo > /dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    fi

    if ! rpm -q code > /dev/null 2>&1; then
        sudo dnf install -y code
    else
        echo "vscode already installed — skipping"
    fi
}

install_steam_rpm() {
    echo "==> installing steam (rpm build, full system access)"

    # rpm fusion setup from: https://rpmfusion.org/Configuration
    local fedora_release
    fedora_release="$(rpm -E %fedora)"

    if ! rpm -q rpmfusion-free-release > /dev/null 2>&1; then
        sudo dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_release}.noarch.rpm"
    fi
    if ! rpm -q rpmfusion-nonfree-release > /dev/null 2>&1; then
        sudo dnf install -y \
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_release}.noarch.rpm"
    fi

    if ! rpm -q steam > /dev/null 2>&1; then
        sudo dnf install -y steam
    else
        echo "steam already installed — skipping"
    fi
}

main() {
    install_vscode_rpm
    install_steam_rpm
    ensure_flathub
    install_flatpak_apps

    echo "==> desktop applications installed"
}

main "$@"
