output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "artifact_registry_url" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.retail.repository_id}"
}

output "workload_gsa_email" {
  value = google_service_account.workload.email
}

output "cluster_location" {
  value = var.region
}
