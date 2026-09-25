output "bff_url" {
  value = try(module.cloudrun[0].bff_url, null)
}

output "bff_name" {
  value = try(module.cloudrun[0].bff_name, null)
}
