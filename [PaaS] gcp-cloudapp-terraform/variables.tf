variable "project_id" {
  description = "GCP project id"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Run/SQL"
  type        = string
  default     = "asia-east1"
}

variable "backend_image" {
  description = "Artifact Registry image for backend"
  type        = string
  default     = "asia-east1-docker.pkg.dev/htwg-cloudapp-hw/cloud-app-hw-backend/cloud-app-hw-backend:latest"
}

variable "frontend_image" {
  description = "Artifact Registry image for frontend"
  type        = string
  default     = "asia-east1-docker.pkg.dev/htwg-cloudapp-hw/cloud-app-hw-frontend/cloud-app-hw-frontend:latest"
}

variable "sql_instance_name" {
  description = "Cloud SQL instance name"
  type        = string
  default     = "mysql1141104"
}

variable "sql_database_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "backend_env" {
  description = "Backend env vars (map). Values here are placeholders; edit as needed."
  type        = map(string)
  default = {
    PORT        = "8080"
    NODE_ENV    = "production"
    DB_HOST     = "127.0.0.1"
    DB_USER     = "root"
    DB_PASSWORD = ""         # 保持空字串，尊重現有程式
    DB_NAME     = "appdb"
    DB_PORT     = "3306"
    # 其他依你的 Readme.md 自填
    FIREBASE_API_KEY        = "__FILL_ME__"
    FIREBASE_PROJECT_ID     = "__FILL_ME__"
    FIREBASE_STORAGE_BUCKET = "__FILL_ME__"
  }
}

variable "frontend_env" {
  description = "Frontend env vars (map). Values here are placeholders; edit as needed."
  type        = map(string)
  default = {
    VITE_API_BASE_URL = "https://cloud-app-hw-backend-XXXXXXXX-asia-east1.run.app"
    NODE_ENV          = "production"
  }
}
