# Homelab Research Testbed 

This repository holds configurations and documentation for deploying my personal homelab and network research tesbed.

The lab environment is intended to run under a infrastructure-as-code model, with all services running as containers deployable by Ansible, Terraform, and Helm within Kubernetes. Currently the lab is run in the cloud within [Digital Ocean Kubernetes](https://www.digitalocean.com/products/kubernetes/). 

# Cloud Environment

![alt text](https://github.com/stevenplatt/homelab/blob/main/img/cloud_k8s.jpg?raw=true)

## Cluster Components

**QTY 1:** Digital Ocean Load Balancer  

**QTY 1:** Digital Ocean Kubernetes
- Autoscaling Node Group
  -  Min: 1 nodes; Max: 2 nodes 

## Services List

The following containers are deployed with the Kebernetes cluster environment. 

This list is included for demonstration purposes and can be considered partial or otherwise incomplete.

- Telecomsteve (Website)
- ResearchEng Portfolio (Website)
- Prometheus (Monitoring)
- Grafana (Monitoring Dashboard)
- PiHole (ad blocking)
- Librespeed (speed test)
  
## Cloud Deployment

Complete instructions for deploying both Kubernetes and containerized microservices can be found in the [wiki](https://github.com/stevenplatt/homelab/wiki) pages for this repository. 

# Developer Environments

This repository also holds configurations for desktop environments. 

## Windows

Windows versions 10 and 11 can be configured using the ``` winget ``` utility. Winget is enabled automatically when app install is installed from the [Windows Store](https://www.microsoft.com/store/productId/9NBLGGH4NNS1).

#### Bulk App Installation (Winget)

Open Windows PowerShell with administrator priveledges. 

The Windows installation file is located at ``` .../homelab/desktop/windows/win11_deploy.json ``` and can be run using the PowerShell command: 

``` winget import -i path\to\win11_deploy.json ```

A json of installed programs can be exported using the command: 

``` winget export -o path\to\export.json ```

The following items are not installed with the winget utility and must be manually installed: 

- Ansible
- Terraform
- Inkscape
- Mendeley
- Helm
- Digital Ocean command line tools

## Linux

A shell script for either Fedora or Ubuntu distributions can be run directly from the Linux terminal to bulk install pre-set applications. 

From the Linux terminal: 

- ``` git clone https://github.com/stevenplatt/homelab.git ``` 
- ``` cd homelab/desktop/linux ```
- ``` bash ubuntu_deploy.sh ``` or ``` bash fedora_deploy.sh ```

