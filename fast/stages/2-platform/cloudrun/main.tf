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

module "cloudrun" {
  source                = "../../../modules/cloudrun"
  project_id            = var.project_id
  region                = var.region
  env                   = var.env
  bff_sa_email          = data.terraform_remote_state.gke.outputs.workload_gsa_email
  vpc_connector_id      = data.terraform_remote_state.network.outputs.serverless_connector_id
  allow_unauthenticated = var.allow_unauthenticated
}
