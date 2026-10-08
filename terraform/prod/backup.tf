resource "google_storage_bucket" "backup_archive" {
  name          = "demo-app-${var.environment}-backup-archive"
  location      = "US"
  storage_class = "ARCHIVE"
  labels        = merge(local.common_labels, { purpose = "backup" })

  uniform_bucket_level_access = true

  retention_policy {
    retention_period = 2592000
  }
}

resource "google_storage_bucket_object" "backup_manifest" {
  name         = "manifests/current.json"
  content      = jsonencode({ service = "demo-app-service", environment = var.environment })
  content_type = "application/json"
  bucket       = google_storage_bucket.backup_archive.name
}
