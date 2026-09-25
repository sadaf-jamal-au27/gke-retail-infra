output "cluster_name" {
  value = try(module.gke[0].cluster_name, null)
}

output "artifact_registry_url" {
  value = try(module.gke[0].artifact_registry_url, null)
}

output "workload_gsa_email" {
  value = try(module.gke[0].workload_gsa_email, null)
}

output "cluster_location" {
  value = try(module.gke[0].cluster_location, null)
}
