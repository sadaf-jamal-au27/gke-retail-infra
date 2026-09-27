moved {
  from = module.github_wif[0]
  to   = module.github_wif
}

module "github_wif" {
  source       = "../../../modules/github_wif"
  project_id   = var.project_id
  region       = var.region
  env          = var.env
  github_org   = var.github_org
  github_repos = var.github_repos
  pool_id      = var.pool_id
  provider_id  = var.provider_id
}
