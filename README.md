# Homelab Research Testbed (under construction)

This repository holds configurations and documentation for deploying my personal homelab and network research tesbed.

The lab environment is intended to run under a infrastructure-as-code model, with all services running as containers deployable by Ansible, Terraform, and Helm within Kubernetes.

# Table of contents

<!--ts-->

- [Testbed Environment](#testbed-environment)
  - [Container List](#container-list)
  - [Virtual Machine List](#virtual-machine-list)
- [Deployment Instructions](#deployment-instructions)
<!--te-->

# Testbed Environment


*The below graphic is outdated and pending an update*
![alt text](https://github.com/stevenplatt/homelab/blob/main/img/lab_topology_v3.png?raw=true)

# Container List

The following containers are deployed with the Kebernetes cluster environment

- PiHole (ad blocking)
- OpenVPN (vpn)
- Librespeed (speed test)
- VSCode Server (Visual Studio Code in the browser)
- OpenWRT (WiFi Router OS)

# Virtual Machine List

The following virtual machines are deployed within Proxmox

- Ubuntu Server / Open Air Interface (4G/5G Core Network Testbed)
- Ubuntu Server / FlexRAN (Network Slicing Testbed)
- Ubuntu Desktop

# YAML Deployment Instructions


...
