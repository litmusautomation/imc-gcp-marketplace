resource "google_compute_address" "imc_ingress" {
  provider     = google-beta
  name         = "imc-ingress-addr"
  address_type = "EXTERNAL"
  description  = "IMC Ingress IP address"
  region        = var.imc_region
  labels       = var.imc_deployment_labels
}

resource "google_compute_address" "imc_remote" {
  provider     = google-beta
  name         = "imc-remote-addr"
  address_type = "EXTERNAL"
  description  = "IMC remote IP address"
  region        = var.imc_region
  labels       = var.imc_deployment_labels
}