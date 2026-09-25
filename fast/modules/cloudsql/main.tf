resource "google_sql_database_instance" "retail" {
  name             = "retail-${var.env}-pg"
  database_version = "POSTGRES_15"
  region           = var.region

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_autoresize   = true
    disk_size         = var.disk_size_gb

    ip_configuration {
      ipv4_enabled    = false
      private_network = var.network_id
    }

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = var.env == "prod"
      transaction_log_retention_days = var.env == "prod" ? 7 : 1
    }

    database_flags {
      name  = "cloudsql.iam_authentication"
      value = "on"
    }
  }

  deletion_protection = var.env == "prod"
}

resource "google_sql_database" "retail" {
  name     = "retail"
  instance = google_sql_database_instance.retail.name
}

resource "google_sql_user" "app" {
  name     = "retail_app"
  instance = google_sql_database_instance.retail.name
  password = var.database_password
}
