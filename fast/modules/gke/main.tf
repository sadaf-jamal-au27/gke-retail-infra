resource "google_artifact_registry_repository" "retail" {
  location      = var.region
  repository_id = "retail"
  format        = "DOCKER"
  description   = "Retail microservices images (${var.env})"
}

resource "google_service_account" "workload" {
  account_id   = "retail-workload-${var.env}"
  display_name = "Retail GKE Workload Identity (${var.env})"
}

# Project-level IAM — CI SA (roles/editor) cannot setIamPolicy on project / AR / secrets.
# Keep these in Terraform so apply does not try to delete imported bindings (403).
resource "google_project_iam_member" "workload_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.workload.email}"
}

resource "google_project_iam_member" "workload_pubsub_sub" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = "serviceAccount:${google_service_account.workload.email}"
}

resource "google_project_iam_member" "workload_cloudsql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.workload.email}"
}

resource "google_project_iam_member" "workload_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.workload.email}"
}

resource "google_project_iam_member" "workload_artifact_registry" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.workload.email}"
}

# Bucket-level IAM (storage.admin on CI can usually set bucket policy).
locals {
  assets_bucket = coalesce(var.assets_bucket_name, "${var.project_id}-retail-assets-${var.env}")
}

data "google_storage_bucket" "assets" {
  name = local.assets_bucket
}

resource "google_storage_bucket_iam_member" "workload_assets" {
  bucket = data.google_storage_bucket.assets.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.workload.email}"
}

# Optional secrets (create only). IAM stays project-level secretAccessor above —
# CI cannot secretmanager.secrets.setIamPolicy without Secret Admin / Owner.
resource "google_secret_manager_secret" "app" {
  for_each  = toset(var.secret_ids)
  project   = var.project_id
  secret_id = each.value

  replication {
    auto {}
  }

  labels = {
    env = var.env
  }
}

resource "google_container_cluster" "primary" {
  provider = google-beta

  name     = "retail-${var.env}"
  location = var.region

  enable_autopilot = true
  networking_mode  = "VPC_NATIVE"

  network    = var.network_name
  subnetwork = var.subnet_name

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.master_authorized_cidr
      display_name = "authorized-admin-network"
    }
  }

  release_channel {
    channel = "REGULAR"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }
}

resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = google_service_account.workload.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.k8s_namespace}/${var.k8s_service_account}]"

  depends_on = [google_container_cluster.primary]
}
