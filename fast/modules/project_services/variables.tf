variable "project_id" { type = string }
variable "region" { type = string }

variable "services" {
  type = list(string)
  default = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "storage.googleapis.com",
    "secretmanager.googleapis.com",
  ]
}
