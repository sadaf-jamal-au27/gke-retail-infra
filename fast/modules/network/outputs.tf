output "network_id" { value = module.vpc.id }
output "network_name" { value = module.vpc.name }
output "gke_subnet_name" { value = local.gke_subnet }
output "pods_range_name" { value = "pods" }
output "services_range_name" { value = "services" }
output "serverless_connector_id" { value = google_vpc_access_connector.serverless.id }
