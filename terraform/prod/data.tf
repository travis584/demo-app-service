# Cloud SQL is covered by a *spend-based* committed use discount, which Google
# only sells through the Billing console and does not expose as a Terraform
# resource. The commitment is recorded here as metadata so the IaC estimate has
# something to reconcile against, but it has no cost of its own in a plan.
#
#   Cloud SQL spend-based CUD: $1,200/mo, 1 year, us-central1, purchased 2026-02-01.
#
# This is the realistic case where a commitment covering the stack is invisible
# to Terraform entirely.
locals {
  external_commitments = {
    cloudsql_spend_cud = {
      service       = "cloud-sql"
      plan          = "TWELVE_MONTH"
      monthly_spend = 1200
      region        = var.region
    }
  }
}

resource "google_sql_database_instance" "primary" {
  name                = "demo-app-${var.environment}-primary"
  database_version    = "POSTGRES_16"
  region              = var.region
  deletion_protection = false

  settings {
    tier              = "db-custom-8-32768"
    availability_type = "REGIONAL"
    disk_type         = "PD_SSD"
    disk_size         = 800
    disk_autoresize   = true

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      start_time                     = "03:00"

      backup_retention_settings {
        retained_backups = 21
      }
    }

    user_labels = local.common_labels
  }
}

resource "google_sql_database_instance" "replica" {
  name                 = "demo-app-${var.environment}-replica"
  database_version     = "POSTGRES_16"
  region               = var.region
  master_instance_name = google_sql_database_instance.primary.name
  deletion_protection  = false

  replica_configuration {
    failover_target = false
  }

  settings {
    tier            = "db-custom-8-32768"
    disk_type       = "PD_SSD"
    disk_size       = 1000
    disk_autoresize = true
    user_labels     = local.common_labels
  }
}

resource "google_redis_instance" "cache" {
  name           = "demo-app-${var.environment}-cache"
  tier           = "STANDARD_HA"
  memory_size_gb = 72
  region         = var.region
  redis_version  = "REDIS_7_0"
  labels         = local.common_labels
}

resource "google_storage_bucket" "artifacts" {
  name          = "demo-app-${var.environment}-artifacts"
  location      = "US"
  storage_class = "STANDARD"
  labels        = local.common_labels

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
}

resource "google_bigquery_dataset" "analytics" {
  dataset_id = "demo_app_${var.environment}_analytics"
  location   = "US"
  labels     = local.common_labels
}

resource "google_bigquery_table" "events" {
  dataset_id          = google_bigquery_dataset.analytics.dataset_id
  table_id            = "events"
  deletion_protection = false

  time_partitioning {
    type  = "DAY"
    field = "occurred_at"
  }

  schema = jsonencode([
    { name = "event_id", type = "STRING", mode = "REQUIRED" },
    { name = "occurred_at", type = "TIMESTAMP", mode = "REQUIRED" },
    { name = "payload", type = "JSON", mode = "NULLABLE" },
  ])
}

resource "google_pubsub_topic" "events" {
  name   = "demo-app-${var.environment}-events"
  labels = local.common_labels
}

resource "google_pubsub_subscription" "events_worker" {
  name                       = "demo-app-${var.environment}-events-worker"
  topic                      = google_pubsub_topic.events.id
  ack_deadline_seconds       = 60
  message_retention_duration = "259200s"
  labels                     = local.common_labels
}
