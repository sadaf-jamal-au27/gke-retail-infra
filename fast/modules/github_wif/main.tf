resource "google_iam_workload_identity_pool" "github" {
  workload_identity_pool_id = "${var.pool_id}-${var.env}"
  display_name              = "GitHub Actions (${var.env})"
  description               = "OIDC pool for ${var.github_org}/${var.github_repo}"
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
  attribute_condition = "assertion.repository == \"${var.github_org}/${var.github_repo}\""
}

resource "google_service_account" "ci" {
  account_id   = "${var.ci_service_account_id}-${var.env}"
  display_name = "GitHub Actions CI (${var.env})"
}

resource "google_service_account_iam_member" "wif_binding" {
  service_account_id = google_service_account.ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_org}/${var.github_repo}"
}

resource "google_project_iam_member" "ci_roles" {
  for_each = toset(var.terraform_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.ci.email}"
}
