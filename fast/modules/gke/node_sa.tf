# Least-privilege node identity. Terraform creates the SA and lets the GKE
# robot impersonate it. Project / Artifact Registry IAM stays out of this
# module: CI (roles/editor) cannot setIamPolicy on the project or AR repo (403).
# Owner grants those once — see scripts/grant-gke-node-sa-iam.sh

data "google_project" "current" {
  project_id = var.project_id
}

resource "google_service_account" "node" {
  account_id   = "gke-node-${var.env}"
  display_name = "GKE node (${var.env})"
  description  = "Autopilot node SA: pull Artifact Registry images, write logs/metrics."
}

# SA-level IAM — CI has roles/iam.serviceAccountAdmin, so this apply works.
resource "google_service_account_iam_member" "node_used_by_gke" {
  service_account_id = google_service_account.node.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:service-${data.google_project.current.number}@container-engine-robot.iam.gserviceaccount.com"
}
