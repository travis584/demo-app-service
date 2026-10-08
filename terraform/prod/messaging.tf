resource "google_pubsub_topic" "dead_letters" {
  name   = "demo-app-${var.environment}-dead-letters"
  labels = merge(local.common_labels, { purpose = "dead-letter" })
}

resource "google_pubsub_subscription" "dead_letters" {
  name                       = "demo-app-${var.environment}-dead-letters"
  topic                      = google_pubsub_topic.dead_letters.id
  ack_deadline_seconds       = 120
  message_retention_duration = "1209600s"
  retain_acked_messages      = true
  labels                     = local.common_labels
}

resource "google_cloud_scheduler_job" "events_replay" {
  name        = "demo-app-${var.environment}-events-replay"
  description = "Periodic replay of recoverable event failures"
  schedule    = "*/15 * * * *"
  region      = var.region

  pubsub_target {
    topic_name = google_pubsub_topic.dead_letters.id
    data       = base64encode("replay")
  }
}
