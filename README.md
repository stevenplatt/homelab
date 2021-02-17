# BlueberryFi Research Testbed (under construction)
This repository holds configurations and documentation for deploying a general purpose datacenter-in-a-box for network research experiments.  

The lab environment is intended to run under a infrastructure-as-code model, with all configuration of both virtual machines and containers being handled by Ansible. 

Table of contents
=================

<!--ts-->
   * [Testbed Environment](#testbed-environment)
      * [Container List](#container-list)
      * [Virtual Machine List](#virtual-machine-list)
   * [Deployment Instructions](#deployment-instructions)
<!--te-->


Testbed Environment
============

The lab environment is contained entirely within a single Intel NUC running Proxmox as hypervisor with the below specs: 

- Core i5 8259U (4 core, 8 thread)
- 32GB DDR4 RAM (2400Mhz)
- 512 GB NVME SSD (Samsung)

The hypervisor environment holds two kubernetes clusters, and a number of virtual machines.

![alt text](https://github.com/stevenplatt/homelab/blob/main/img/lab_topology_v4.png?raw=true)

Container List
============

The following containers are deployed with the Kebernetes cluster environment

- NextCloud (Google Apps substitue)
- PiHole (ad blocking)
- OpenVPN (vpn)
- Librespeed (speed test)
- VSCode Server (Visual Studio Code in the browser)
- Ansible (configuration management)
- OpenWRT (WiFi Router OS)

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

This guide assumes that a base image of Proxmox is already installed. Instructions for initial installation can be found on the [Proxmox website](https://pve.proxmox.com/wiki/Installation). 

## Download Required ISO Images
To deploy the Proxmox testbed environment, the following ISO images will be needed, and can be downloaded to Proxmox local storage using the commands below. 

1. Ubuntu Desktop 20.04 LTS: `wget https://releases.ubuntu.com/20.04/ubuntu-20.04.2.0-desktop-amd64.iso`

2. Ubuntu Server 20.04 LTS: `wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img`

3. PfSense Firewall: `wget https://nyifiles.netgate.com/mirror/downloads/pfSense-CE-2.5.0-RELEASE-amd64.iso.gz`

## Create an Ubuntu Server Template Using Cloud-Init

Virtual machines within the Kubernetes clusters all run Ubuntu Server 20.04 LTS. Creating a machine template for this allow fast cloning to add additional virtual machine nodes to the Kubernetes cluster. Cloud-Init is used to create the image, as this accommodates adding a ssh public key that can be used later by Ansible for customizing the virtual machine for a specific role. 
