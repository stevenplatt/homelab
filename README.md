# Homelab Research Testbed 

This repository holds configurations and documentation for deploying my personal homelab and network research tesbed.

The lab environment is intended to run under a infrastructure-as-code model, with all services running as containers deployable by Ansible, Terraform, and Helm within Kubernetes. Currently the lab is run in the cloud within [Digital Ocean Kubernetes](https://www.digitalocean.com/products/kubernetes/). 

# Table of contents

<!--ts-->

- [Cloud Environment](#cloud-environment)
  - [Service List](#service-list)
- [Deployment Instructions](#deployment-instructions)
  - [Deploying Kubernetes using Terraform](#deploying-kubernetes-using-terraform)
  - [Installing Cluster Management Tools](#installing-cluster-management-tools)
  - [Configuring an Nginx Ingress Controller](#configuring-an-nginx-ingress-controller)
  - [Optional: Deploy a Public Service Using SSL](#optional-deploy-a-public-service-using-ssl)
<!--te-->

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

## Deploying Kubernetes using Terraform

QTY 1: Digital Ocean Load Balancer  

QTY 1: Digital Ocean Kubernetes
- Autoscaling Node Group
  -  Min: 1 nodes; Max: 2 nodes 

Terraform is used to deploy cloud infrastructure for the Kubernetes cluster. 
To deploy teh Kubernetes cluster, Terraform must be installed to your local machine ([source 1](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs/resources/kubernetes_cluster)) ([source 2](https://www.youtube.com/watch?v=U5suIJwobiQ)).

1. Install the terraform cli.

[Terraform install instructions](https://learn.hashicorp.com/tutorials/terraform/install-cli)

2. Clone the homelab repository.

`git clone https://github.com/stevenplatt/homelab.git && cd homelab/`

3. Initialize Terraform within the repository directory. 

`terraform init`

4. Double-check the planned infrastructure changes. 

`terraform plan`

5. Assuming everything looks correct, launch the infrastructure deployment. 

`terraform deploy`

Terraform will request the Digital Ocean API token (it must have read/write priveledges), and to confirm `yes` a final time to apply the change.

**Note:** Using `terraform destroy` from the same directory will delete the infrastructure that was launched using `terraform deploy`.
  
...
  

## Installing Cluster Management Tools

The Helm package manager is used to deploy services to the Kubernetes cluster.
To deploy services to the Kubernetes cluster both `kubectl` and the `helm cli` must be installed to your local machine. 

I addition to installing `kubectl` and the `helm cli`, `kubectl` must be configured to connect to the newly deployed Kubernetes cluster. This is done by downloading the new `kubeconfig` file created with the new Kubernetes cluster. 

1. Install the `kubectl` CLI tool.

[Kubectl install instructions](https://kubernetes.io/docs/tasks/tools/)

2. Install the `helm` Kubernetes package manager.

[Helm install instructions](https://helm.sh/docs/intro/install/)

3. Download the `kubeconfig` file for your previously deployed Kubernetes cluster. 

[Kubeconfig installation instructions](https://docs.digitalocean.com/products/kubernetes/how-to/connect-to-cluster/)
   
...
   
## Configuring an Nginx Ingress Controller

Installing an ingress controller must be done to allow deployed services to be reachable from outside the kubernetes cluster (see topology image above).

An additional command is also required to resolve an error relating to webhook timeouts when creating a Kubernetes Ingress (step 4) ([source](https://stackoverflow.com/questions/61616203/nginx-ingress-controller-failed-calling-webhook)). 

1. Add the nginx Helm repository.

`helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx`

2. Refresh the local Helm repositories.

`helm repo update`

3. Install the nginx ingress. ([source](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-on-digitalocean-kubernetes-using-helm))

`helm install nginx-ingress ingress-nginx/ingress-nginx --set controller.publishService.enabled=true`

4. Stop validation of webhook configurations.

`kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission`
  
...
  
## Optional: Deploy a Public Service Using SSL

To test that everything is deployed correctly, a sample app can be pushed to the Kubernetes cluster using [this tutorial](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-on-digitalocean-kubernetes-using-helm) from Digital Ocean. 
