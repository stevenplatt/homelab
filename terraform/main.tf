# The main.tf file will be used to define providers and configure any modeules that are added over time as the configuration is expanded
# configuration of Terraform itself
terraform {
    # version 0.14.8 is required to use kubernetes manifest functions
    # https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest
    required_version = ">= 0.14.8"
    
    required_providers {
        google = {
        source  = "hashicorp/google"
        version = ">=4.3.0" # version required to run Terraform on Mac with M1
        }
    }

    backend "gcs" {
        bucket  = "telecomsteve-infra"
        prefix  = "homelab/terraform/state"
    }
}

# Desclaration of all providers required of the deployment
provider "google" {
    # project may be required to avoid "required item not set" error
    project = "telecomsteve" 
}

################################################################
# Calling each module and passing it variable values
################################################################

# for initial rollout, comment out all modules except "kubernetes-deploy" as it is a dependancy of the other mudules
# after the kubernetes deployment, uncomment all other modules to apply them

module "kubernetes-deploy" {
  source = "./modules/kubernetes-deploy"
  project_id = var.project_id
  location = var.location
  region = var.region
  gke_num_nodes = var.gke_num_nodes
}

module "telecomsteve-deploy" {
  source = "./modules/telecomsteve-deploy"
  project_id = var.project_id
  location = var.location
}
