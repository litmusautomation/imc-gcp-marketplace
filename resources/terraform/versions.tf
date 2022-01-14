terraform {
  required_providers {
    google      = {
      source  = "hashicorp/google"
      version = "4.5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "3.89.0"
    }
    time        = {
      source  = "hashicorp/time"
      version = "0.7.2"
    }
    random      = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
    kubernetes  = {
      source  = "hashicorp/kubernetes"
      version = "2.5"
    }
  }
}

provider "google" {
  project = var.imc_project_id
  region  = var.imc_region

  request_timeout = "60s"
}

provider "google-beta" {
  project = var.imc_project_id
  region  = var.imc_region

  request_timeout = "60s"
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.imc_gke.endpoint}"
  token                  = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.imc_gke.master_auth[0].cluster_ca_certificate)
}
