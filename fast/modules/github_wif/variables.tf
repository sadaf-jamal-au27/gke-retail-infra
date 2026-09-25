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
  default = [
    "roles/editor",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.workloadIdentityPoolAdmin",
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
  description = "Grant roles/secretmanager.admin on the project to the CI SA."
  default     = true
}
