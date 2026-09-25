variable "project_id" { type = string }
variable "region" { type = string }
variable "env" { type = string }

variable "github_org" { type = string }
variable "github_repo" { type = string }

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
    "roles/storage.admin",
  ]
}
