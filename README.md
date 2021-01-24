# homelab (under construction)
This repository holds configurations and documentation of my home lab and wireless testbed. 

The lab environment is intended to run under a infrastructure-as-code model, with all configuration of both virtual machines and containers being handled by Ansible (or possibly Terraform). Visit the Wiki of this repository for more detailed information of how to run the configuration scripts to recreate this environment. 

### Lab Overview

The lab environment is contained entirely within a single Intel NUC running Proxmox as hypervisor with the below specs: 

- Core i5 8259U (4 core, 8 thread)
- 32GB DDR4 RAM (2400Mhz)
- 512 GB NVME SSD (Samsung)

The hypervisor environment holds two kubernetes clusters, and a number of virtual machines.

![alt text](https://github.com/stevenplatt/homelab/blob/main/img/lab_topology.jpg?raw=true)

### Kubernetes Architecture

The kubernetes clusters within the environment are each deployed using Rancher variants of the below components: 

- Kubernetes Master (2x K3s Server)
- Kubernetes Worker (3x K3s Agent)
- Longhorn Storage Node (3x Longhorn)

Deploying kubernetes in this configuration allows for [high availability](https://rancher.com/docs/k3s/latest/en/architecture/) (ignoring hardware redundancy). This means that if a VM is powered off by accidents, corrupted, or otherwise not available, the services running the environment will stay online. 

A number of components are required to sit outside of the Kubernetes cluster for the high availability configuration to work; these include NGINX serving as a load balancer in front of the active/active kubernetes masters, and a database that holds the kubernetes cluster configuration. Rather than deploying these external components to more brittle virtual machines, or an isolated docker environment, the second kubernetes cluster is added. Each cluster runs these external services as containers in the other cluster to benefit from high availability. Finally, the external database holding the cluster configuration is itself backed-up to off-site cloud storage.

![alt text](https://github.com/stevenplatt/homelab/blob/main/img/kubernetes_architecture.jpg?raw=true)

The environment does not include any observability tools, such as Istio or Apache Skywalker, since most of the services run as single containers and are not networks or accessing other resources. This may change in the future. 

## Container List
The following containers are deployed with the Kebernetes cluster environment

- Apache Guacamole (web remote access)
- NextCloud (Google Apps substitue)
- PiHole (ad blocking)
- OpenVPN (vpn)
- Librespeed (speed test)
- VSCode Server (Visual Studio Code in the browser)
- Nginx (Static Sites)
- Ansible (configuration management)
- Grafana (logging dashboard)
- Python Dynamic DNS Script (update DNS if ISP changed IP)
- OpenWRT (WiFi Router OS)
- BlueberryFi (OpenWRT testbed UI)
- Python Cloud Phone (pending)
- HTTPS Proxy (pending)

## Virtual Machine List
The following virtual machines are deployed within Proxmox

- Windows 10
- Ubuntu Desktop
- Fedora Workstation
- Open Air Interface (4G/5G Core Network Testbed)
- FlexRAN (Network Slicing Testbed)
