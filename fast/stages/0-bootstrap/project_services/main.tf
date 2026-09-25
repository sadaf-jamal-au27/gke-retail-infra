module "project_services" {
  source     = "../../../modules/project_services"
  project_id = var.project_id
  region     = var.region
}
