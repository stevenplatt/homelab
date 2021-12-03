# configuration to deploy a homelab cluster to Google Kubernetes Engine
terraform {
    required_version = ">= 0.14.0"
    
    backend "gcs" {
        bucket  = "telecomsteve-infra"
        prefix  = "homelab/terraform/state"
    }
}