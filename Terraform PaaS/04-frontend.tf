# 04-frontend.tf
# (修正版)
# 錯誤原因：'--no-cpu-boost' (gcloud) 不等於 'startup_cpu_boost' (Terraform)。
#           'startup_cpu_boost' 在 'google_cloud_run_v2_service' 裡是無效參數。
# 修正：
# 1. 刪除了 'startup_cpu_boost = false' 這行。
# 2. 'google_cloud_run_v2_service' 的預設行為是 'cpu_idle = true'，
#    這 *已經* 實現了 '--no-cpu-boost' 的效果 (閒置時 CPU 降頻)。

resource "google_cloud_run_v2_service" "frontend" {
  name     = var.frontend_service_name
  location = var.region
  project  = var.project_id

  # 確保後端部署完畢
  depends_on = [
    google_cloud_run_v2_service.backend
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
      image = var.frontend_image
      
      # 資源：1 CPU, 1GiB 記憶體
      # 'startup_cpu_boost = false' 已被移除 (因為無效)
      # 預設的 'cpu_idle = true' 就等於 gcloud 的 '--no-cpu-boost'
      resources {
        limits = {
          cpu    = "1"
          memory = "1Gi"
        }
      }

      # 環境變數
      env {
        name  = "VITE_API_BASE_URL"
        value = var.VITE_API_BASE_URL # <-- 來自你的手動輸入
      }
      env{
        name="VITE_FIREBASE_API_KEY"
        value=var.VITE_FIREBASE_API_KEY
      }
      env{
        name="VITE_FIREBASE_AUTH_DOMAIN"
        value=var.VITE_FIREBASE_AUTH_DOMAIN
      }
      env{
        name="VITE_FIREBASE_PROJECT_ID"
        value=var.VITE_FIREBASE_PROJECT_ID
      }
      env{
        name="VITE_FIREBASE_APP_ID"
        value=var.VITE_FIREBASE_APP_ID
      }
      env{
        name="VITE_FIREBASE_STORAGE_BUCKET"
        value=var.VITE_FIREBASE_STORAGE_BUCKET
      }
      env{
        name="VITE_MEASUREMENTID"
        value=var.VITE_MEASUREMENTID
      }
    }
  }
}

# 允許公開（未經驗證）的流量
resource "google_cloud_run_service_iam_member" "frontend_invoker" {
  location = google_cloud_run_v2_service.frontend.location
  service  = google_cloud_run_v2_service.frontend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# --- 輸出 (Output) ---

output "frontend_url" {
  description = "前端服務的公開 URL"
  value       = google_cloud_run_v2_service.frontend.uri
}


