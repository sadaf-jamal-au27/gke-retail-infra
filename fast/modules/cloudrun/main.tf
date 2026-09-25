locals {
  image = coalesce(
    var.image,
    "${var.region}-docker.pkg.dev/${var.project_id}/retail/bff-api-service:1.0.0"
  )
}

resource "google_cloud_run_v2_service" "bff" {
  name     = "retail-bff-${var.env}"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = var.bff_sa_email

    vpc_access {
      connector = var.vpc_connector_id
      egress    = "PRIVATE_RANGES_ONLY"
    }

    containers {
      image = local.image

      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.project_id
      }
      env {
        name  = "BFF_MODE"
        value = "cloudrun"
      }

      resources {
        limits = {
          cpu    = "2"
          memory = "1Gi"
        }
      }
    }

    scaling {
      min_instance_count = var.env == "prod" ? 1 : 0
      max_instance_count = var.env == "prod" ? 20 : 5
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.allow_unauthenticated ? 1 : 0

  name     = google_cloud_run_v2_service.bff.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}
