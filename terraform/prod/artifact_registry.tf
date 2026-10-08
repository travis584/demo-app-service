resource "google_artifact_registry_repository" "containers" {
  location      = var.region
  repository_id = "demo-app-${var.environment}"
  description   = "Container images for the demo application"
  format        = "DOCKER"
  labels        = local.common_labels
}

resource "google_artifact_registry_repository" "terraform_modules" {
  location      = var.region
  repository_id = "demo-app-${var.environment}-modules"
  description   = "Internal Terraform module packages"
  format        = "DOCKER"
  labels        = local.common_labels
}
