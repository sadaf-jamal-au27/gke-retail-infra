output "assets_bucket_name" {
  value = google_storage_bucket.assets.name
}

output "terraform_state_bucket_name" {
  value = data.google_storage_bucket.terraform_state.name
}
