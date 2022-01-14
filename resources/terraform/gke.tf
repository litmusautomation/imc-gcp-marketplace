resource "google_container_cluster" "imc_gke" {
  name = var.imc_gke_name
  location = var.imc_region
  resource_labels = var.imc_gke_labels
  project = var.imc_project_id
  network = var.imc_network
  node_pool {
    node_count = 1
    node_config {
      image_type = "UBUNTU_CONTAINERD"
      machine_type = var.imc_node_machine_type
      service_account = google_service_account.imc_sa.email
      oauth_scopes    = [
        "https://www.googleapis.com/auth/cloud-platform",
        "https://www.googleapis.com/auth/logging.write",
        "https://www.googleapis.com/auth/monitoring"
      ]        
    }  
  }    
  release_channel {
    channel = "REGULAR"
  }
}


data "google_container_cluster" "imc_gke" {
  name       = google_container_cluster.imc_gke.name
  location   =  var.imc_region
}

data "google_client_config" "provider" {}

resource "kubernetes_namespace" "imc" {
  metadata {
    name = var.imc_k8s_namespace
  }
}

resource "kubernetes_secret" "google-application-credentials" {
  metadata {
    name = "imc-sa-key"
    namespace = var.imc_k8s_namespace
  }
  data = {
    "imc_sa_key.json" = base64decode(google_service_account_key.imc_sa_key.private_key)
  }
  depends_on = [
    kubernetes_namespace.imc
  ]
}

locals {
  vault_config = <<-EOT
    ui = true
    listener "tcp" {
      tls_disable = 1
      address = "[::]:8200"
      cluster_address = "[::]:8201"
    }
    storage "gcs" {
      bucket = "${google_storage_bucket.imc_vault_bucket_name.name}"
    }
    seal "gcpckms" {
      project     = "${var.imc_project_id}"
      region      = "global"
      key_ring    = "${data.google_kms_key_ring.vault-keyring.name}"
      crypto_key  = "${data.google_kms_crypto_key.vault-unseal.name}"
    }
  EOT
}

resource "kubernetes_secret" "vault-storage-config" {
  metadata {
    name = "vault-storage-config"
    namespace = var.imc_k8s_namespace
  }
  data = {
    "config.hcl" = local.vault_config
  }
  depends_on = [
    kubernetes_namespace.imc
  ]
}

resource "tls_private_key" "ingress" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "tls_self_signed_cert" "ingress" {
  key_algorithm     = "RSA"
  private_key_pem   = "${tls_private_key.ingress.private_key_pem}"
  is_ca_certificate = false
  dns_names = ["${var.imc_domain_name}"]
  subject {
    common_name         = "${var.imc_domain_name}"
  }

  validity_period_hours = 87659

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
    "client_auth",
  ]
}

resource "kubernetes_secret" "ingress_tls" {
  metadata {
    name = "imc-tls"
    namespace = var.imc_k8s_namespace
  }
  data = {
    "tls.crt" = "${tls_self_signed_cert.ingress.cert_pem}"
    "tls.key" = "${tls_private_key.ingress.private_key_pem}"
  }
  type = "kubernetes.io/tls"
  depends_on = [
    kubernetes_namespace.imc
  ]
}
