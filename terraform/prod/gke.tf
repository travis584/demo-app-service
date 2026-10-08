resource "google_container_cluster" "main" {
  name     = "demo-app-${var.environment}"
  location = var.region

  network    = google_compute_network.main.id
  subnetwork = google_compute_subnetwork.main.id

  remove_default_node_pool = true
  initial_node_count       = 1
  deletion_protection      = false

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }
}

# 6 x n2d-standard-8 == 48 vCPU / 192 GB across the region. The N2D commitment in
# commitments.tf covers half of it (24 vCPU / 96 GB), so this pool is the main
# source of partial-coverage signal.
resource "google_container_node_pool" "platform" {
  name     = "platform"
  location = var.region
  cluster  = google_container_cluster.main.name

  node_count = 2 # per zone, 3 zones in us-central1

  node_config {
    machine_type = "n2d-standard-8"
    disk_size_gb = 100
    disk_type    = "pd-balanced"
    labels       = merge(local.common_labels, { role = "platform" })

    service_account = google_service_account.api.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

# Spot pool for burst batch work. Spot and CUDs do not stack, so this pool is
# deliberately excluded from every commitment.
resource "google_container_node_pool" "batch_spot" {
  name     = "batch-spot"
  location = var.region
  cluster  = google_container_cluster.main.name

  node_count = 1

  node_config {
    machine_type = "n2d-standard-16"
    spot         = true
    disk_size_gb = 100
    disk_type    = "pd-balanced"
    labels       = merge(local.common_labels, { role = "batch" })

    service_account = google_service_account.api.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
