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

The playbook targets the local machine via [inventory.ini](inventory.ini), which pins `localhost` to the `local` connection. From inside the `ansible/` directory:

```sh
sudo ansible-playbook -i inventory.ini steel_legend.yml
```

Flags:

- `-i inventory.ini` — inventory file (`localhost` with `ansible_connection=local`).
- `--check` — dry run; show what would change without applying.
