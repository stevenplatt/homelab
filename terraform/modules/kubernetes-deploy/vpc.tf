




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

# https://cloud.google.com/kubernetes-engine/docs/how-to/exposing-apps

resource "google_compute_firewall" "homelab_ingress" {
  name    = "${var.project_id}-homelab-ingress"
  network = google_compute_network.vpc.name

  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"] # this is the GKE nodeport range
  }

  allow {
    protocol = "udp"
    ports    = ["30000-32767"]
  }
}
