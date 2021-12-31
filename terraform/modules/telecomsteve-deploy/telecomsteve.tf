################################################################
# Declaring imported variables
################################################################

variable "project_id" {
}

variable "location" {
}



################################################################
# Connecting to the new Kubernetes cluster
################################################################

data "google_client_config" "default" {}

data "google_container_cluster" "homelab" {
  name     = "${var.project_id}-gke"
  location = var.location
}

provider "kubernetes" {
  token                  = data.google_client_config.default.access_token
  host                   = "https://${data.google_container_cluster.homelab.endpoint}"
  cluster_ca_certificate = base64decode(data.google_container_cluster.homelab.master_auth[0].cluster_ca_certificate)
}

################################################################
# Telecomsteve Website Deployment
################################################################

# source: https://circleci.com/blog/learn-iac-part02/
# todo: labels can be coded into variables

# defining the Kubernetes deployment
resource "kubernetes_deployment" "website-deployment" {
  metadata {
    name = "website-deployment"
    labels = {
      app = "telecomsteve-flask"
    }
    namespace = "default"
  }
  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "telecomsteve-flask"
      }
    }
    template {
      metadata {
        labels = {
          app = "telecomsteve-flask"
        }
      }
      spec {
        container {
          image = "docker.io/telecomsteve/telecomsteve-flask:main"
          name  = "telecomsteve-flask"
          port {
            name           = "port-5000"
            container_port = 5000
          }
        }
      }
    }
  }
}

# defining the Kubernetes services
resource "kubernetes_service" "cluster-ip-service" {
  metadata {
    name = "cluster-ip-service"
  }
  spec {
    selector = {
      app = kubernetes_deployment.website-deployment.metadata.0.labels.app
    }
    port {
      protocol = "TCP"
      port        = 80
      target_port = 8080
    }
    type = "ClusterIP"
  }
} 

resource "kubernetes_service" "nodeport-service" {
  metadata {
    name = "nodeport-service"
    namespace = "default"
  }
  spec {
    selector = {
      app = kubernetes_deployment.website-deployment.metadata.0.labels.app
    }
    port {
      protocol = "TCP"
      port        = 80
      target_port = 5000
    }
    type = "NodePort"
  }
} 
