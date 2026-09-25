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
variable "services" {
  type = list(string)
  default = [
    "artifactregistry.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "storage.googleapis.com",
  ]
}
