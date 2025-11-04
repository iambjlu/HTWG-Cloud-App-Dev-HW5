locals {
  run_region            = var.region
  connection_name       = "${var.project_id}:${var.region}:${var.sql_instance_name}"
  backend_service_name  = "cloud-app-hw-backend"
  frontend_service_name = "cloud-app-hw-frontend"
  backend_sa_name       = "run-backend"
  frontend_sa_name      = "run-frontend"
}

# 1) Enable required APIs
resource "google_project_service" "apis" {
  for_each = toset([
    "run.googleapis.com",                 # Cloud Run Admin API
    "artifactregistry.googleapis.com",    # Artifact Registry API
    "firestore.googleapis.com",           # Cloud Firestore API
    "sts.googleapis.com",                 # Token/Security Token Service API
    "firebasestorage.googleapis.com",     # Cloud Storage for Firebase API
    "identitytoolkit.googleapis.com",     # Identity Toolkit API
    "monitoring.googleapis.com",          # Cloud Monitoring API
    "storage.googleapis.com",             # Cloud Storage API
    "sqladmin.googleapis.com"             # Cloud SQL Admin API
  ])
  service            = each.key
  disable_on_destroy = false
}

# 2) Cloud SQL instance (MySQL 8.0, Shared Core)
resource "google_sql_database_instance" "mysql" {
  name             = var.sql_instance_name
  database_version = "MYSQL_8_0"
  project          = var.project_id
  region           = var.region

  settings {
    tier = "db-f1-micro"     # Shared core; or change to "db-g1-small" if you prefer

    disk_type       = "PD_HDD"
    disk_size       = 10
    disk_autoresize = false

    availability_type = "ZONAL"

    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = "allow-all"
        value = "0.0.0.0/0"
      }
    }

    backup_configuration {
      enabled             = false
      binary_log_enabled  = false
    }

    maintenance_window {
      day          = 0
      hour         = 0
      update_track = "stable"
    }
  }

  deletion_protection = false
  depends_on          = [google_project_service.apis]
}

# Initial database only; DO NOT touch users/passwords
resource "google_sql_database" "db" {
  name     = var.sql_database_name
  instance = google_sql_database_instance.mysql.name
}

# 3) Service Accounts for Cloud Run
resource "google_service_account" "run_backend" {
  account_id   = local.backend_sa_name
  display_name = "Cloud Run backend SA"
}

resource "google_service_account" "run_frontend" {
  account_id   = local.frontend_sa_name
  display_name = "Cloud Run frontend SA"
}

# Grant minimal roles: Cloud SQL client + Artifact Registry reader
resource "google_project_iam_member" "sa_cloudsql_client_backend" {
  role   = "roles/cloudsql.client"
  member = "serviceAccount:${google_service_account.run_backend.email}"
}

resource "google_project_iam_member" "sa_cloudsql_client_frontend" {
  role   = "roles/cloudsql.client"
  member = "serviceAccount:${google_service_account.run_frontend.email}"
}

resource "google_project_iam_member" "sa_artifact_reader_backend" {
  role   = "roles/artifactregistry.reader"
  member = "serviceAccount:${google_service_account.run_backend.email}"
}

resource "google_project_iam_member" "sa_artifact_reader_frontend" {
  role   = "roles/artifactregistry.reader"
  member = "serviceAccount:${google_service_account.run_frontend.email}"
}

# 4) Cloud Run - Backend
resource "google_cloud_run_v2_service" "backend" {
  name     = local.backend_service_name
  location = local.run_region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.run_backend.email
    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }
    containers {
      image = var.backend_image

      resources {
        cpu_idle = true
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
      }

      # env from map
      dynamic "env" {
        for_each = var.backend_env
        content {
          name  = env.key
          value = env.value
        }
      }

      # Mount Cloud SQL connection at /cloudsql
      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [local.connection_name]
      }
    }
  }

  depends_on = [
    google_project_service.apis,
    google_sql_database.db
  ]
}

# Public access for simplicity; remove if you want authenticated invokers only
resource "google_cloud_run_v2_service_iam_member" "backend_public" {
  location = google_cloud_run_v2_service.backend.location
  name     = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# 5) Cloud Run - Frontend
resource "google_cloud_run_v2_service" "frontend" {
  name     = local.frontend_service_name
  location = local.run_region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.run_frontend.email
    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }
    containers {
      image = var.frontend_image

      resources {
        cpu_idle = true
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
      }

      dynamic "env" {
        for_each = var.frontend_env
        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }

  depends_on = [google_project_service.apis]
}

resource "google_cloud_run_v2_service_iam_member" "frontend_public" {
  location = google_cloud_run_v2_service.frontend.location
  name     = google_cloud_run_v2_service.frontend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
