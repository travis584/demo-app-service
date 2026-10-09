resource "google_logging_metric" "api_errors" {
  name   = "demo-app-${var.environment}-api-errors"
  filter = "resource.type=\"gce_instance\" AND severity>=ERROR"

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_notification_channel" "operations_email" {
  display_name = "Demo app operations"
  type         = "email"

  labels = {
    email_address = "platform-operations@example.com"
  }
}

resource "google_monitoring_alert_policy" "api_error_rate" {
  display_name = "demo-app-${var.environment} API error rate"
  combiner     = "OR"

  conditions {
    display_name = "API errors detected"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.api_errors.name}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 10
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.operations_email.name]
}

resource "google_logging_project_sink" "audit" {
  name        = "demo-app-${var.environment}-audit"
  destination = "storage.googleapis.com/${google_storage_bucket.audit_logs.name}"
  filter      = "resource.type=(\"gce_instance\" OR \"gcs_bucket\" OR \"gke_container\")"

  unique_writer_identity = true
}
