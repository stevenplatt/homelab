#!/usr/bin/env bash
#
# setup.sh — fedora setup orchestrator
#
# runs the installation scripts under applications/ in order:
#   1. applications/homelab.sh — base system (ssh key, git identity, homebrew,
#      devops tooling)
#   2. applications/hermes.sh  — local ai agent stack (lm studio + qwen +
#      hermes + pi)
#   3. applications/desktop.sh — desktop applications (vscode, steam, slack,
#      flatseal, zotero)
#
# finishes by printing the github configuration (user, email, public key)
# so the key can be pasted into https://github.com/settings/keys.
#
# run as your normal user; sudo is used where root is required.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$(id -u)" -eq 0 ]]; then
    echo "error: run this script as your normal user, not root." >&2
    exit 1
fi

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
    bash "$SCRIPT_DIR/applications/homelab.sh"
    bash "$SCRIPT_DIR/applications/hermes.sh"
    bash "$SCRIPT_DIR/applications/desktop.sh"

    echo "==> setup complete"
    confirm_github_config
}

main "$@"
