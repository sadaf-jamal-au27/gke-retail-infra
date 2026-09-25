variable "project_id" { type = string }
variable "region" { type = string }
variable "env" { type = string }
variable "bff_sa_email" { type = string }
variable "vpc_connector_id" { type = string }

variable "image" {
  type    = string
  default = ""
}

variable "allow_unauthenticated" {
  type    = bool
  default = false
}
