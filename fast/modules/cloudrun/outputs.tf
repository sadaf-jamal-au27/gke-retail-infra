output "bff_url" {
  value = google_cloud_run_v2_service.bff.uri
}

output "bff_name" {
  value = google_cloud_run_v2_service.bff.name
}
