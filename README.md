# Homelab Research Testbed (under construction)

This repository holds configurations and documentation for deploying my personal homelab and network research tesbed.

The lab environment is intended to run under a infrastructure-as-code model, with all services running as containers deployable by Ansible, Terraform, and Helm within Kubernetes. Currently the lab is run in the cloud within [Digital Ocean Kubernetes](https://www.digitalocean.com/products/kubernetes/). 

# Table of contents

<!--ts-->

- [Cloud Environment](#cloud-environment)
  - [Service List](#service-list)
- [Deployment Instructions](#deployment-instructions)  
<!--te-->

# Cloud Environment

![alt text](https://github.com/stevenplatt/homelab/blob/main/cloud_k8s.jpg?raw=true)

  
## Service List

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

QTY 1: Digital Ocean Load Balancer  

QTY 1: Digital Ocean Kubernetes
- Autoscaling Node Group
  -  Min: 1 nodes; Max: 2 nodes 

Terraform is used to deploy cloud infrastructure for the Kubernetes cluster. 
To deploy teh Kubernetes cluster, Terraform must be installed to your local machine.

1. [Terraform install instructions](https://learn.hashicorp.com/tutorials/terraform/install-cli)

...

## Services Deployment

The Helm package manager is used to deploy services to the Kubernetes cluster.
To deploy services to the Kubernetes cluster both `kubectl` and `helm` must be installed to your local machine. 

1. [Kubectl install instructions](https://kubernetes.io/docs/tasks/tools/)
1. [Helm install instructions](https://helm.sh/docs/intro/install/)

I addition to installing `kubectl` and `helm`, `kubectl` must be configured to connect to the newly deployed Kubernetes cluster. This is done by downloading the new `kubeconfig` file created with the new Kubernetes cluster. 

1. [Install kubeconfig file](https://docs.digitalocean.com/products/kubernetes/how-to/connect-to-cluster/)


### Deploying Telecomsteve (Website)

### Deploying PiHole
1. `helm repo add mojo2600 https://mojo2600.github.io/pihole-kubernetes/`
1. `helm repo update`

...
