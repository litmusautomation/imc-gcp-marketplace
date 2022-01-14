variable "imc_project_id" {
    description = "Environment project id"
}
variable "imc_region" {
    description = "Default region where all services are being provisioned."
}
variable "imc_zone" {
    description = "Default zone where all services are being provisioned."
}
variable "imc_oauth_client_id" {
    type      = string
    sensitive = true
}
variable "imc_oauth_client_secret" {
    type      = string
    sensitive = true
}
variable "imc_deployment_labels" {
    type = map(string)
    default = {
        "app" = "imc"
    }
}
variable "imc_gke_labels" {
    description = "GKE allows only lowercase letters ([a-z]), numeric characters ([0-9]), underscores (_) and dashes (-). International characters are allowed too."
    type = map(string)
    default = {}
}

variable "imc_network" {
    type        = string
    description = "IMC network name."
    default = "default"
}


variable "imc_gke_name" {
    type        = string
    description = "IMC GKE cluster name."
    default = "imc-gke"
}

variable "imc_node_machine_type" {
    type = string
    default = "e2-custom-4-12288"
}

variable "imc_sa_id" {
  type    = string
  default = "imc-k8s-app"
}

variable "imc_sa_roles" {
  type = set(string)
  default = [
      "roles/cloudiot.admin", 
      "roles/cloudsql.client", 
      "roles/pubsub.serviceAgent",
      "roles/pubsub.admin",
      "roles/secretmanager.secretAccessor",
      "roles/iam.serviceAccountAdmin",
      "roles/iam.serviceAccountKeyAdmin",
      "roles/iam.serviceAccountTokenCreator",
      "roles/storage.objectCreator",
      "roles/storage.objectViewer",
      "roles/viewer",
      "roles/pubsub.publisher",
      "roles/pubsub.subscriber"
    ]
}

variable "imc_k8s_namespace" {
    type = string
    default = "imc"
}

variable "imc_data_bucket_name_suffix" {
  type = string
  description = "GCS data_bucket suffics"
  default = "imc-data"
}

variable "imc_vault_bucket_name_suffix" {
  type = string
  description = "GCS vault bucket suffics"
  default = "imc-vault"
}

variable "create_imde_pubsub_topic" {
  description = "Create IMDE pub/sub topic"
  default = true
}

variable "imde_pubsub_topic_name" {
  type = string
  description = "IMDE pub/sub topic name"
  default = "input-messages"
}

variable "imc_domain_name" {
  type = string
  description = "IMC domain name"
}
