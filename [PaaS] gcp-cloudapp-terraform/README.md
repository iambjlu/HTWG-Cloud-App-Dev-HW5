# Infra for Cloud Run + Cloud SQL (Shared Core) — Terraform

> 重點：**Shared Core (`db-f1-micro`)**、**不變更 root 密碼**、**Cloud Run 前後端**一次部署。

## 先決條件
- 安裝 **Terraform 1.8+**
- 安裝 **Google Cloud SDK**
- 已把映像推到 **Artifact Registry**
- 專案已綁 **Billing**

## 登入
```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project htwg-cloudapp-hw
```

## 使用方式
```bash
# 1) 在這個資料夾
terraform init

# 2) 先看變數
cp terraform.tfvars.example terraform.tfvars
# 編輯 terraform.tfvars，把 backend_env / frontend_env 改成你 Readme.md 的值

# 3) 套用
terraform apply
```

## 會做什麼
- 啟用必要 API（Run / Artifact Registry / Firestore / STS / Firebase Storage / Identity Toolkit / Monitoring / Storage / SQL Admin）
- 建立 **Cloud SQL (MySQL 8.0)**：`db-f1-micro`（Shared Core）、HDD 10GB、無備份、Public IPv4、白名單 `0.0.0.0/0`（可自行縮限）
- **不建立/不修改** 任何使用者或密碼（即 **不會動 root 密碼**）
- 建立 2 個 Cloud Run：
  - Backend：CPU 1 / 1Gi、min=0 / max=5、掛載 `/cloudsql` 連 DB、環境變數從 `backend_env`
  - Frontend：CPU 1 / 1Gi、min=0 / max=5、環境變數從 `frontend_env`
- 兩個服務都先設為 **公開**（`roles/run.invoker` on `allUsers`）。想收斂可以移除 IAM 這兩段。

## 變更重點
- 若你想改成 `db-g1-small`，在 `main.tf` 把 `tier` 換成 `"db-g1-small"`。
- 想要更安全：
  - 把 `authorized_networks` 改成你的固定 IP；或
  - 改用私網 + Serverless VPC Access + Cloud SQL 連線器（我可以提供對應 Terraform 版）。

## 輸出
- `backend_url` / `frontend_url`
- `cloud_sql_connection_name`
```

