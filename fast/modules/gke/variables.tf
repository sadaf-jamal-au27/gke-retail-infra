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

variable "assets_bucket_name" {
  type        = string
  description = "GCS assets bucket for object-level IAM. Defaults to {project}-retail-assets-{env}."
  default     = null
}

variable "secret_ids" {
  type        = list(string)
  description = "Secret Manager secret IDs to create (if missing) and grant secretAccessor to the workload SA."
  default     = []
}
