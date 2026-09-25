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
variable "force_destroy" {
  type    = bool
  default = false
}

variable "enable_versioning" {
  type    = bool
  default = true
}
