resource "google_pubsub_topic" "imde_pubsub_topic" {
  count = "${var.create_imde_pubsub_topic ? 1 : 0}"
  name     = var.imde_pubsub_topic_name
  labels   = var.imc_deployment_labels
}
