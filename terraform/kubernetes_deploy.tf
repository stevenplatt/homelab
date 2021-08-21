terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

variable "do_token" {}

provider "digitalocean" {
    token = var.do_token
}


# Deploy Load Balancer Node
resource "digitalocean_droplet" "load_balancer" {
  name   = "k8s-lb-droplet"
  size   = "s-1vcpu-1gb"
  image  = "ubuntu-20-04-x64"
  region = "sfo3"
}

resource "digitalocean_loadbalancer" "k8s_lb_resource" {
  name   = "k8s-loadbalancer"
  region = "sfo3"
  algorithm = "least_connections"

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  sticky_sessions {
    type  = "cookies"
    cookie_name = "telecomsteve"
    cookie_ttl_seconds = 3600
  }

  healthcheck {
    port     = 22
    protocol = "tcp"
  }

  droplet_ids = [digitalocean_droplet.load_balancer.id]
}



data "digitalocean_kubernetes_versions" "homelab" {
  version_prefix = "1.21." # allow auto upgrades for patch releases of this base version
}

# Deploy K8s cluster
resource "digitalocean_kubernetes_cluster" "homelab" {
  name    = "homelab"
  region  = "sfo3"
  auto_upgrade = true
  surge_upgrade = true # allow adding burst nodes if needed to complete cluster upgrades
  version      = data.digitalocean_kubernetes_versions.homelab.latest_version

  maintenance_policy { # set when patches are applied
    start_time  = "04:00"
    day         = "sunday"
  }

  node_pool {
    name       = "autoscale-worker-pool"
    size       = "s-1vcpu-2gb"
    auto_scale = true # allow autoscaling between the min/max node counts
    min_nodes  = 1
    max_nodes  = 2
  }
}

