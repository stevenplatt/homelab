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

## gemma3 inference snap

The playbook installs the `gemma3` inference snap, pins it to the `amd-gpu` engine (with the `llamacpp-rocm` component), and binds it to `127.0.0.1:9090`. Reference: [Inference Snaps CLI](https://documentation.ubuntu.com/inference-snaps/reference/models-cli/).

### Service control

```sh
sudo snap start gemma3            # start the OpenAI-compatible server
sudo snap stop gemma3             # stop it
sudo snap restart gemma3          # restart (apply config changes)
sudo snap services gemma3         # show service state and logs
```

### Inspecting state

| Command | What it does |
| --- | --- |
| `gemma3 status` | Server URL, runtime, active engine and model |
| `gemma3 get` | Print all configuration keys and values |
| `gemma3 get <key>` | Print one key (e.g. `gemma3 get http.port`) |
| `gemma3 list-engines` | Available engines with vendor and compatibility |
| `gemma3 show-engine <engine>` | Engine details (`--format=json` or `yaml`) |
| `gemma3 show-machine` | Host hardware summary (`--format=json` or `yaml`) |

### Configuration

```sh
sudo gemma3 set http.port=9090    # change listening port
sudo gemma3 set http.host=0.0.0.0 # expose to LAN (default 127.0.0.1)
sudo snap restart gemma3          # required after `set`
```

### Switching engines

```sh
sudo gemma3 use-engine amd-gpu    # specific engine
sudo gemma3 use-engine --auto     # let the snap pick the best fit
sudo gemma3 prune-cache           # wipe all cached engine data
sudo gemma3 prune-cache --engine=<engine>  # wipe one engine's cache
```

### Interacting with the model

```sh
gemma3 chat                       # terminal chat client
curl -s http://127.0.0.1:9090/v1/models | jq   # raw OpenAI API
```

Open WebUI (also installed by the playbook) gives a browser UI at `http://localhost:8080` — point its **Direct Connections** at `http://127.0.0.1:9090/v1`.

Global flags available on every subcommand: `--help`, `--verbose`, `--format=json` (where the output is structured).
