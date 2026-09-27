moved {
  from = module.project_services[0]
  to   = module.project_services
}

module "project_services" {
  source     = "../../../modules/project_services"
  project_id = var.project_id
  region     = var.region
  services   = var.services
}
