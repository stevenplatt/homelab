# Ansible

Playbooks for provisioning workstations and homelab hosts.

## Playbooks

| File | Target | Purpose |
| --- | --- | --- |
| [fedora_deploy.yml](fedora_deploy.yml) | `fedora_workstation` | Full setup of a fresh Fedora workstation. |
| [ubuntu_deploy.yml](ubuntu_deploy.yml) | `ubuntu_workstation` | Full setup of a fresh Ubuntu 26.04 LTS workstation. Installs `kind` and bootstraps a local cluster as the active kubecontext (`kind-homelab`). |

Inventory lives in [_hosts.txt](_hosts.txt). Update the IPs under the relevant group before running.

## Prerequisites

On the **control machine** (the host running Ansible):

```sh
# Fedora
sudo dnf install -y ansible

# Ubuntu / Debian
sudo apt install -y ansible

# macOS
brew install ansible
```

Install required collections:

```sh
ansible-galaxy collection install community.general
```

On each **target host**:

- SSH server running and reachable from the control machine.
- A user account with `sudo` privileges.
- Your SSH public key in that user's `~/.ssh/authorized_keys` (recommended), or be ready to pass `--ask-pass`.

Verify connectivity before running a playbook:

```sh
ansible -i _hosts.txt ubuntu_workstation -m ping
```

## Running a playbook

From inside the `ansible/` directory:

```sh
# Ubuntu workstation
ansible-playbook -i _hosts.txt ubuntu_deploy.yml -K

# Fedora workstation
ansible-playbook -i _hosts.txt fedora_deploy.yml -K
```

Flags:

- `-i _hosts.txt` — inventory file.
- `-K` — prompt for the sudo (become) password on the target host.
- `-u <user>` — connect as a specific SSH user (defaults to your current username).
- `--check` — dry run; show what would change without applying.
- `--limit <host-or-ip>` — restrict the run to a single host in the group.

Example targeting a single Ubuntu host with a non-default user:

```sh
ansible-playbook -i _hosts.txt ubuntu_deploy.yml -u steve -K --limit 10.0.5.11
```

## Running locally (no SSH)

To configure the machine you are sitting at, point the playbook at `localhost` over the local connection:

```sh
ansible-playbook -i 'localhost,' -c local ubuntu_deploy.yml -K
```

## Inventory groups

Defined in [_hosts.txt](_hosts.txt):

- `hypervisor`
- `kubernetes_cluster_1` (`masters_1` / `workers_1` / `storage_1`)
- `kubernetes_cluster_2` (`masters_2` / `workers_2` / `storage_2`)
- `openairinterface`, `flexran`
- `windows10`
- `fedora_workstation`, `ubuntu_workstation`

A playbook only runs against the group named in its `hosts:` field, so adding a new host to the right group is all that's needed to bring it under management.
