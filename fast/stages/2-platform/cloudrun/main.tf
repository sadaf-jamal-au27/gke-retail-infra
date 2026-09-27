data "terraform_remote_state" "network" {
  backend = "gcs"

  config = {
    bucket = var.state_bucket
    prefix = "${var.env}/network"
  }
}

data "terraform_remote_state" "gke" {
  backend = "gcs"

  config = {
    bucket = var.state_bucket
    prefix = "${var.env}/gke"
  }
}

locals {
  vpc_connector_id   = try(data.terraform_remote_state.network.outputs.serverless_connector_id, null)
  workload_gsa_email = try(data.terraform_remote_state.gke.outputs.workload_gsa_email, null)
  cloudrun_ready     = local.vpc_connector_id != null && local.workload_gsa_email != null
}

module "cloudrun" {
  count = local.cloudrun_ready ? 1 : 0

  source                = "../../../modules/cloudrun"
  project_id            = var.project_id
  region                = var.region
  env                   = var.env
  bff_sa_email          = local.workload_gsa_email
  vpc_connector_id      = local.vpc_connector_id
  allow_unauthenticated = var.allow_unauthenticated
}
