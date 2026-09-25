variable "project_id" { type = string }
variable "region" { type = string }
variable "env" { type = string }
variable "network_id" { type = string }

variable "database_password" {
  type      = string
  sensitive = true
}

variable "tier" {
  type    = string
  default = "db-custom-2-8192"
}

variable "availability_type" {
  type    = string
  default = "ZONAL"
}

variable "disk_size_gb" {
  type    = number
  default = 20
}
