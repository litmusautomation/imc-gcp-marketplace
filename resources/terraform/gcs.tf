resource "google_storage_bucket" "imc_data_bucket_name" {
  name          = "${var.imc_project_id}-${var.imc_data_bucket_name_suffix}"
  project       = var.imc_project_id
  location      = var.imc_region
  storage_class = "REGIONAL"
  force_destroy = true
  labels        = var.imc_deployment_labels
  cors {
    origin          = ["*"]
    method          = ["GET", "PUT", "POST", "OPTIONS"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

resource "google_storage_bucket_iam_binding" "binding_data" {
  bucket = google_storage_bucket.imc_data_bucket_name.name
  role = "roles/storage.admin"
  members = [
    "serviceAccount:${google_service_account.imc_sa.email}",
  ]
}

