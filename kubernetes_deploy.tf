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

data "digitalocean_kubernetes_versions" "homelab" {
  version_prefix = "1.21." # allow auto upgrades for patch releases of this base version
}

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