data "terraform_remote_state" "network" {
  backend = "gcs"

  config = {
    bucket = var.state_bucket
    prefix = "${var.env}/network"
  }
}

locals {
  network_id            = try(data.terraform_remote_state.network.outputs.network_id, null)
  network_outputs_ready = local.network_id != null
}

module "cloudsql" {
  count = local.network_outputs_ready ? 1 : 0

  source            = "../../../modules/cloudsql"
  project_id        = var.project_id
  region            = var.region
  env               = var.env
  network_id        = local.network_id
  database_password = var.database_password
  tier              = var.tier
  availability_type = var.availability_type
  disk_size_gb      = var.disk_size_gb
}
