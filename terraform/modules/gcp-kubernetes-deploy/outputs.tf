# define values that should be saved/printed to console

# Google Cloud
output "region" {
  value       = var.region
  description = "GCloud Region"
}

output "project_id" {
  value       = var.project_id
  description = "GCloud Project ID"
}

# Kubernetes
/* output "kubernetes_cluster_name" {
  value       = google_container_cluster.homelab.name
  description = "GKE Cluster Name"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.homelab.endpoint
  description = "GKE Cluster Host"
}

output "kubernetes_cluster_host" {
  value       = google_container_cluster.homelab.endpoint
  description = "GKE Cluster Host"
} */

output "gke_node_count" {
  value       = var.gke_num_nodes
  description = "quantity of vm's assigned to Kubernetes"
}

output "gke_node_location" {
  value       = var.location
  description = "location of vm's assigned to Kubernetes"
}