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

resource "random_password" "mysql-root" {
  length           = 16
  special          = true
}

resource "random_password" "mysql-replication-root" {
  length           = 16
  special          = true
}

resource "random_password" "imc-enc-string" {
  length           = 16
  special          = true
}

resource "random_password" "imc-cfg-token" {
  length           = 20
  special          = true
}

resource "kubernetes_secret" "imc-enc-string" {
  metadata {
    name = "imc-enc-string"
    namespace = var.imc_k8s_namespace
  }
  data = {
    "imc-enc-string" = random_password.imc-enc-string.result
  }
  depends_on = [
    kubernetes_namespace.imc
  ]
}

resource "kubernetes_secret" "imc-cfg-token" {
  metadata {
    name = "imc-cfg-token"
    namespace = var.imc_k8s_namespace
  }
  data = {
    "imc-cfg-token" = random_password.imc-cfg-token.result
  }
  depends_on = [
    kubernetes_namespace.imc
  ]
}

resource "kubernetes_secret" "mysql-creds" {
  metadata {
    name = "imc-mysql-creds"
    namespace = var.imc_k8s_namespace
  }
  data = {
    "mysql-root-password" = random_password.mysql-root.result
    "mysql-replication-password" = random_password.mysql-replication-root.result
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
