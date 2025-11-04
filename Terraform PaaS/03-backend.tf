# 03-backend.tf
# (修正版)
# 1. 修正 'env = [...]' (list 語法)
#    改為 'env { ... } env { ... }' (block 語法)

resource "google_cloud_run_v2_service" "backend" {
  name     = var.backend_service_name
  location = var.region
  project  = var.project_id

  # 確保資料庫建立後才部署
  depends_on = [
    google_sql_database_instance.default
  ]

  template {
    annotations = {
      # This "key" (鍵) 100% doesn't matter (不重要).
      # "client.terraform.io/update" is just a "pro" (專業) vibe.
      "client.terraform.io/update" = timestamp()
    }
    
    # --min-instances=0
    scaling {
      min_instance_count = 0
      max_instance_count = 5
    }

    containers {
      image = var.backend_image

      # 資源：1 CPU, 1GiB 記憶體
      resources {
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
      }

      # --- 修正點：'env' 語法 ---
      # 環境變數 (根據 README.md)
      env {
        name  = "DB_HOST"
        value = var.manual_db_host # <-- 來自你的手動輸入
      }
      env {
        name  = "DB_USER"
        value = var.db_user
      }
      env {
        name  = "DB_PASSWORD"
        value = var.db_root_password
      }
      env {
        name  = "DB_PORT"
        value = var.db_port
      }
      env {
        name  = "DB_DATABASE"
        value = var.db_database_name
      }
      env {
        name  = "GCP_SERVICE_ACCOUNT_JSON"
        value = var.GCP_SERVICE_ACCOUNT_JSON
      }
      env {
        name  = "GEMINI_API_KEY"
        value = var.GEMINI_API_KEY
      }
      env {
        name  = "GCP_BUCKET_NAME"
        value = var.GCP_BUCKET_NAME
      }

      # --- 修正結束 ---
    }

    # --set-cloudsql-instances
    vpc_access {
      connector = "" # 留空以使用 Cloud SQL 內建的 public IP 連線
      # 注意：更安全作法是設定 VPC Connector + Private IP，
      # 但目前依照你的 gcloud (public IP) 做法，這裡留空。
    }
  }
}

# 允許公開（未經驗證）的流量，這樣前端才能呼叫
resource "google_cloud_run_service_iam_member" "backend_invoker" {
  location = google_cloud_run_v2_service.backend.location
  service  = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# --- 輸出 (Output) ---

output "backend_url" {
  description = "後端服務的 URL (給前端用)"
  value       = google_cloud_run_v2_service.backend.uri
}


