# The main.tf file will be used to define providers and configure any modeules that are added over time as the configuration is expanded
# configuration of Terraform itself
terraform {
    required_version = ">= 0.14.0"
    
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

module "gcp-kubernetes-deploy" {
  source = "./modules/gcp-kubernetes-deploy"
}