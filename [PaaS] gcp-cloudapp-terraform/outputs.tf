output "cloud_sql_connection_name" {
  value = "${var.project_id}:${var.region}:${var.sql_instance_name}"
}

output "backend_url" {
  value = google_cloud_run_v2_service.backend.uri
}

output "frontend_url" {
  value = google_cloud_run_v2_service.frontend.uri
}
