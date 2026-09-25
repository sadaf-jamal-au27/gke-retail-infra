variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "env" {
  type = string
}

variable "state_bucket" {
  type        = string
  description = "GCS bucket holding remote state for stack dependencies."
}
variable "database_password" {
  type      = string
  sensitive = true
}
variable "tier" { type = string }
variable "availability_type" { type = string }
variable "disk_size_gb" { type = number }
