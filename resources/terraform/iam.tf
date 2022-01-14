// Litmus Edge SA
resource "google_service_account" "imc_sa" {
  account_id   = var.imc_sa_id
  display_name = var.imc_sa_id
  description  = "SA for IMC deployment on GKE"
}

resource "google_project_iam_member" "imc_sa_binding" {
  for_each = var.imc_sa_roles
  member   = "serviceAccount:${google_service_account.imc_sa.email}"
  project = var.imc_project_id
  role     = each.value
}

resource "google_service_account_key" "imc_sa_key" {
  service_account_id = google_service_account.imc_sa.name
}
