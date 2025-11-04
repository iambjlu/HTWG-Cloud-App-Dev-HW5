# variables.tf

variable "project_id" {
  description = "你的 Google Cloud Project ID"
  type        = string
  default     = "htwg-cloudapp-hw"
}

variable "region" {
  description = "主要部署區域"
  type        = string
  default     = "asia-east1"
}

variable "zone" {
  description = "Cloud SQL 的 Zone"
  type        = string
  default     = "asia-east1-b"
}

# --- Cloud SQL 變數 ---
variable "db_name" {
  description = "Cloud SQL 實例的名稱"
  type        = string
  default     = "htwg-cloud-app-dev-1141104" # 你的 gcloud 參數
}

variable "db_database_name" {
  default     = "travel_app_db" 
  description = "要在 SQL 實例中建立的資料庫名稱"
  type        = string
  # 你必須在 .tfvars 填這個
}

variable "db_root_password" {
  description = "資料庫 root 密碼"
  type        = string
  default     = "mypassword" 
  sensitive   = true
}

# --- 後端變數 ---
variable "backend_service_name" {
  description = "後端 Cloud Run 服務名稱"
  type        = string
  default     = "cloud-app-hw-backend"
}

variable "backend_image" {
  description = "後端 Docker 映像檔路徑"
  type        = string
  default     = "asia-east1-docker.pkg.dev/htwg-cloudapp-hw/cloud-app-hw-backend/cloud-app-hw-backend:latest"
}

# --- 前端變數 ---
variable "frontend_service_name" {
  description = "前端 Cloud Run 服務名稱"
  type        = string
  default     = "cloud-app-hw-frontend"
}

variable "frontend_image" {
  description = "前端 Docker 映像檔路徑"
  type        = string
  default     = "asia-east1-docker.pkg.dev/htwg-cloudapp-hw/cloud-app-hw-frontend/cloud-app-hw-frontend:latest"
}

# --- 手動步驟用的變數 ---
variable "manual_db_host" {
  description = "【手動填寫】步驟 1 拿到的資料庫 IP"
  type        = string
  default     = "" # 保持空白
}

variable "manual_backend_url" {
  description = "【手動填寫】步驟 2 拿到的後端 URL"
  type        = string
  default     = "" # 保持空白
}

# --- (新加入) 根據 README.md 補上的變數 ---
variable "db_user" {
  description = "資料庫使用者 (根據 README 預設為 root)"
  type        = string
  default     = "cloudapp_user"
}

variable "db_port" {
  description = "資料庫 Port (根據 README 預設為 3306)"
  type        = string
  default     = "3306"
}

variable "GCP_SERVICE_ACCOUNT_JSON" {
  type        = string
  description = "Service account JSON key (as a string)"
  sensitive   = true # <-- 100% W move (這會把它藏在 'apply' log 裡)
}

variable "GEMINI_API_KEY" {
  type        = string
  description = "API Key for Gemini"
  sensitive   = true
}

variable "GCP_BUCKET_NAME" {
  type        = string
  description = "Name of the GCS bucket"
  sensitive   = false # <-- This one probably isn't a secret (這個大概不是機密)
}

variable "VITE_FIREBASE_APP_ID" {
  type        = string
  description = "Firebase App ID for VITE frontend"
  sensitive   = true # <-- (You had this warning too / 你也有這個警告)
}


variable "VITE_API_BASE_URL" {
  type        = string
  description = "Frontend API base URL (manual_backend_url)"
  sensitive   = false # This is just a URL
}

variable "VITE_FIREBASE_API_KEY" {
  type        = string
  description = "Firebase API Key"
  sensitive   = true
}

variable "VITE_FIREBASE_AUTH_DOMAIN" {
  type        = string
  description = "Firebase Auth Domain"
  sensitive   = true
}

variable "VITE_FIREBASE_PROJECT_ID" {
  type        = string
  description = "Firebase Project ID"
  sensitive   = true # You got a warning for this one too
}

variable "VITE_FIREBASE_STORAGE_BUCKET" {
  type        = string
  description = "Firebase Storage Bucket"
  sensitive   = true
}

variable "VITE_MEASUREMENTID" {
  type        = string
  description = "Firebase Measurement ID"
  sensitive   = true
}


