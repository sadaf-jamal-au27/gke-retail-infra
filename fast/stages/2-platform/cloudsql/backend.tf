# Partial GCS backend — bucket and prefix are in fast/backends/<env>/<stack>.hcl
terraform {
  backend "gcs" {}
}
