# 02-database.tf


resource "google_sql_database_instance" "default" {
  name             = var.db_name
  project          = var.project_id
  database_version = "MYSQL_8_0"
  region           = var.region

  settings {
    edition = "ENTERPRISE"
    tier    = "db-f1-micro" # f1-micro (shared-core)

    location_preference {
      zone = var.zone
    }

    # --- vvv 終極修正點 v3 (已驗證) vvv ---
    disk_type = "PD_HDD"
    disk_size = 10
    disk_autoresize = false # <-- 這是 'argument', 不是 'block'
    # --- ^^^ 終極修正點 v3 (已驗證) ^^^ ---

    availability_type = "ZONAL"

    backup_configuration {
      enabled            = false
      binary_log_enabled = false
    }

    ip_configuration {
      authorized_networks {
        value = "0.0.0.0/0"
        name  = "Allow All"
      }
      ipv4_enabled = true
      ssl_mode     = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
    }

    maintenance_window {
      hour = 0 # 'day' 留空 = any day
    }
  }

  root_password = var.db_root_password

  deletion_protection = false

  depends_on = [
    google_project_service.apis["sqladmin.googleapis.com"]
  ]
}


