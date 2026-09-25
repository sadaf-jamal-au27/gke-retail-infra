locals {
  github_repositories = [for name in var.github_repos : "${var.github_org}/${name}"]
  attribute_condition = join(" || ", [for repo in local.github_repositories : "assertion.repository == \"${repo}\""])
  assets_bucket       = coalesce(var.assets_bucket_name, "${var.project_id}-retail-assets-${var.env}")
  state_bucket        = coalesce(var.state_bucket_name, "${var.project_id}-retail-tfstate-${var.env}")
}

resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "${var.pool_id}-${var.env}"
  display_name              = "GitHub Actions (${var.env})"
  description               = "OIDC pool for ${join(", ", local.github_repositories)}"
}

resource "google_iam_workload_identity_pool_provider" "github" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "GitHub OIDC"
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  attribute_condition = local.attribute_condition
}

resource "google_service_account" "ci" {
  account_id   = "${var.ci_service_account_id}-${var.env}"
  display_name = "GitHub Actions CI (${var.env})"
}

resource "google_service_account_iam_member" "wif_binding" {
  for_each = toset(local.github_repositories)

  service_account_id = google_service_account.ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${each.value}"
}

# --- Project-level IAM (Terraform apply needs broad project APIs) ---
resource "google_project_iam_member" "ci_roles" {
  for_each = toset(var.terraform_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.ci.email}"
}

# --- Bucket-level IAM (state + assets; least privilege overlay on storage.admin) ---
data "google_storage_bucket" "terraform_state" {
  name = local.state_bucket
}

data "google_storage_bucket" "assets" {
  name = local.assets_bucket
}

resource "google_storage_bucket_iam_member" "ci_state" {
  bucket = data.google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ci.email}"
}

resource "google_storage_bucket_iam_member" "ci_assets" {
  bucket = data.google_storage_bucket.assets.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.ci.email}"
}

# --- Secret Manager project-level for CI (create/manage app secrets via Terraform) ---
resource "google_project_iam_member" "ci_secret_admin" {
  count   = var.enable_secret_manager_admin ? 1 : 0
  project = var.project_id
  role    = "roles/secretmanager.admin"
  member  = "serviceAccount:${google_service_account.ci.email}"
}
