# define values that should be saved/printed to console

output "telecomsteve_nodeport" {
  value       = kubernetes_service.nodeport-service.spec[0].port[0].node_port
  description = "External IP for the telecomsteve website"
}

output "telecomsteve_clusterip" {
  value       = kubernetes_service.cluster-ip-service.spec[0].cluster_ip
  description = "External IP for the telecomsteve website"
}


