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

### Passwordless sudo (Ubuntu 25.10+)

Ubuntu 25.10 and 26.04 LTS replace classic `sudo` with `sudo-rs`, whose prompt format breaks ansible's interactive password handling (see [ansible#85837](https://github.com/ansible/ansible/issues/85837), fix pending in [PR #86175](https://github.com/ansible/ansible/pull/86175)). Until that fix ships, run ansible against a passwordless-sudo user:

```sh
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/99-ansible
```

Remove the file when you're done:

```sh
sudo rm /etc/sudoers.d/99-ansible
```

## Running the playbook

The playbook targets the local machine via [inventory.ini](inventory.ini), which pins `localhost` to the `local` connection. With passwordless sudo in place, run from inside the `ansible/` directory:

```sh
ansible-playbook -i inventory.ini steel_legend.yml
```

Flags:

- `-i inventory.ini` — inventory file (`localhost` with `ansible_connection=local`).
- `--check` — dry run; show what would change without applying.
