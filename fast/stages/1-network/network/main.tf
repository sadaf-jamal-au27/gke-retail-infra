module "network" {
  source                    = "../../../modules/network"
  project_id                = var.project_id
  region                    = var.region
  env                       = var.env
  gke_subnet_cidr           = var.gke_subnet_cidr
  pods_cidr                 = var.pods_cidr
  services_cidr             = var.services_cidr
  sql_subnet_cidr           = var.sql_subnet_cidr
  serverless_connector_cidr = var.serverless_connector_cidr
}
