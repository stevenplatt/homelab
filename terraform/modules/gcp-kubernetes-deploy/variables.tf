# Google Cloud Platform

variable "project_id" {
  default     = "homelab"
  description = "name of this Terraform project"
}

variable "region" {
  default     = "us-west1"
  description = "the selected GCP region for deployment"
}

# Kubernetes

variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}

variable "gke_num_nodes" {
  default     = 1
  description = "number of gke nodes"
}

variable "location" {
  default     = "us-west1-b"
  description = "the selected GCP location for nodes"
}