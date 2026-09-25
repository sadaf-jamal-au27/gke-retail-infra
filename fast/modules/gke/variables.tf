variable "project_id" { type = string }
variable "region" { type = string }
variable "env" { type = string }
variable "network_name" { type = string }
variable "subnet_name" { type = string }
variable "master_ipv4_cidr" { type = string }
variable "pods_range_name" { type = string }
variable "services_range_name" { type = string }

variable "master_authorized_cidr" {
  type        = string
  description = "CIDR allowed to reach the GKE control plane."
  default     = "0.0.0.0/0"
}

variable "k8s_namespace" {
  type    = string
  default = "retail"
}

variable "k8s_service_account" {
  type    = string
  default = "retail-app"
}
