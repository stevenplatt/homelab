# Ansible

Playbook for provisioning a local Ubuntu workstation.

## Playbook

| File | Purpose |
| --- | --- |
| [steel_legend.yml](steel_legend.yml) | Full setup of a fresh Ubuntu 26.04 LTS workstation. |

## Prerequisites

Install Ansible and the required collection:

```sh
sudo apt install -y ansible
ansible-galaxy collection install community.general
```

## Running the playbook

The playbook is intended to run against the local machine. From inside the `ansible/` directory:

```sh
ansible-playbook -i 'localhost,' -c local steel_legend.yml -K
```

Flags:

- `-i 'localhost,'` — inline inventory of one host (the trailing comma is required).
- `-c local` — use the local connection instead of SSH.
- `-K` — prompt for the sudo password.
- `--check` — dry run; show what would change without applying.
