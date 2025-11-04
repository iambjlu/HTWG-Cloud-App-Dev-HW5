Used commands
```bash
#installation
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
brew install --cask google-cloud-sdk
gcloud init

#cd to project dir
terraform init
terraform apply -target=google_project_service.apis -target=google_sql_database_instance.default
terraform apply -target=google_project_service.apis;terraform output db_public_ip_address\
terraform state show google_sql_database_instance.default\
terraform apply -target=google_cloud_run_v2_service.backend -target=google_cloud_run_service_iam_member.backend_invoker
terraform import google_cloud_run_v2_service.backend projects/htwg-cloudapp-hw/locations/asia-east1/services/cloud-app-hw-backend\
terraform apply -target=google_cloud_run_v2_service.backend -target=google_cloud_run_service_iam_member.backend_invoker\
terraform apply -target=google_cloud_run_v2_service.frontend -target=google_cloud_run_service_iam_member.frontend_invoker\
terraform import google_cloud_run_v2_service.frontend projects/htwg-cloudapp-hw/locations/asia-east1/services/cloud-app-hw-frontend\
terraform apply -target=google_cloud_run_v2_service.frontend -target=google_cloud_run_service_iam_member.frontend_invoker\
terraform apply
```