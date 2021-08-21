# Homelab Research Testbed (under construction)

This repository holds configurations and documentation for deploying my personal homelab and network research tesbed.

The lab environment is intended to run under a infrastructure-as-code model, with all services running as containers deployable by Ansible, Terraform, and Helm within Kubernetes. Currently the lab is run in the cloud within [Digital Ocean Kubernetes](https://www.digitalocean.com/products/kubernetes/). 

# Table of contents

<!--ts-->

- [Testbed Environment](#testbed-environment)
  - [Container List](#container-list)
- [Deployment Instructions](#deployment-instructions)
<!--te-->

# Testbed Environment


*The below graphic is outdated and pending an update*
![alt text](https://github.com/stevenplatt/homelab/blob/main/img/lab_topology_v3.png?raw=true)

# Container List

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


...
