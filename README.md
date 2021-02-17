# BlueberryFi Research Testbed (under construction)
This repository holds configurations and documentation for deploying a general purpose datacenter-in-a-box for network research experiments.  

The lab environment is intended to run under a infrastructure-as-code model, with all configuration of both virtual machines and containers being handled by Ansible. 

Table of contents
=================

<!--ts-->
   * [Testbed Environment](#testbed-environment)
      * [Kubernetes Architecture](#kubernetes-architecture)
      * [Container List](#container-list)
      * [Virtual Machine List](#virtual-machine-list)
   * [Deployment Wiki](#deployment-wiki)
<!--te-->


Testbed Environment
============

The lab environment is contained entirely within a single Intel NUC running Proxmox as hypervisor with the below specs: 

- Core i5 8259U (4 core, 8 thread)
- 32GB DDR4 RAM (2400Mhz)
- 512 GB NVME SSD (Samsung)

The hypervisor environment holds two kubernetes clusters, and a number of virtual machines.

![alt text](https://github.com/stevenplatt/homelab/blob/main/img/lab_topology_v3.png?raw=true)

Container List
============

The following containers are deployed with the Kebernetes cluster environment

- NextCloud (Google Apps substitue)
- PiHole (ad blocking)
- OpenVPN (vpn)
- Librespeed (speed test)
- VSCode Server (Visual Studio Code in the browser)
- Nginx (static sites)
- Ansible (configuration management)
- Zabbix (monitoring server)
- Python Dynamic DNS Script (update DNS if ISP changes IP)
- Tweet-Delete (auto-deleting of Twitter posts)
- OpenWRT (WiFi Router OS)
- BlueberryFi (OpenWRT testbed UI)
- Python Cloud Phone (pending)

Virtual Machine List
============

The following virtual machines are deployed within Proxmox

- pfSense (firewall)
- Ubuntu Server / MiniKube (Kubernetes)
- Ubuntu Server / Open Air Interface (4G/5G Core Network Testbed)
- Ubuntu Server / FlexRAN (Network Slicing Testbed)
- Ubuntu Desktop

Deployment Instructions
============

Complete information for setting up the virtual machines within the testbed and deploying containerized experiments and services can be found in this repos' [Deployment Wiki](https://github.com/stevenplatt/homelab/wiki).
