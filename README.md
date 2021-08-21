# Homelab Research Testbed (under construction)

This repository holds configurations and documentation for deploying my personal homelab and network research tesbed.

The lab environment is intended to run under a infrastructure-as-code model, with all services running as containers deployable by Ansible, Terraform, and Helm within Kubernetes. Currently the lab is run in the cloud within [Digital Ocean Kubernetes](https://www.digitalocean.com/products/kubernetes/). 

# Table of contents

<!--ts-->

- [Cloud Environment](#cloud-environment)
  - [Container List](#container-list)
- [Deployment Instructions](#deployment-instructions)  
<!--te-->

# Cloud Environment

QTY 1: Digital Ocean Load Balancer ($5) 

QTY 1: Digital Ocean Kubernetes
- Autoscaling Node Group
  -  Min: 1 nodes; Max: 2 nodes ($10 - $20)

#### Total: $15 - $25 / mo  


![alt text](https://github.com/stevenplatt/homelab/blob/main/cloud_k8s.jpg?raw=true)

  
## Container / Service List

The following containers are deployed with the Kebernetes cluster environment

- Telecomsteve (Website)
- ResearchEng Portfolio (Website)
- Prometheus (Monitoring)
- Grafana (Monitoring Dashboard)
- PiHole (ad blocking)
- OpenVPN (vpn)
- Librespeed (speed test)
- VSCode Server (Visual Studio Code in the browser)
- OpenWRT (WiFi Router OS)
  
  
# Deployment Instructions

## Infrastructure Deployment
### Deploying Kubernetes
...

## Service Deployment
### Deploying Telecomsteve (Website)
...
