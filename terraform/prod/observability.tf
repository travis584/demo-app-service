resource "google_storage_bucket" "audit_logs" {
  name          = "demo-app-${var.environment}-audit-logs"
  location      = "US"
  storage_class = "STANDARD"
  labels        = merge(local.common_labels, { purpose = "audit" })

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
}

resource "google_pubsub_subscription" "events_archive" {
  name  = "demo-app-${var.environment}-events-archive"
  topic = google_pubsub_topic.events.id

  ack_deadline_seconds         = 120
  message_retention_duration   = "604800s"
  retain_acked_messages        = true
  enable_message_ordering      = false
  labels                       = local.common_labels
}
