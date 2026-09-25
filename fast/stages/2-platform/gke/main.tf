data "terraform_remote_state" "network" {
  backend = "gcs"

  config = {
    bucket = var.state_bucket
    prefix = "${var.env}/network"
  }
}

module "gke" {
  source                  = "../../../modules/gke"
  project_id              = var.project_id
  region                  = var.region
  env                     = var.env
  network_name            = data.terraform_remote_state.network.outputs.network_name
  subnet_name             = data.terraform_remote_state.network.outputs.gke_subnet_name
  pods_range_name         = data.terraform_remote_state.network.outputs.pods_range_name
  services_range_name     = data.terraform_remote_state.network.outputs.services_range_name
  master_ipv4_cidr        = var.master_ipv4_cidr
  master_authorized_cidr  = var.master_authorized_cidr
  k8s_namespace           = var.k8s_namespace
  k8s_service_account     = var.k8s_service_account
}
