output "network_id" {
  value = module.network.network_id
}

output "network_name" {
  value = module.network.network_name
}

output "gke_subnet_name" {
  value = module.network.gke_subnet_name
}

output "pods_range_name" {
  value = module.network.pods_range_name
}

output "services_range_name" {
  value = module.network.services_range_name
}

output "serverless_connector_id" {
  value = module.network.serverless_connector_id
}
