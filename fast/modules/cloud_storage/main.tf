resource "google_storage_bucket" "assets" {
  name                        = "${var.project_id}-retail-assets-${var.env}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

  versioning {
    enabled = var.enable_versioning
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "terraform_state" {
  name                        = "${var.project_id}-retail-tfstate-${var.env}"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

  versioning {
    enabled = true
  }
}
