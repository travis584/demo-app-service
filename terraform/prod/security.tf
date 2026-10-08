resource "google_kms_key_ring" "application" {
  name     = "demo-app-${var.environment}"
  location = var.region
}

resource "google_kms_crypto_key" "application" {
  name            = "demo-app-${var.environment}-application"
  key_ring        = google_kms_key_ring.application.id
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_secret_manager_secret" "database_credentials" {
  secret_id = "demo-app-${var.environment}-database-credentials"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_secret_manager_secret" "api_signing_key" {
  secret_id = "demo-app-${var.environment}-api-signing-key"

  replication {
    auto {}
  }

  labels = local.common_labels
}

resource "google_storage_bucket" "encrypted_exports" {
  name                        = "demo-app-${var.environment}-encrypted-exports"
  location                    = "US"
  storage_class               = "NEARLINE"
  uniform_bucket_level_access = true
  labels                      = merge(local.common_labels, { purpose = "exports" })

  lifecycle_rule {
    condition {
      age = 180
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }
}
