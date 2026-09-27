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
variable "master_ipv4_cidr" {
  type    = string
  default = "172.16.0.0/28"
}
variable "master_authorized_cidr" {
  type    = string
  default = "0.0.0.0/0"
}
variable "k8s_namespace" {
  type    = string
  default = "retail"
}
variable "k8s_service_account" {
  type    = string
  default = "retail-app"
}

variable "use_custom_node_sa" {
  type    = bool
  default = false
}

variable "secret_ids" {
  type        = list(string)
  description = "Secret Manager IDs to keep (must match live state)."
  default     = []
}
