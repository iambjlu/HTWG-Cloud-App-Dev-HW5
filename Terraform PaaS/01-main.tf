# 01-main.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# 啟用所有需要的 API
resource "google_project_service" "apis" {
  # 為了避免 destroy 時出錯，設定為 true
  disable_on_destroy = false

  # 使用 for_each 一次啟用所有 API
  for_each = toset([
    "run.googleapis.com",             # Cloud Run Admin API
    "artifactregistry.googleapis.com", # Artifact Registry API
    "firestore.googleapis.com",       # Cloud Firestore API
    "iamcredentials.googleapis.com",  # Token Service API (IAM)
    "firebase.googleapis.com",        # Cloud Storage for Firebase API
    "identitytoolkit.googleapis.com", # Identity Toolkit API
    "monitoring.googleapis.com",      # Cloud Monitoring API
    "storage.googleapis.com",         # Cloud Storage API
    "sqladmin.googleapis.com"         # Cloud SQL Admin API (部署資料庫需要)
  ])

  service = each.key
}

