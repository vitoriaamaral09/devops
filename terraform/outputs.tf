output "cluster_name" {
  description = "Nome do cluster Kind criado"
  value       = kind_cluster.devops.name
}

output "kubeconfig_path" {
  description = "Caminho do kubeconfig gerado para o cluster"
  value       = kind_cluster.devops.kubeconfig_path
}

output "client_certificate" {
  description = "Endpoint da API do cluster"
  value       = kind_cluster.devops.endpoint
}
