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
variable "gke_subnet_cidr" { type = string }
variable "pods_cidr" { type = string }
variable "services_cidr" { type = string }
variable "sql_subnet_cidr" { type = string }
variable "serverless_connector_cidr" { type = string }
