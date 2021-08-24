# Homelab Research Testbed 

This repository holds configurations and documentation for deploying my personal homelab and network research tesbed.

The lab environment is intended to run under a infrastructure-as-code model, with all services running as containers deployable by Ansible, Terraform, and Helm within Kubernetes. Currently the lab is run in the cloud within [Digital Ocean Kubernetes](https://www.digitalocean.com/products/kubernetes/). 

# Cloud Environment

![alt text](https://github.com/stevenplatt/homelab/blob/main/cloud_k8s.jpg?raw=true)

  
## Service List

The following containers are deployed with the Kebernetes cluster environment. 

This list is included for demonstration purposes and can be considered partial or otherwise incomplete.

- Telecomsteve (Website)
- ResearchEng Portfolio (Website)
- Prometheus (Monitoring)
- Grafana (Monitoring Dashboard)
- PiHole (ad blocking)
- Librespeed (speed test)
  
...
  
# Deployment Instructions

Complete instructions for deploying both Kubernetes and containerized microservices can be found in the [wiki](https://github.com/stevenplatt/homelab/wiki) pages for this repository. 
