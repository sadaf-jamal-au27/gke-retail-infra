module "cloud_storage" {
  source        = "../../../modules/cloud_storage"
  project_id    = var.project_id
  region        = var.region
  env           = var.env
  force_destroy = var.force_destroy
}
