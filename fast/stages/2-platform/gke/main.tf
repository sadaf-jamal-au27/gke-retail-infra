data "terraform_remote_state" "network" {
  backend = "gcs"

  config = {
    bucket = var.state_bucket
    prefix = "${var.env}/network"
  }
}

locals {
  network_name          = try(data.terraform_remote_state.network.outputs.network_name, null)
  gke_subnet_name       = try(data.terraform_remote_state.network.outputs.gke_subnet_name, null)
  pods_range_name       = try(data.terraform_remote_state.network.outputs.pods_range_name, null)
  services_range_name   = try(data.terraform_remote_state.network.outputs.services_range_name, null)
  network_outputs_ready = local.network_name != null
}

module "gke" {
  count = local.network_outputs_ready ? 1 : 0

  source                 = "../../../modules/gke"
  project_id             = var.project_id
  region                 = var.region
  env                    = var.env
  network_name           = local.network_name
  subnet_name            = local.gke_subnet_name
  pods_range_name        = local.pods_range_name
  services_range_name    = local.services_range_name
  master_ipv4_cidr       = var.master_ipv4_cidr
  master_authorized_cidr = var.master_authorized_cidr
  k8s_namespace          = var.k8s_namespace
  k8s_service_account    = var.k8s_service_account
}
