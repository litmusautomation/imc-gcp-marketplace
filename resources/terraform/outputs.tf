output "imc_domain_name" {
  value = var.imc_domain_name
}

output "imc_ingress_external_ip" {
  value = google_compute_address.imc_ingress.address
}

output "imc_remote_external_ip" {
  value = google_compute_address.imc_remote.address
}
