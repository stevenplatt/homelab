# define values that should be saved/printed to console
# Google Cloud

output "google_cloud_project_id" {
  value       = module.gcp-kubernetes-deploy.project_id
  description = "Deployment Name"
}
output "kubernetes_cluster_region" {
  value       = module.gcp-kubernetes-deploy.region
  description = "GCP deployment region"
}

output "kubernetes_vm_location" {
  value       = module.gcp-kubernetes-deploy.gke_node_location
  description = "Kubernetes vm deployment location"
}

output "kubernetes_vm_count" {
  value       = module.gcp-kubernetes-deploy.gke_node_count
  description = "number of vm's in the Kubernetes cluster"
}