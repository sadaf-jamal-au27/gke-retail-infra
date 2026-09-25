output "cluster_name" {
  value = module.gke.cluster_name
}

output "artifact_registry_url" {
  value = module.gke.artifact_registry_url
}

output "workload_gsa_email" {
  value = module.gke.workload_gsa_email
}

output "cluster_location" {
  value = module.gke.cluster_location
}
