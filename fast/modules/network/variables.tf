variable "project_id" { type = string }
variable "region" { type = string }
variable "env" { type = string }

variable "gke_subnet_cidr" {
  type    = string
  default = "10.10.0.0/20"
}

variable "pods_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "services_cidr" {
  type    = string
  default = "10.30.0.0/20"
}

variable "sql_subnet_cidr" {
  type    = string
  default = "10.11.0.0/24"
}

variable "serverless_connector_cidr" {
  type    = string
  default = "10.8.0.0/28"
}
