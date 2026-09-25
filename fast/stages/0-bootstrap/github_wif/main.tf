module "github_wif" {
  source      = "../../../modules/github_wif"
  project_id  = var.project_id
  region      = var.region
  env         = var.env
  github_org  = var.github_org
  github_repo = var.github_repo
}
