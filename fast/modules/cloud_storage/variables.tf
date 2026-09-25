variable "project_id" { type = string }
variable "region" { type = string }
variable "env" { type = string }

variable "force_destroy" {
  type    = bool
  default = false
}

variable "enable_versioning" {
  type    = bool
  default = true
}
