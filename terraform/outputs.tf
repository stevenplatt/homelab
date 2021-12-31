# define values that should be saved/printed to console
# Google Cloud

output "google_cloud_project_id" {
  value       = module.kubernetes-deploy.project_id
  description = "Deployment Name"
}
output "kubernetes_cluster_region" {
  value       = module.kubernetes-deploy.region
  description = "GCP deployment region"
}

output "kubernetes_vm_location" {
  value       = module.kubernetes-deploy.gke_node_location
  description = "Kubernetes vm deployment location"
}

output "kubernetes_vm_count" {
  value       = module.kubernetes-deploy.gke_node_count
  description = "number of vm's in the Kubernetes cluster"
}

output "cluster_ip" {
  value       = module.kubernetes-deploy.kubernetes_cluster_host
  description = "number of vm's in the Kubernetes cluster"
}




# telecomsteve website deployment
output "telecomsteve_port" {
  value       = module.telecomsteve-deploy.telecomsteve_nodeport
  description = "External IP for the telecomsteve website"
}