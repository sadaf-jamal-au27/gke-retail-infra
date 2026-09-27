variable "project_id" { type = string }
variable "region" { type = string }
variable "env" { type = string }

variable "github_org" { type = string }

variable "github_repos" {
  type        = list(string)
  description = "GitHub repository names (without org) that may use this pool."
}

variable "pool_id" {
  type    = string
  default = "github-pool"
}

variable "provider_id" {
  type    = string
  default = "github-provider"
}

variable "ci_service_account_id" {
  type    = string
  default = "github-ci"
}

variable "terraform_roles" {
  type = list(string)
  # Do NOT include roles the CI SA cannot grant to itself (needs Owner / projectIamAdmin).
  # Grant once as a human: roles/iam.workloadIdentityPoolAdmin, roles/secretmanager.admin
  default = [
    "roles/editor",
    "roles/iam.serviceAccountAdmin",
    "roles/storage.admin",
  ]
}

variable "state_bucket_name" {
  type        = string
  description = "Terraform state bucket for bucket-level IAM. Defaults to {project}-retail-tfstate-{env}."
  default     = null
}

variable "assets_bucket_name" {
  type        = string
  description = "Assets bucket for bucket-level IAM. Defaults to {project}-retail-assets-{env}."
  default     = null
}

variable "enable_secret_manager_admin" {
  type        = bool
  description = "Grant roles/secretmanager.admin to CI SA. Default false — CI cannot self-grant this (403); use Owner once if needed."
  default     = false
}
