# Standard inputs used by provider.tf (set per environment via Terragrunt).

variable "project_id" {
  type        = string
  description = "GCP project ID."
}

variable "region" {
  type        = string
  description = "Default GCP region for regional resources."
}
