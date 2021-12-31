# VPC
resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-vpc"
  auto_create_subnetworks = "false"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "${var.project_id}-subnet"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}

################################################################
# Assigning firewall rules to the network IP space
################################################################

# source = https://github.com/MinaProtocol/mina/blob/develop/automation/terraform/modules/google-cloud/vpc-network/main.tf
resource "google_compute_firewall" "homelab_ingress" {
  name    = "${var.project_id}-homelab-ingress"
  network = google_compute_network.vpc.name

  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["10000-11000"]
  }

  allow {
    protocol = "udp"
    ports    = ["10000-11000"]
  }

  source_tags = ["homelab-ports"]
}
