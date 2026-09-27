# Least-privilege node identity. Do not use the default Compute Engine SA
# (it often has roles/editor). Nodes only pull images and write telemetry.

data "google_project" "current" {
  project_id = var.project_id
}

resource "google_service_account" "node" {
  account_id   = "gke-node-${var.env}"
  display_name = "GKE node (${var.env})"
  description  = "Autopilot node SA: pull Artifact Registry images, write logs/metrics."
}

resource "google_project_iam_member" "node_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/autoscaling.metricsWriter",
    "roles/stackdriver.resourceMetadata.writer",
  ])
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.node.email}"
}

resource "google_artifact_registry_repository_iam_member" "node_pull" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.retail.repository_id
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.node.email}"
}

# GKE control plane must be allowed to attach this SA to nodes.
resource "google_service_account_iam_member" "node_used_by_gke" {
  service_account_id = google_service_account.node.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:service-${data.google_project.current.number}@container-engine-robot.iam.gserviceaccount.com"
}
