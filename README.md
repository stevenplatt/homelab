# homelab (under construction)
This repository holds configurations and documentation of my home lab and wireless testbed. 

The lab environment is intended to run under a configuration-as-code model, with all configuration of both virtual machines and containers being handled by Ansible (or possibly Terraform). 

### Lab Topology

The lab environment is contained entirely within a single Intel NUC running Proxmox as hypervisor with the below specs. 
The hypervisor environment holds two kubernetes clusters, and a number of virtual machines.

- Core i5 8259U (4 core, 8 thread)
- 32GB DDR4 RAM (2400Mhz)
- 512 GB NVME SSD (Samsung)

![alt text](https://github.com/stevenplatt/homelab/blob/main/img/lab_topology.jpg?raw=true)

### Kubernetes Architecture

![alt text](https://github.com/stevenplatt/homelab/blob/main/img/kubernetes_architecture.jpg?raw=true)

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