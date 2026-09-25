module "pubsub" {
  source     = "../../../modules/pubsub"
  project_id = var.project_id
  region     = var.region
  env        = var.env
}
