output "instance_connection_name" {
  value = try(module.cloudsql[0].instance_connection_name, null)
}

output "instance_name" {
  value = try(module.cloudsql[0].instance_name, null)
}
